"""
CityFit backend - Flask + CrewAI + DeepSeek

How to run:
    python app.py       (terminal 1)
    ngrok http 5000     (terminal 2, copy URL into Constants.swift)
"""

from dotenv import load_dotenv

load_dotenv()

from flask import Flask, jsonify, request

from crews.chat_crew import run_chat_crew
from crews.route_crew import run_route_crew
from crews.trip_crew import run_trip_crew
from crews.vision_crew import run_vision_crew

app = Flask(__name__)


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.post("/chat")
def chat():
    """sends user message to chat crew, returns coach reply"""
    data = request.get_json(force=True)
    try:
        reply = run_chat_crew(
            user_message=data.get("user_message", ""),
            level=data.get("level", 1),
            exp=data.get("exp", 0),
            steps_today=data.get("steps_today", 0),
            active_mission=data.get("active_mission", "none"),
            streak=data.get("streak", 0),
            missions_completed=data.get("missions_completed", 0),
        )
        return jsonify({"response": reply})
    except Exception as exc:  # noqa: BLE001 — surface any crew failure as 503
        app.logger.exception("chat crew failed")
        return jsonify({"error": str(exc)}), 503


@app.post("/route")
def route():
    """generates a walking route with waypoints and fitness info"""
    data = request.get_json(force=True)
    try:
        result = run_route_crew(
            current_lat=data.get("current_lat", 0.0),
            current_lng=data.get("current_lng", 0.0),
            level=data.get("level", 1),
            mission_pins=data.get("mission_pins", []),
            preferred_distance=data.get("preferred_distance", 2000),
        )
        return jsonify(result)
    except Exception as exc:  # noqa: BLE001
        app.logger.exception("route crew failed")
        return jsonify({"error": str(exc)}), 503


@app.post("/plan-trip")
def plan_trip():
    """calculates steps, time, and calories for a trip between two map points.
    distance is measured on the phone using MapKit and sent here."""
    data = request.get_json(force=True)
    try:
        result = run_trip_crew(
            origin_lat=data.get("origin_lat", 0.0),
            origin_lng=data.get("origin_lng", 0.0),
            destination_lat=data.get("destination_lat", 0.0),
            destination_lng=data.get("destination_lng", 0.0),
            distance_meters=data.get("distance_meters", 0.0),
            level=data.get("level", 1),
            weight_kg=data.get("weight_kg", 70.0),
        )
        return jsonify(result)
    except Exception as exc:  # noqa: BLE001
        app.logger.exception("trip crew failed")
        return jsonify({"error": str(exc)}), 503


@app.post("/verify-photo")
def verify_photo():
    """checks if the photo contains the mission target object"""
    data = request.get_json(force=True)
    try:
        result = run_vision_crew(
            image_base64=data.get("image_base64", ""),
            target_object=data.get("target_object", "object"),
            user_id=data.get("user_id", "anonymous"),
        )
        return jsonify(result)
    except Exception as exc:  # noqa: BLE001
        app.logger.exception("vision crew failed")
        return jsonify({"error": str(exc)}), 503


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
