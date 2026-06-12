"""Route Crew — 2 agents collaborating sequentially:
Route Planner picks the waypoints, Fitness Calculator estimates metrics
using the planner's output as context."""

import json

from crewai import Agent, Crew, Process, Task

from .llm_config import deepseek_llm, extract_json

route_planner_agent = Agent(
    role="Route Planner",
    goal="Design optimal walking route through mission points",
    backstory="""You plan walking routes through a city for the CityFit game.
    You pick 3-5 mission waypoints in a logical walking order, starting near
    the user's current position and minimizing back-tracking.""",
    llm=deepseek_llm,
    verbose=False,
)

fitness_calculator_agent = Agent(
    role="Fitness Calculator",
    goal="Calculate calories, EXP, and time for a given route",
    backstory="""You are a fitness metrics expert. Given an ordered walking
    route, you estimate total distance, walking time (~5 km/h), calories
    (~55 kcal per km walked), and sum the EXP rewards of the missions.""",
    llm=deepseek_llm,
    verbose=False,
)


def run_route_crew(current_lat: float, current_lng: float, level: int,
                   mission_pins: list, preferred_distance: float) -> dict:
    pins_json = json.dumps(mission_pins)

    route_task = Task(
        description=f"""The user is at lat {current_lat}, lng {current_lng} (level {level}).
Available mission pins (JSON): {pins_json}
Preferred total distance: about {preferred_distance} meters.

Select 3-5 of these mission pins and order them into a logical walking route
starting from the user's position. If fewer pins exist, use all of them.
Output ONLY a JSON array of waypoints in visit order, each:
{{"lat": <number>, "lng": <number>, "title": "<mission title>", "exp": <number>}}""",
        expected_output="A JSON array of 3-5 ordered waypoints.",
        agent=route_planner_agent,
    )

    calculation_task = Task(
        description="""Using the planned route from the Route Planner, estimate the
fitness metrics for walking it. Assume ~5 km/h walking speed and ~55 kcal per km.
Sum the exp values of the waypoints for the total EXP.
Output ONLY one JSON object exactly in this shape:
{"waypoints": [{"lat": 0.0, "lng": 0.0, "title": ""}],
 "calories": 0, "exp": 0, "minutes": 0,
 "summary": "<one motivating sentence describing the route>"}
The waypoints must be the planner's waypoints in the same order (without exp).""",
        expected_output="A single JSON object with waypoints, calories, exp, minutes, summary.",
        agent=fitness_calculator_agent,
        context=[route_task],
    )

    crew = Crew(
        agents=[route_planner_agent, fitness_calculator_agent],
        tasks=[route_task, calculation_task],
        process=Process.sequential,
    )
    result = extract_json(crew.kickoff())

    result.setdefault("waypoints", [])
    result.setdefault("calories", 0)
    result.setdefault("exp", 0)
    result.setdefault("minutes", 0)
    result.setdefault("summary", "Your AI walking route is ready!")
    return result
