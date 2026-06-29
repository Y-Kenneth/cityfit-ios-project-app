# CityFit — AI & ML Architecture

_Everything about the AI/ML parts: what runs where, what's trained vs.
pre-trained, and the open decisions. Last updated: 2026-06-13._

---

## Overview — three AI features + two ML models

| Feature | Type of AI | Where it runs | Status |
|---|---|---|---|
| AI Coach (chat) | Cloud LLM (DeepSeek) | Backend → DeepSeek API | ✅ Working |
| AI Route Generator | Cloud LLM (DeepSeek, 2-agent crew) | Backend → DeepSeek API | ✅ Working |
| AI Trip Planner | Cloud LLM (DeepSeek, 2-agent crew) | Backend → DeepSeek API | ✅ Working |
| Photo Verification (Tier 1) | On-device computer vision (trained CoreML model) | On the iPhone | ✅ Working — trained model bundled |
| Photo Verification (Tier 2, "Snap") | Cloud LLM vision (DeepSeek Vision + Vision Crew agent), on-device fallback | Backend → DeepSeek API | ✅ Working |
| Activity detection | On-device heuristic (final — no CoreML training planned) | On the iPhone | ✅ Heuristic is permanent |
| Photo classifier | On-device CoreML, trained with CreateML | On the iPhone | ✅ Trained model bundled (`ImageClassifier.mlmodel`) |

**Key distinction:**
- **Cloud LLM** (chat, route, trip): a huge model on DeepSeek's servers. Needs internet.
  You do **not** train it — you use it as-is.
- **On-device ML** (photo, activity): a small model that lives inside the app and
  runs offline on the iPhone's Neural Engine. The photo classifier is where
  **real data was trained** with CreateML — the project's ML deliverable is done
  (see below).

---

## 1. Backend AI (Flask + CrewAI + DeepSeek)

- `cityfit_backend/` — Flask, 4 endpoints, 4 crews, 6 agents total:
  - `POST /chat` → Chat Crew (1 agent: Personal Coach)
  - `POST /route` → Route Crew (2 agents: Route Planner → Fitness Calculator)
  - `POST /plan-trip` → Trip Crew (2 agents: Distance Analyst → Pace Estimator)
  - `POST /verify-photo` → Vision Crew (1 agent: Object Detection Specialist) —
    called by `CameraViewModel.snap()` for Tier 2 photo verification, see below
- LLM: **DeepSeek** `deepseek-v4-flash`, OpenAI-compatible API at
  `api.deepseek.com`, configured in `crews/llm_config.py`.
  - ⚠️ **Model id is case-sensitive.** Must be lowercase `deepseek-v4-flash`
    (from `GET /models`). Wrong casing → CrewAI throws the misleading
    "Prompt file 'None' not found" → HTTP 503 → app shows "AI unavailable".
- API key in `cityfit_backend/.env` (`DEEPSEEK_API_KEY`), gitignored.
- Exposed to the phone via **ngrok**. Free-tier URL changes each restart and must
  be pasted into `CityFit iOS Project/Utils/Constants.swift` (`backendURL`).
  ngrok and Flask are **separate processes** — restarting Flask doesn't restart
  ngrok.
- All AI calls **degrade gracefully** when the backend is unreachable.
- **GFW note:** external LLM calls must avoid OpenAI/Google. DeepSeek is reachable
  and handles both text and vision (Vision Crew), so no alternative provider is needed.

---

## 2. Photo Verification (two tiers: on-device, then backend Vision Crew)

File: `Services/VisionService.swift`, driven by `ViewModels/CameraViewModel.swift`.

- **Tier 1 (live):** runs continuously on camera frames while the user hovers
  over an object; auto-completes the mission at high confidence (≥0.85), shows
  "possible" with the Snap button at medium confidence (0.50–0.85). This is
  the path used most of the time — no backend call, fully on-device.
- **Tier 2 ("Snap"):** only triggered when Tier 1's confidence is too low to
  auto-complete on its own (the 0.50–0.85 "possible" band) and the user taps
  Snap. The captured frame is sent to the backend **Vision Crew**: DeepSeek
  Vision first describes the photo, then the Object Detection Specialist agent
  turns that description into a strict `detected: true/false` verdict.
  If the backend is unreachable, it falls back to a stricter on-device
  re-check (≥0.65) instead, so the feature still works offline.

### Why DeepSeek can work for vision after all
An earlier note in this doc said DeepSeek was text-only and couldn't verify
images. `deepseek-v4-flash` does accept image input via the same
OpenAI-compatible API (`image_url` content blocks) — see
`cityfit_backend/crews/vision_crew.py`. The Vision Crew backend was built
correctly from the start; the iOS app just wasn't calling it. `CameraViewModel.snap()`
now calls `AIService.verifyPhoto` (`/verify-photo`), so Tier 2 is live end-to-end.

---

## 3. Trained models (CreateML) — the "real data" deliverable

**Status: done.** `ImageClassifier.mlmodel` is trained, bundled in the Xcode
project (`CityFit iOS Project/ImageClassifier.mlmodel`), and registered in the
build. The app is wired so a trained model **auto-loads with no code change**
— `VisionService` detects the bundled `.mlmodelc` and prefers it automatically;
the built-in `VNClassifyImageRequest` is only a fallback for the rare case the
bundled model fails to load.

### Photo classifier — `ImageClassifier.mlmodel` — how it was trained
1. CreateML → **Image Classification** template.
2. One folder per object class, ~25–100+ images each (mix of Kaggle/internet
   images + your own iPhone photos for best accuracy). Folder names must exactly
   match the `targetObject` keys used in missions:

   | Folder name     | What to photograph |
   |---|---|
   | `bottle`        | Water bottles, plastic bottles, flasks |
   | `bicycle`       | Bikes, cycles (parked or ridden) |
   | `flower`        | Flowers, blooming plants |
   | `chair`         | Chairs, stools, seats |
   | `backpack`      | Backpacks, school bags |
   | `book`          | Books, textbooks, notebooks |
   | `person_male`   | Men / boys (varied angles, campus setting) |
   | `person_female` | Women / girls (varied angles, campus setting) |
   | `trash_can`     | Bins, trash cans, dustbins |
   | `car`           | Cars, sedans, SUVs |
   | `laptop`        | Laptops, computers, MacBooks |
   | `phone`         | Smartphones, mobile phones |

3. Train → export → drag `ImageClassifier.mlmodel` into Xcode (Copy items + app
   target). Xcode compiles it to `ImageClassifier.mlmodelc` in the bundle.
4. `VisionService` auto-detects it and uses it instead of the built-in classifier.
   Confirm at runtime via `VisionService.isUsingTrainedModel`.

**Data collection tip:** Kaggle and Google Images work great for bulk data.
Add 10–15 of your own iPhone photos per class (shot in your actual campus
environment) for better real-world accuracy during the demo.

### Activity classifier — **NOT planned (heuristic is permanent)**

`ActivityService` uses a motion-magnitude heuristic to classify walking /
running / stationary. This is the final implementation — no `ActivityClassifier.mlmodel`
will be trained. The heuristic performs well enough for the EXP multiplier
feature, and collecting labeled sensor data requires sustained device sessions
that are out of scope for this project phase.

The CoreML slot still exists in the code for future extensibility but will
never be populated in this project.

---

## Confidence thresholds (tune as needed)

| Where | Threshold | Meaning |
|---|---|---|
| Tier 1 auto-complete | ≥ 0.85 | Confident enough to complete, on-device, no backend call |
| Tier 1 "possible" | 0.50–0.85 | Too low to auto-complete — show Snap button |
| Tier 2 Snap → backend | n/a | Vision Crew agent gives a strict true/false verdict |
| Tier 2 Snap → on-device fallback | ≥ 0.65 | Only used if the backend is unreachable |

---

## Files to know

| File | Role |
|---|---|
| `cityfit_backend/crews/llm_config.py` | DeepSeek model config (case-sensitive id) |
| `cityfit_backend/crews/vision_crew.py` | Vision Crew: DeepSeek Vision describe step + Object Detection Specialist agent |
| `cityfit_backend/app.py` | Flask endpoints |
| `Services/AIService.swift` | iOS HTTP client; typed error reporting |
| `ViewModels/AIViewModel.swift` | Chat/route/trip/photo calls; graceful fallback + logging |
| `Services/VisionService.swift` | On-device vision; trained-model auto-load |
| `ViewModels/CameraViewModel.swift` | Two-tier photo detection state machine; Tier 2 calls the backend Vision Crew, with on-device fallback |
| `ViewModels/CameraViewModel.swift` | Two-tier photo detection state machine |
| `Services/ActivityService.swift` | Activity detection (heuristic / CoreML) |
| `Utils/Constants.swift` | `backendURL` (update on ngrok restart) |
