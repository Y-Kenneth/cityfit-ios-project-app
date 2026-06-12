# CityFit — Claude Code Notes

Gamified fitness app (SwiftUI, MVVM) + Flask/CrewAI/Groq AI backend.
Full spec: `iOS CityFit Project Background.md`.

## Hard constraints (Xcode 14.3.1 / iOS 16 SDK — DO NOT break)

- **NEVER use iOS 17+ MapKit API.** Always `Map(coordinateRegion:showsUserLocation:annotationItems:)` + `MapAnnotation` (not `MapMarker`, not `Marker`/`UserAnnotation`).
- **NEVER use `#Preview {}`.** Always a `*_Previews: PreviewProvider` struct.
- No `@Observable` macro — use `ObservableObject` + `@Published`.
- Deployment target iOS 16.0, Swift 5, SwiftUI only (UIKit only where unavoidable: `CameraPreviewView`, `RouteMapView` for polylines — iOS 16 SwiftUI Map can't draw overlays).
- MVVM strictly: no business logic in Views. Mock data only in `Utils/MockData.swift`.
- Backend URL lives in `Utils/Constants.swift` (`backendURL`) — update on every Ngrok restart.
- `PedometerService` keeps its `#if targetEnvironment(simulator)` mock block.
- All AI features degrade gracefully when the backend is unreachable.
- External LLM calls go to DeepSeek (OpenAI-compatible API, `api.deepseek.com`).
  Model id is case-sensitive — use lowercase `deepseek-v4-flash` exactly as
  returned by `GET /models`. (No OpenAI/Google APIs — GFW.)

## Project layout

- iOS app target folder: `CityFit iOS Project/` (Models, ViewModels, Views/{Auth,Onboarding,Main,Components}, Services, Utils).
- AI backend: `cityfit_backend/` (Flask, 3 endpoints, 3 crews / 4 agents — see its README).

## Adding new Swift files

This is an Xcode 14 project (explicit pbxproj file references — no folder sync).
After creating .swift files in the existing folders, either add them in Xcode,
or re-run `python3 scripts/register_sources.py` *only for a fresh tree*
(the script is idempotent per-path but appends duplicates if a file is already
registered — prefer Xcode's "Add Files…" for one-off additions).

## Build / run

```bash
xcodebuild -scheme "CityFit iOS Project" -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

Simulator GPS: Features → Location → City Run. Steps auto-mock on simulator.

## Phase 2 still manual (CoreML)

`ActivityService` works today with a motion heuristic. Once
`ActivityClassifier.mlmodel` is trained in CreateML (Activity Classification
template, CSV columns `accel_x..gyro_z`, window 50) and dragged into the
project, the service auto-detects and uses it — no code change needed.

## Photo-mission model (CoreML / Vision)

`VisionService` works today with Apple's built-in image classifier
(`VNClassifyImageRequest`) — photo missions detect common objects untrained,
fully on-device (no backend; the old DeepSeek/Groq "Snap" path was removed
because DeepSeek is text-only). Tier 2 "Snap" re-runs the same classifier at a
higher confidence bar.

To use your own trained model (the project's "train real data" deliverable):

1. In **CreateML** → **Image Classification** template.
2. Collect labeled photos: one folder per object class (e.g. `bottle/`,
   `bicycle/`, `plant/`, `bench/`), ~25+ images each, shot on the iPhone.
   Class folder names should match the mission `targetObject` values (or add
   the trained labels to `VisionService.synonyms`).
3. Train, then **export** → drag the resulting `ImageClassifier.mlmodel` into
   the Xcode project (check "Copy items" + the app target). Xcode compiles it
   to `ImageClassifier.mlmodelc` in the bundle.
4. That's it — `VisionService` auto-detects the bundled model and uses it
   instead of the built-in classifier. No code change. Confirm at runtime via
   `VisionService.isUsingTrainedModel`.
