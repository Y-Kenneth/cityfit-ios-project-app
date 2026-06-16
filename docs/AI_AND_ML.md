# CityFit — AI & ML Architecture

_Everything about the AI/ML parts: what runs where, what's trained vs.
pre-trained, and the open decisions. Last updated: 2026-06-13._

---

## Overview — three AI features + two ML models

| Feature | Type of AI | Where it runs | Status |
|---|---|---|---|
| AI Coach (chat) | Cloud LLM (DeepSeek) | Backend → DeepSeek API | ✅ Working |
| AI Route Generator | Cloud LLM (DeepSeek, 2-agent crew) | Backend → DeepSeek API | ✅ Working |
| Photo Verification | On-device computer vision (Apple Vision / CoreML) | On the iPhone | ✅ Working (untrained fallback) |
| Activity detection | On-device heuristic (final — no CoreML training planned) | On the iPhone | ✅ Heuristic is permanent |
| Photo classifier | On-device CoreML (planned) / built-in now | On the iPhone | ⚠️ Built-in until trained |

**Key distinction:**
- **Cloud LLM** (chat, route): a huge model on DeepSeek's servers. Needs internet.
  You do **not** train it — you use it as-is.
- **On-device ML** (photo, activity): a small model that lives inside the app and
  runs offline on the iPhone's Neural Engine. This is where **you train real data**
  with CreateML — the project's ML deliverable.

---

## 1. Backend AI (Flask + CrewAI + DeepSeek)

- `cityfit_backend/` — Flask, 3 endpoints, 3 crews:
  - `POST /chat` → Chat Crew (1 agent: Personal Coach)
  - `POST /route` → Route Crew (2 agents: Planner → Fitness Calculator)
  - `POST /verify-photo` → Vision Crew (currently UNUSED by the app, see below)
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
- **GFW note:** external LLM calls must avoid OpenAI/Google. DeepSeek is reachable;
  Groq is the documented alternative if a vision LLM is needed.

---

## 2. Photo Verification (on-device, two tiers)

File: `Services/VisionService.swift`, driven by `ViewModels/CameraViewModel.swift`.

- **Tier 1 (live):** runs on camera frames; auto-completes the mission at high
  confidence (≥0.85), shows "possible" at medium (0.50–0.85).
- **Tier 2 ("Snap"):** when the user taps Snap on a medium hit, re-runs the same
  model on a clean still at a stricter bar (≥0.65) to confirm/reject.
- **Fully on-device.** No network, GFW-irrelevant, free, private.

### Why no cloud LLM here
DeepSeek is **text-only** (confirmed via `/models` — both `deepseek-v4-flash` and
`deepseek-v4-pro` reject image input). So the original "cloud LLM double-checks the
photo" plan can't run on DeepSeek. Tier 2 was moved on-device. The legacy cloud
client (`AIViewModel.verifyPhoto` + `/verify-photo`) is kept but unused.

### ⚠️ OPEN DECISION — Tier 2 verification
1. **Keep on-device** (current): one model, two confidence tiers. Simplest, offline.
2. **Groq vision model** for Tier 2: restores cloud "describe + confirm" with
   free-form text. GFW-friendly. Needs a Groq key + network.
3. **Second on-device model** for Tier 2: e.g. a CoreML object *detector* over the
   classifier. Two different models, still offline. More training work.

---

## 3. Training your own models (CreateML) — the "real data" deliverable

The app is wired so a trained model **auto-loads with no code change**.

### Photo classifier — `ImageClassifier.mlmodel`
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
| Tier 1 auto-complete | ≥ 0.85 | Confident enough to complete |
| Tier 1 "possible" | 0.50–0.85 | Show Snap button |
| Tier 2 Snap confirm | ≥ 0.65 | Deliberate confirmation bar |

---

## Files to know

| File | Role |
|---|---|
| `cityfit_backend/crews/llm_config.py` | DeepSeek model config (case-sensitive id) |
| `cityfit_backend/app.py` | Flask endpoints |
| `Services/AIService.swift` | iOS HTTP client; typed error reporting |
| `ViewModels/AIViewModel.swift` | Chat/route calls; graceful fallback + logging |
| `Services/VisionService.swift` | On-device vision; trained-model auto-load |
| `ViewModels/CameraViewModel.swift` | Two-tier photo detection state machine |
| `Services/ActivityService.swift` | Activity detection (heuristic / CoreML) |
| `Utils/Constants.swift` | `backendURL` (update on ngrok restart) |
