# CityFit — Design & UI Spec

_For brainstorming the visual design (e.g. with an AI designer or in Figma).
Describes every screen, the navigation flow, components, and the visual system
as currently built. Last updated: 2026-06-12._

---

## Visual identity

**Theme:** dark, neon, "cyber-city / game HUD" aesthetic.

| Token | Hex | Use |
|---|---|---|
| `cityBackground` | `#0D0D1A` | Deep dark navy — app background |
| `cityCard` | `#1A1A2E` | Card / surface |
| `cityAccent` | `#00D4FF` | Cyan — primary accent, buttons, route lines |
| `cityGreen` | `#39FF14` | Neon green — EXP bar, progress, trail |
| `cityYellow` | `#FFD700` | Gold — rewards, timers |
| `cityPurple` | `#7B2FBE` | Purple — secondary |
| `citySubtext` | `#8888AA` | Dimmed text |

- Typography: SF system font, heavy weights for titles, `.monospacedDigit()` for
  numbers (steps, distance, timers).
- Shapes: rounded rectangles (corner radius ~12–24), capsule progress bars,
  circular avatar/icon chips.

---

## App flow

```
SplashView
   ↓
(first launch) Onboarding: CharacterSelectView → OnboardingLoadingView
   ↓                                   (or) Auth: LoginView / SignUpView
   ↓
MainTabView  ← the main app
```

- `RootView` decides Splash → Auth/Onboarding → MainTabView.
- Auth (Login/SignUp) are UI flows; no real account backend yet.

---

## Main navigation — 5 tabs (`MainTabView`)

| Tab | Icon (SF Symbol) | Screen |
|---|---|---|
| **Home** | `map.fill` | `HomeView` — live map of missions |
| **Missions** | `target` | `MissionsView` — mission list/board |
| **Ranks** | `trophy.fill` | `LeaderboardView` |
| **Community** | `person.3.fill` | `CommunityView` |
| **Profile** | `person.fill` | `ProfileView` |

- A floating **AI Coach** button overlays the tabs → opens `AIChatView` as a sheet.

---

## Screen-by-screen

### Home (`HomeView`)
- Full-screen **map** (iOS 16 MapKit: `Map(coordinateRegion:…)` + `MapAnnotation`).
- Mission pins (`MissionPinView`) + game-event pins.
- Top overlay: avatar (`CharacterAvatarView`) + EXP bar (`EXPBarView`).
- Action to **generate an AI route** → `RoutePreviewView` (sheet).

### Route Preview (`RoutePreviewView`)
- `MKMapView` polyline preview of the AI route + numbered waypoint pins.
- Metrics card: `X km · Y min · Z EXP · ~N cal` + AI summary text + waypoint list.
- **"Start This Route"** → opens live navigation (`RouteNavigationView`).

### Route Navigation (`RouteNavigationView`)  ← live nav
- Full-screen live map (`NavigationMapView`): route polyline, moving user dot,
  follows the user.
- Bottom panel: **big "X m to [next waypoint]"**, **"Total left"**, **waypoint
  counter (n/total)**. Close (✕) button top-left.
- On arrival at final waypoint → starts the mission.

### Active Mission — map-based (`ActiveMissionView`)
- Full-screen live map (`MissionMapView`): user dot, **green trail** of the path
  walked, optional destination pin for distance missions.
- Top bar: ✕ (give up) + timer/countdown chip (`mm:ss`, gold if time-limited).
- Bottom panel: mission title, **capsule progress bar** (`current of target unit`),
  activity badge (walking/running + EXP multiplier), steps + distance stats.
- On completion → `MissionCompleteView` overlay (EXP awarded, level-up banner).

### Photo Mission (`PhotoMissionView`)
- Full-screen **camera** feed (`CameraPreviewView`); placeholder + demo buttons on
  Simulator (no camera there).
- Top bar: ✕ + target/progress chip (`🎯 Title  current/target`).
- Bottom: **detection banner** (`DetectionBannerView`) with live status; a
  **"Snap"** button appears at medium confidence to confirm.
- States: scanning → possible → verifying → detected / rejected.
- On completion → `MissionCompleteView`.

### Missions (`MissionsView`)
- List/board of missions (`MissionCardView`); tap → `MissionDetailView`.
- Mission types: **steps**, **distance**, **photo**. Difficulty: easy/medium/hard.

### Ranks (`LeaderboardView`)
- Ranked list of users (`LeaderboardRowView`) by EXP/level.

### Community (`CommunityView`)
- Cards of communities/groups (`CommunityCardView`); tap → `CommunityDetailView`.

### Profile (`ProfileView`)
- User avatar, level, EXP progress, streak, mission stats.

### AI Coach (`AIChatView`)
- Chat sheet: assistant + user bubbles, text input ("Ask your coach…"), send
  button. Replies come from the DeepSeek backend; references user stats.

---

## Key components (`Views/Components`)

| Component | Purpose |
|---|---|
| `CharacterAvatarView` | Circular avatar for the chosen character |
| `EXPBarView` | Level + EXP progress bar (neon green) |
| `MissionCardView` | Mission summary card (list) |
| `MissionPinView` | Map pin for a mission |
| `LeaderboardRowView` | One leaderboard row |
| `CommunityCardView` | Community summary card |
| `DetectionBannerView` | Photo-mission live status banner |
| `CameraPreviewView` | UIKit AVCaptureVideoPreviewLayer bridge |
| `RouteMapView` | UIKit MKMapView — static route polyline preview |
| `NavigationMapView` | UIKit MKMapView — live route navigation |
| `MissionMapView` | UIKit MKMapView — live active-mission map + trail |

---

## Gameplay / data rules (for design context)

- **Characters** (4): Sportsman 🏃‍♂️, Sportswoman 🏃‍♀️, Student 👩‍🎓, Rabbit 🐰.
- **EXP:** 500 EXP per level. Multipliers — running ×2.0, walking ×1.0,
  stationary ×0.0. Activity detected by `ActivityService`.
- **Mission types:** steps (count), distance (meters), photo (find N objects).
- **Mission status:** available / active / completed / failed.
- Some missions have a **time limit** (countdown) and/or a **map pin**.

---

## iOS 16 / SDK constraints that affect design

- Map uses the **iOS 16 API** — `Map(coordinateRegion:…)` + `MapAnnotation`.
  Polylines/overlays require a UIKit `MKMapView` bridge (hence the three map
  components above).
- No iOS 17+ MapKit, no `#Preview` macro, no `@Observable`.
- Designs should assume **dark mode only** (no light theme implemented).
