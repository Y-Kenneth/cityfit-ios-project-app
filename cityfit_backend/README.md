# CityFit AI Backend

Flask + CrewAI + Groq backend with 3 endpoints and 4 agents across 3 crews.

| Endpoint | Crew | Agents |
|---|---|---|
| `POST /chat` | Chat Crew | Personal Coach |
| `POST /route` | Route Crew | Route Planner → Fitness Calculator (sequential) |
| `POST /verify-photo` | Vision Crew | Object Detection Specialist (+ Groq Vision model) |

## Setup (on the AI laptop)

```bash
cd cityfit_backend
python -m venv venv
venv\Scripts\activate          # Windows
pip install -r requirements.txt
copy .env.example .env          # then paste your GROQ_API_KEY into .env
```

## Run

```bash
# Terminal 1 — Flask
python app.py

# Terminal 2 — expose to the internet
ngrok http 5000
# -> https://abc123.ngrok-free.app
```

Paste the Ngrok URL into the iOS app: `CityFitMapTest/Utils/Constants.swift`
(`backendURL`). The free-tier URL changes on every Ngrok restart.

## Quick test

```bash
curl http://localhost:5000/health

curl -X POST http://localhost:5000/chat -H "Content-Type: application/json" \
  -d '{"user_message":"I feel lazy today","level":5,"exp":1340,"steps_today":800,"active_mission":"Daily Walker","streak":3}'

curl -X POST http://localhost:5000/route -H "Content-Type: application/json" \
  -d '{"current_lat":32.0603,"current_lng":118.7964,"level":5,"preferred_distance":2000,"mission_pins":[{"id":"m3","title":"Morning Sprinter","lat":32.0620,"lng":118.7980,"exp":150},{"id":"m4","title":"City Explorer","lat":32.0590,"lng":118.7950,"exp":200}]}'
```
