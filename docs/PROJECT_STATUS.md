# CityFit — Project Status

_Last updated: 2026-06-13. This file is the hand-off so you can resume on any machine._

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

### Photo Mission Verification — **working, two-tier (on-device + backend Vision Crew)**
- Tier 1 (live): a trained CreateML model (`ImageClassifier.mlmodel`, bundled
  and registered in Xcode) runs on-device via `VisionService`; auto-completes
  at high confidence (≥0.85).
- Tier 2 ("Snap"): only triggered when Tier 1 confidence is too low to
  auto-complete (0.50–0.85, "possible" band). Tapping Snap sends the captured
  frame to the backend Vision Crew (DeepSeek Vision describes the photo, the
  Object Detection Specialist agent gives a strict detected/rejected verdict).
  Falls back to a stricter on-device re-check (≥0.65) if the backend is
  unreachable, so the feature still works offline.
- **The "real data" deliverable is done:** `ImageClassifier.mlmodel` is trained
  and bundled — `VisionService` loads it automatically (falls back to Apple's
  built-in `VNClassifyImageRequest` only if the bundled model is ever missing).
  See `AI_AND_ML.md`.

### Firebase — **working**
- `AuthService`: real login via Google Sign-In, exchanged for a Firebase Auth
  session (not a mock flow).
- `FirestoreService`: real-time cloud database — user profile (level, EXP,
  steps, streak), leaderboard, and community chat messages (live updates via
  Firestore listeners, not polling).

### Backend
- Flask app with 4 endpoints (`/chat`, `/route`, `/plan-trip`, `/verify-photo`),
  4 crews / 6 agents — all 4 crews are now called by the app (see `AI_AND_ML.md`).
- Runs on DeepSeek (`deepseek-v4-flash`, OpenAI-compatible API, also accepts
  image input for Vision Crew). Exposed via ngrok.

### Robustness / docs
- AIService now reports the real failure cause (tunnel offline / backend error /
  timeout) instead of a generic "offline"; ViewModels log the true error.
- `CLAUDE.md` documents constraints, DeepSeek model casing, ngrok behavior, and
  both CreateML training workflows.

---

## ⚠️ Not done / known gaps / decisions pending

- **`ActivityClassifier.mlmodel` — intentionally not planned.** Activity
  detection uses the motion-magnitude heuristic permanently. The EXP multiplier
  works correctly without a trained model; collecting labeled sensor data is out
  of scope.
- **Real device testing pending.** Camera (Tier 1 live + Snap) and real GPS/
  pedometer only run on a physical iPhone. The Simulator mocks movement and has
  no camera. Test on device before judging these.
- **ngrok free tier URL changes on restart** and must be pasted into
  `Utils/Constants.swift` (`backendURL`). Consider a reserved static domain.
- **No voice/turn-by-turn navigation, no off-route rerouting** (out of scope on
  iOS 16 SDK).
- **No AR camera layer** (a larger future phase if you want full Pokémon-GO feel).

---

## How to run

See [`HOW_TO_RUN.md`](HOW_TO_RUN.md) for full setup steps (Firebase, backend
`.env`/ngrok, Xcode build, troubleshooting).

---

## Suggested next steps (brainstorm list)

1. **Test on a real iPhone** — camera + GPS + pedometer.
2. **Optional:** "complete on arrival at pin" geofence for distance missions.
3. **Optional:** AR camera layer for true Pokémon-GO feel.

See `DESIGN_SPEC.md` for the full UI/screen breakdown and `AI_AND_ML.md` for the
AI/ML details.
