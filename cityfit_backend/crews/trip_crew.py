"""Trip Crew — 2 agents collaborating sequentially:
Distance Analyst frames the real MapKit-measured distance between two points
the user picked on the Home map, Pace Estimator turns it into steps/time/
calories for both walking and running. The actual distance is measured
on-device via MKDirections (CrewAI agents can't call Apple's MapKit) and
passed in as ground truth — these agents reason on top of it, they don't
recompute the geometry."""

import time

from crewai import Agent, Crew, Process, Task

from .llm_config import deepseek_llm_structured, extract_json

distance_analyst_agent = Agent(
    role="Distance Analyst",
    goal="Assess a real-world walking distance between two points the user chose on the map",
    backstory="""You receive a real walking-route distance, already measured
    by Apple Maps, between two points a CityFit user picked on the map. You
    don't recompute the geometry — you judge how demanding the trip is for
    the user's level and frame it for the next agent.""",
    llm=deepseek_llm_structured,
    verbose=False,
)

pace_estimator_agent = Agent(
    role="Pace Estimator",
    goal="Calculate steps, time, and calories burned for walking and running a given distance",
    backstory="""You are a fitness metrics expert. Given a distance in meters
    and the user's body weight, you estimate steps (via average stride
    length), time, and calories burned (MET-based) for both walking
    (~5 km/h, ~0.75m stride, MET 3.5) and running (~9 km/h, ~1.1m stride,
    MET 8) the same distance. calories = MET * weight_kg * hours.""",
    llm=deepseek_llm_structured,
    verbose=False,
)

# Same rationale as Route Crew: 2 sequential DeepSeek calls with a strict
# JSON contract occasionally drift off-format — retry the whole crew once
# before surfacing a 503 to the app.
TRIP_ATTEMPTS = 2


def _run_once(origin_lat: float, origin_lng: float, destination_lat: float,
              destination_lng: float, distance_meters: float, level: int,
              weight_kg: float) -> dict:
    analysis_task = Task(
        description=f"""A CityFit user (level {level}) selected two points on the map:
start ({origin_lat}, {origin_lng}) and destination ({destination_lat}, {destination_lng}).
Apple Maps measured the real walking-route distance between them as {distance_meters} meters.
Write one short, motivating sentence about this trip, and judge its difficulty
for this user's level.
Output ONLY a JSON object exactly in this shape:
{{"difficulty": "easy" | "moderate" | "challenging", "note": "<one sentence>"}}
No markdown, no code fences, no explanation before or after the JSON.""",
        expected_output="A JSON object with difficulty and note.",
        agent=distance_analyst_agent,
    )

    estimate_task = Task(
        description=f"""Using the Distance Analyst's note as context, calculate fitness
metrics for a {distance_meters}-meter trip for a user weighing {weight_kg} kg.
Walking: ~5 km/h, stride ~0.75m, MET 3.5.
Running: ~9 km/h, stride ~1.1m, MET 8.
calories = MET * weight_kg * hours.
Output ONLY one JSON object exactly in this shape:
{{"walk": {{"steps": 0, "minutes": 0, "calories": 0}},
 "run": {{"steps": 0, "minutes": 0, "calories": 0}},
 "summary": "<one motivating sentence combining the analyst's note and these numbers>"}}
No markdown, no code fences, no explanation before or after the JSON.""",
        expected_output="A single JSON object with walk, run, and summary.",
        agent=pace_estimator_agent,
        context=[analysis_task],
    )

    crew = Crew(
        agents=[distance_analyst_agent, pace_estimator_agent],
        tasks=[analysis_task, estimate_task],
        process=Process.sequential,
    )
    return extract_json(crew.kickoff())


def run_trip_crew(origin_lat: float, origin_lng: float, destination_lat: float,
                  destination_lng: float, distance_meters: float, level: int,
                  weight_kg: float) -> dict:
    last_error = None
    result = None
    for attempt in range(1, TRIP_ATTEMPTS + 1):
        try:
            result = _run_once(origin_lat, origin_lng, destination_lat,
                               destination_lng, distance_meters, level, weight_kg)
            break
        except Exception as exc:  # noqa: BLE001 — malformed JSON or a transient API hiccup
            last_error = exc
            if attempt < TRIP_ATTEMPTS:
                time.sleep(1)
    if result is None:
        raise last_error

    result.setdefault("walk", {"steps": 0, "minutes": 0, "calories": 0})
    result.setdefault("run", {"steps": 0, "minutes": 0, "calories": 0})
    result.setdefault("summary", "Your trip is ready!")
    result["distance_meters"] = distance_meters
    return result
