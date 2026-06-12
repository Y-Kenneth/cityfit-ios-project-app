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
