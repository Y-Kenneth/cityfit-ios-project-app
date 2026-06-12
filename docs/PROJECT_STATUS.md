# CityFit — Project Status

_Last updated: 2026-06-12. This file is the hand-off so you can resume on any machine._

CityFit is a gamified, Pokémon-GO-style fitness app: walk/run real-world routes,
complete missions, earn EXP, level up an avatar, climb leaderboards, and chat
with an AI coach. **iOS app** (SwiftUI, MVVM, iOS 16 SDK) + **Python AI backend**
(Flask + CrewAI + DeepSeek).

---

## ✅ Done & working

### App structure / build
- Project renamed from `CityFitMapTest` → **"CityFit iOS Project"** (folder, target,
  `@main struct CityFitApp`). Builds clean for the iOS Simulator.
- iOS 16 / Xcode 14.3.1 constraints respected throughout (see `CLAUDE.md`).

### AI Chatbot (Coach) — **working**
- Chat tab → DeepSeek via Flask `/chat`. Returns personalized coaching that
  references the user's level/steps/streak. Verified end-to-end.

### AI Route Generator — **working**
- Home → "generate route" → DeepSeek via Flask `/route` (2-agent crew).
  Returns waypoints + calories/EXP/minutes/summary, drawn as a real walking
  polyline (MKDirections). Verified end-to-end.

### Live Route Navigation — **working**
- "Start This Route" opens a dedicated map navigation screen: route polyline,
  live user location, "distance to next waypoint" + "total distance left" +
  waypoint counter. On arrival it starts the mission (existing EXP flow).
- Scope: route path + live distance only (no voice/turn-by-turn, no off-route
  rerouting — iOS 16 SDK limitation).

### Map-based Active Missions (Pokémon-GO style) — **working**
- All active step/distance missions now track on a **live map** (was a static
  progress ring): user's dot moves in real time, walked path draws as a trail,
  distance missions show a destination pin, compact progress bar + stats.

### Photo Mission Verification — **working, on-device**
- Two-tier, **fully on-device** (no cloud):
  - Tier 1 (live): Apple Vision `VNClassifyImageRequest` auto-completes at high
    confidence.
  - Tier 2 ("Snap"): re-runs Vision at a stricter confidence bar to confirm.
- **CreateML-ready:** drop a trained `ImageClassifier.mlmodel` into the project
  and `VisionService` uses it automatically — no code change. See `AI_AND_ML.md`.

### Backend
- Flask app with 3 endpoints (`/chat`, `/route`, `/verify-photo`), 3 crews.
- Runs on DeepSeek (`deepseek-v4-flash`, OpenAI-compatible API). Exposed via ngrok.

### Robustness / docs
- AIService now reports the real failure cause (tunnel offline / backend error /
  timeout) instead of a generic "offline"; ViewModels log the true error.
- `CLAUDE.md` documents constraints, DeepSeek model casing, ngrok behavior, and
  both CreateML training workflows.

---

## ⚠️ Not done / known gaps / decisions pending

- **Photo Tier 2 is no longer a cloud LLM.** DeepSeek is **text-only** (confirmed
  via its `/models`), so it cannot verify images. Tier 2 was moved on-device.
  DECISION PENDING: keep on-device, OR add a Groq vision model for free-form
  descriptions, OR add a second on-device CoreML detector. (See `AI_AND_ML.md`.)
- **No trained CoreML models yet.** Both `ActivityClassifier.mlmodel` (activity
  detection) and `ImageClassifier.mlmodel` (photo missions) are still TODO — the
  app uses heuristic/built-in fallbacks until trained. This is the project's
  "train real data" deliverable.
- **No real auth/persistence backend.** Login/SignUp are UI flows over mock data;
  there's no user account server. Data is local (UserDefaults-style).
- **Real device testing pending.** Camera (Tier 1 live + Snap) and real GPS/
  pedometer only run on a physical iPhone. The Simulator mocks movement and has
  no camera. Test on device before judging these.
- **ngrok free tier URL changes on restart** and must be pasted into
  `Utils/Constants.swift` (`backendURL`). Consider a reserved static domain.
- **No voice/turn-by-turn navigation, no off-route rerouting** (out of scope on
  iOS 16 SDK).
- **No AR camera layer** (a larger future phase if you want full Pokémon-GO feel).

---

## How to run (quick reference)

**Backend (the "AI laptop"):**
```bash
cd cityfit_backend
source venv/bin/activate        # macOS; venv\Scripts\activate on Windows
python app.py                    # terminal 1  (or: venv/bin/python app.py)
ngrok http 5000                  # terminal 2  -> copy URL into Constants.swift
```
- DeepSeek key lives in `cityfit_backend/.env` (gitignored). Rotate if leaked.

**iOS app:**
```bash
xcodebuild -scheme "CityFit iOS Project" -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' build
```
- Simulator GPS: Features → Location → City Run. Steps/movement auto-mock.

---

## Suggested next steps (brainstorm list)

1. **Decide Tier 2 verification direction** (on-device vs Groq vs 2nd CoreML).
2. **Collect data + train** `ImageClassifier.mlmodel` (photo) and
   `ActivityClassifier.mlmodel` (activity) in CreateML, then drop in.
3. **Test on a real iPhone** — camera + GPS + pedometer.
4. **Optional:** "complete on arrival at pin" geofence for distance missions.
5. **Optional:** real auth + persistence backend.
6. **Optional:** AR camera layer for true Pokémon-GO feel.

See `DESIGN_SPEC.md` for the full UI/screen breakdown and `AI_AND_ML.md` for the
AI/ML details.
