# How to Run CityFit (New Machine / Grader Setup)

This is the single guide for getting the project building and running from a
fresh clone/unzip. Read this top to bottom before opening Xcode.

CityFit has two halves that run independently: the **iOS app** (works on its
own with mock data) and the **AI backend** (only needed for the AI Coach chat,
AI route generator, and AI trip planner — everything else works without it).

---

## 1. iOS app — minimum to build & run on Simulator

**Requirements:** macOS, Xcode 14.3.1, iOS 16 SDK. (This project intentionally
targets iOS 16 / Xcode 14.3.1 — see `../CLAUDE.md` for why; don't let Xcode
auto-upgrade packages.)

1. Open `CityFit iOS Project.xcodeproj`.
2. Let Xcode resolve Swift Package dependencies (File → Packages → Resolve
   Package Versions, if it doesn't happen automatically). This project pins
   Firebase to 10.x and `nanopb` to an exact version — **do not** run "Update
   to Latest Package Versions"; see Troubleshooting below if you hit package
   errors.
3. `GoogleService-Info.plist` (Firebase config) — included in this submission
   already, under `CityFit iOS Project/`. If it's ever missing, see the
   "Firebase config note" below.
4. Build & run on an iOS Simulator (e.g. iPhone 14), target "CityFit iOS
   Project":
   ```bash
   xcodebuild -scheme "CityFit iOS Project" -sdk iphonesimulator \
     -destination 'generic/platform=iOS Simulator' build
   ```
   or just hit ▶ in Xcode with a Simulator selected.
5. To simulate GPS movement: Simulator menu → Features → Location → City Run.
   Steps and movement auto-mock on the Simulator (see `PedometerService`).

**This is enough to explore almost the whole app** — missions, map, profile,
leaderboard, community, photo missions (Simulator has no camera, so photo
missions only work on a real device) — all run on local mock data
(`Utils/MockData.swift`) with no backend required.

### Running on a physical device instead of Simulator
Code signing needs your own Apple Developer Team:
- Create `Config/Local.xcconfig` (gitignored, doesn't ship in this zip) with:
  ```
  PRODUCT_BUNDLE_IDENTIFIER = com.yourbundleid.here
  DEVELOPMENT_TEAM = YOURTEAMID
  ```
- Do **not** set Team/Bundle ID via Xcode's Signing & Capabilities UI — that
  writes an inline override into `project.pbxproj`, which would then need to
  be reverted before resubmitting. Edit `Config/Local.xcconfig` instead.

### Firebase config note (`GoogleService-Info.plist`)
This file is normally gitignored and machine-specific (it's bundled in this
submission so the project runs immediately). If you ever re-clone from git
without it: download it from Firebase Console → CityFit project → Project
Settings → your iOS app (`com.kenneth.cityfit`) → drag into Xcode under
`CityFit iOS Project/` with "Copy items if needed" checked.

---

## 2. AI backend — needed only for AI Coach / AI Route / AI Trip Planner

Without this running, those three features fail gracefully (the app shows an
"AI unavailable" message instead of crashing) — everything else in the app is
unaffected.

```bash
cd cityfit_backend
python -m venv venv
venv\Scripts\activate            # Windows
# source venv/bin/activate       # macOS/Linux
pip install -r requirements.txt
copy .env.example .env           # Windows; `cp` on macOS/Linux
```

Then edit `cityfit_backend/.env` and paste in a real DeepSeek API key:
```
DEEPSEEK_API_KEY=sk-your_real_key_here
```
(Get one at https://platform.deepseek.com — this project does not include a
working key; the submitted `.env.example` is a template only.)

Run it:
```bash
# Terminal 1
python app.py

# Terminal 2 — exposes localhost to the internet so the iOS app can reach it
ngrok http 5000
```

Copy the `https://....ngrok-free.app` URL ngrok prints, and paste it into
[`CityFit iOS Project/Utils/Constants.swift`](../CityFit%20iOS%20Project/Utils/Constants.swift)
as `backendURL` — **the URL currently committed there is stale** (ngrok's free
tier issues a new URL every restart) and must be replaced before the AI
features will work. Rebuild the iOS app after changing it.

Full endpoint list and curl test examples: [`../cityfit_backend/README.md`](../cityfit_backend/README.md).

---

## Troubleshooting

**"Package.resolved file is corrupted... unknown 'PinsStorage' version '3'"**
— a newer Xcode re-resolved packages in a format Xcode 14.3.1 can't read.
Delete `CityFit iOS Project.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
and let Xcode 14.3.1 regenerate it.

**"package product 'nanopb' requires minimum platform version 12.0... but this
target supports 11.0"** — known Firebase 10.29.0 SPM bug, already fixed in
this project by pinning `nanopb` to `2.30910.0` as an explicit dependency.
Should just work; if it resurfaces, use "Resolve Package Versions" (not
"Update to Latest").

**Do not upgrade Firebase past 10.x** — Firebase 11+ requires Swift
5.9-compatible tooling that Xcode 14.3.1 (Swift 5.8.1) can't parse.

**Packages stuck/failing to download** — check connectivity to
`dl.google.com` specifically (Firebase binary artifacts are hosted there,
separate from `github.com`).

**DeepSeek model errors / "AI unavailable"** — the model id in
`cityfit_backend/crews/llm_config.py` is case-sensitive (`deepseek-v4-flash`,
lowercase). Also confirm `DEEPSEEK_API_KEY` is set in `.env` and the ngrok URL
in `Constants.swift` is current (see above).

---

## What does and doesn't need a backend

| Feature | Needs backend? |
|---|---|
| Missions, map, leaderboard, community, profile | No — local mock data |
| Photo missions (object detection) | No — fully on-device (Apple Vision) |
| Activity detection (walk/run/stationary) | No — on-device heuristic |
| AI Coach chat | **Yes** |
| AI-generated routes | **Yes** |
| AI trip planner | **Yes** |

See [`PROJECT_STATUS.md`](PROJECT_STATUS.md) for what's fully working vs. known
gaps, and [`AI_AND_ML.md`](AI_AND_ML.md) for how the AI/ML pieces are built.
