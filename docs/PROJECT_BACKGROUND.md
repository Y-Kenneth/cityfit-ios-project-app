# CityFit iOS — Project Brief & Claude Code Handoff
> **Project type:** iOS Gamified Fitness App ("A city walking game")
> **Developer:** Kenneth (Solo)
> **Course:** iOS Application Development — Final Project
> **Deadline:** July 1
> **Figma prototype:** https://www.figma.com/design/Twi6Wo5jDEXUZWJZOE9KAr/Proyek-PDK (52 screens, iPhone 14 Plus)

---

## 1. Problem & Concept

**Problem:** Indonesian young adults are sedentary — scrolling TikTok, gaming in bed, rarely exercising. They know they should move more, but screens are more immediately rewarding than exercise.

**Solution:** CityFit makes exercise feel like playing a game. Users walk and run around their real city to earn EXP, complete missions, level up a character, and compete on leaderboards. The behavioral loop is directly inspired by Pokémon GO — instead of catching Pokémon, you complete fitness missions by physically moving through your city.

**Target users:** Indonesian young adults, ages 18-25, sedentary lifestyle, high smartphone usage.

**Why it beats just telling people to exercise:** CityFit doesn't fight against screen addiction — it hijacks the same dopamine loop (rewards, levels, missions) and redirects it toward physical movement.

---

## 2. Developer Environment

| Item | Spec |
|---|---|
| Mac | macOS Ventura 13.6 (22G120) — Intel x86_64 |
| Xcode | 14.3.1 (14E300c) |
| iOS SDK | iOS 16.4 |
| Test device | Lecturer's iPhone (iOS 16.4) — available once per week |
| Simulator | iPhone 14 (iOS 16.4) — currently has boot issues on lab Mac |
| AI laptop | ASUS TUF Gaming F15, RTX 3070, Windows — runs Flask + CrewAI |
| Location | Nanjing, China — GFW applies, Google Maps blocked |

---

## 3. Tech Stack

### iOS App
| Layer | Choice | Notes |
|---|---|---|
| Language | Swift | No Objective-C |
| UI | SwiftUI | MVVM pattern strictly |
| Maps | MapKit (Apple) | iOS 14–16 API only — NOT iOS 17+ |
| Location | CoreLocation | Real GPS tracking |
| Steps | CoreMotion (CMPedometer) | Real-time pedometer |
| Health | HealthKit | Step data read |
| Camera | AVFoundation + Vision | For photo missions |
| On-device AI | CoreML (Activity Classifier) | Custom trained model |
| Object detection | Apple Vision Framework | Live hover detection |
| Storage | UserDefaults + FileManager | No Firebase, no CoreData |
| Networking | URLSession | HTTPS calls to backend |

### AI Backend (Python — runs on Kenneth's Windows laptop)
| Layer | Choice | Notes |
|---|---|---|
| Server | Flask | 3 endpoints |
| Multi-agent | CrewAI | 4 agents across 3 crews |
| LLM | Groq API (Llama 3.3 70B) | Free tier, works in China |
| Vision LLM | Groq Vision API | For photo mission verification |
| Tunnel | Ngrok | Exposes laptop to internet — works anywhere |

### What was considered and rejected
- **LangGraph + RAG** — over-engineered for this scope, Groq direct prompting is sufficient
- **Ollama** — replaced by Groq (Ollama requires same WiFi, Groq works anywhere)
- **Firebase** — replaced by UserDefaults (simpler, no dependency)
- **Hugging Face Spaces** — untested, risky for deadline
- **Google Maps / Mapbox** — blocked by GFW in China

---

## 4. ⚠️ Critical Constraints

### MapKit API Version
Xcode 14.3.1 uses iOS 16 SDK. **NEVER use iOS 17+ MapKit API.**

```swift
// ✅ CORRECT — iOS 14-16 style (use this)
Map(coordinateRegion: $region,
    showsUserLocation: true,
    annotationItems: items) { item in
    MapAnnotation(coordinate: item.coordinate) {
        MissionPinView(item: item)
    }
}

// ❌ WRONG — iOS 17+ only, will NOT compile on Xcode 14
Map(initialPosition: .region(region)) {
    UserAnnotation()
    Marker("Event", coordinate: coord)
}
```

### Preview Syntax
Xcode 14 does NOT support `#Preview {}` macro. Always use:
```swift
// ✅ CORRECT for Xcode 14
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// ❌ WRONG — Xcode 15+ only
#Preview {
    ContentView()
}
```

### Other Constraints
- Deployment target: **iOS 16.0**
- No Google Maps, no Mapbox — **MapKit only**
- CMPedometer does NOT work on Simulator — use mock data with `#if targetEnvironment(simulator)`
- Ngrok URL changes on free tier — store in `Constants.swift` for easy update
- All AI features must **gracefully degrade** — app works fully if backend is unreachable
- China coordinate system (GCJ-02) — MapKit handles this automatically on Chinese region devices

---

## 5. Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                  iPhone (iOS 16.4)               │
│                                                  │
│  SwiftUI Views (MVVM)                           │
│       ↓                                          │
│  ViewModels                                      │
│       ↓                                          │
│  Services Layer                                  │
│  ├── LocationService (CoreLocation + MapKit)     │
│  ├── PedometerService (CoreMotion)               │
│  ├── ActivityClassifierService (CoreML) ←──────┐ │
│  ├── VisionService (Apple Vision + AVFoundation)│ │
│  └── AIService (URLSession → Ngrok → Flask)     │ │
│                                                  │ │
└──────────────────────────┬──────────────────────┘ │
                           │ HTTPS via Ngrok          │
                           ↓                          │
┌──────────────────────────────────────────────────┐ │
│         Flask Backend (Kenneth's Laptop)          │ │
│                                                   │ │
│  POST /chat        → Chat Crew (1 agent)          │ │
│  POST /route       → Route Crew (2 agents)        │ │
│  POST /verify-photo → Vision Crew (1 agent)       │ │
│                                                   │ │
│  All crews → Groq API (Llama 3.3 70B)            │ │
└──────────────────────────────────────────────────┘ │
                                                      │
┌─────────────────────────────────────────────────┐  │
│        CoreML Model (on-device, offline)         │──┘
│  ActivityClassifier.mlmodel                      │
│  Input: accelerometer + gyroscope data           │
│  Output: walking / running / stationary          │
│  Effect: EXP multiplier (2x running, 1x walking) │
└─────────────────────────────────────────────────┘
```

---

## 6. Feature List

### Core Features (Real Implementation)
| Feature | Technology | Status |
|---|---|---|
| Real-time map with user location | MapKit + CoreLocation | Build |
| Custom mission pins on map | MapKit MapAnnotation | Build |
| Step counting | CoreMotion CMPedometer | Build |
| Distance tracking | CoreLocation | Build |
| EXP & leveling system | Swift logic + UserDefaults | Build |
| Mission progress tracking | UserDefaults | Build |
| Activity detection (walk/run/still) | CoreML Activity Classifier | Build |
| AI Chatbot (floating button) | CrewAI + Groq | Build |
| AI Route Generator | CrewAI + MapKit MKDirections | Build |
| Photo missions (object detection) | Apple Vision + Groq Vision | Build |

### Mock Features (UI Only — No Real Backend)
| Feature | Notes |
|---|---|
| Leaderboard | Static array of fake users, current user in middle |
| Communities | 5 fake communities, join toggles locally |
| Game events on map | Hardcoded coordinate pins in Nanjing area |

---

## 7. AI Features — Detailed Implementation

### 7.1 Floating AI Chatbot

**Trigger:** Floating cyan button (bottom right) on every screen via ZStack overlay in MainTabView. Tapping opens a sheet with a chat interface.

**CrewAI — Chat Crew:**
```python
chat_agent = Agent(
    role="CityFit Personal Coach",
    goal="Help the user with fitness advice, app guidance, and motivation",
    backstory="""You are CityFit's AI coach. You know the user's level, 
    EXP, steps, missions, and streak. Respond in 2-3 sentences max, 
    friendly and encouraging.""",
    llm=groq_llm
)
# Endpoint: POST /chat
# Input: user_message, level, exp, steps_today, active_mission, streak
# Output: short conversational response string
```

**iOS — Floating Button (in MainTabView):**
```swift
ZStack {
    TabView { ... }  // your normal tab view

    VStack {
        Spacer()
        HStack {
            Spacer()
            Button { showChat = true } label: {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
                    .padding(16)
                    .background(Color.cyan)
                    .clipShape(Circle())
                    .shadow(color: .cyan.opacity(0.5), radius: 10)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 90)
        }
    }
}
.sheet(isPresented: $showChat) { AIChatView() }
```

---

### 7.2 AI Route Generator

**Trigger:** "Generate Route" button on HomeView map screen.

**Flow:**
```
User taps "Generate Route"
        ↓
Swift sends: current GPS, user level, available mission pins, preferred distance
        ↓
Route Planner Agent → selects 3-5 mission waypoints in logical walking order
        ↓
Fitness Calculator Agent → estimates calories, EXP, time (uses Route Planner output as context)
        ↓
Returns: ordered waypoints JSON + metrics JSON
        ↓
Swift passes waypoints to MKDirections for walking route calculation
        ↓
MapKit draws cyan polyline connecting all waypoints
        ↓
UI shows route summary card: "2.3km · 28min · 450 EXP · ~180 cal"
        ↓
User taps "Start This Route" → missions activate in order
```

**CrewAI — Route Crew:**
```python
route_planner_agent = Agent(
    role="Route Planner",
    goal="Design optimal walking route through mission points",
    llm=groq_llm
)
fitness_calculator_agent = Agent(
    role="Fitness Calculator",
    goal="Calculate calories, EXP, and time for a given route",
    llm=groq_llm
)
# route_task runs first, calculation_task uses context=[route_task]
# Endpoint: POST /route
# Input: current_lat, current_lng, level, mission_pins[], preferred_distance
# Output: { waypoints: [...], calories: 180, exp: 450, minutes: 28, summary: "..." }
```

**iOS — Drawing the Route:**
```swift
func drawRoute(waypoints: [CLLocationCoordinate2D]) {
    for i in 0..<waypoints.count - 1 {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[i]))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: waypoints[i+1]))
        request.transportType = .walking
        MKDirections(request: request).calculate { response, _ in
            if let polyline = response?.routes.first?.polyline {
                self.routeOverlays.append(polyline)
            }
        }
    }
}
```

**UI Layout:**
```
┌─────────────────────────────┐
│         Apple Map           │
│  ⚡──────⚡──────⚡         │  ← cyan polyline route
│  Mission1    Mission2  M3   │  ← mission pins
│         📍 (you)            │
├─────────────────────────────┤
│ 🗺️ AI Generated Route       │
│ 2.3km · 28min · 450 EXP    │
│ ~180 calories burned        │
│ [  Start This Route  ]      │
└─────────────────────────────┘
```

---

### 7.3 Camera Object Detection Missions

**Concept:** Some missions require the user to find and photograph specific real-world objects (bottle, bicycle, plant, bench). Uses a two-tier detection system.

**Two-Tier Detection System:**

**Tier 1 — Apple Vision Framework (on-device, real-time, no internet)**
- Runs continuously while camera is open
- Analyzes every frame for the target object
- High confidence (≥85%) → auto-updates mission, no tap needed
- Medium confidence (50-84%) → shows "Possible [object] detected" + Snap button
- Low confidence (<50%) → nothing shown, keep scanning

**Tier 2 — Groq Vision API (cloud, on-demand)**
- Only triggered when user taps "Snap" on a medium-confidence detection
- Sends single photo as base64 to Flask → Groq Vision confirms or rejects
- Confirmed → mission updates
- Rejected → "Not quite, try again"

**Why two tiers:**
- Apple Vision = fast, offline, works while walking outdoors
- Groq Vision = more accurate, handles ambiguous cases
- Groq only called ~1-2 times per mission → negligible API usage
- Clear separation of responsibilities for report

**UI States:**
```
State 1 — Scanning:
┌─────────────────────────────┐
│  🎯 Find 2 Bottles  0/2     │
│     [ Live Camera Feed ]    │
│  Point camera at a bottle   │
└─────────────────────────────┘

State 2 — High confidence (Apple Vision auto-detects):
┌─────────────────────────────┐
│  🎯 Find 2 Bottles  0/2     │
│  ┌──────────────────────┐   │
│  │  ✅ BOTTLE DETECTED  │   │  ← green border
│  └──────────────────────┘   │
│       Mission: 1/2 ✅       │  ← auto-updated, no tap
└─────────────────────────────┘

State 3 — Medium confidence (needs Groq):
┌─────────────────────────────┐
│  🎯 Find 2 Bottles  1/2     │
│  ┌──────────────────────┐   │
│  │ ⚠️ POSSIBLE BOTTLE   │   │  ← yellow border
│  └──────────────────────┘   │
│   Not sure? [ 📸 Snap ]     │  ← snap button appears
└─────────────────────────────┘

State 4 — Groq confirmed:
┌─────────────────────────────┐
│       Mission: 2/2 ✅ 🎉    │  ← complete!
└─────────────────────────────┘
```

**CrewAI — Vision Crew:**
```python
vision_agent = Agent(
    role="Object Detection Specialist",
    goal="Verify if photo contains the required mission object",
    backstory="""You analyze photos to verify CityFit mission completion.
    The object must be clearly visible. Be strict but fair.""",
    llm=groq_vision_llm
)
# Endpoint: POST /verify-photo
# Input: image_base64, target_object, user_id
# Output: { detected: true, description: "red bicycle on left", confidence: "HIGH" }
```

**Apple Vision confidence handler:**
```swift
func handleVisionResult(observation: VNClassificationObservation) {
    switch observation.confidence {
    case 0.85...1.0:
        showBanner("✅ \(targetObject.capitalized) detected!")
        updateMissionProgress()      // auto-complete, no Groq call
    case 0.50..<0.85:
        showBanner("⚠️ Possible \(targetObject) detected")
        showSnapButton = true        // user decides to confirm with Groq
    default:
        showSnapButton = false       // keep scanning silently
    }
}
```

---

## 8. CoreML Activity Classifier

### What it does
Detects in real-time what the user is doing — **walking, running, or stationary** — using the iPhone's accelerometer and gyroscope. Used to apply an EXP multiplier during active missions:
- Running → 2x EXP
- Walking → 1x EXP
- Stationary → 0x EXP, mission timer pauses

### Why it's different from FitnessCoachApp's CoreML model
| | FitnessCoachApp | CityFit |
|---|---|---|
| Model type | Action Classification (video) | Activity Classification (motion sensors) |
| Input | Camera frames | Accelerometer + gyroscope data |
| CreateML template | Action Classification | Activity Classification |
| Runtime | Single prediction per frame | Continuous real-time stream |
| Training data | Squat videos | CSV of sensor readings |

### How to collect training data
You need a small Swift data-logger app (or script) that saves CoreMotion data to CSV while you move. Run it three times:
- **10 minutes walking** around campus, phone in pocket → `walking_session.csv`
- **5 minutes running/jogging** → `running_session.csv`
- **5 minutes standing still** → `stationary_session.csv`

CSV format:
```
timestamp, accel_x, accel_y, accel_z, gyro_x, gyro_y, gyro_z, label
0.01, 0.12, -0.98, 0.23, 0.01, -0.02, 0.00, walking
0.02, 0.15, -0.97, 0.21, 0.01, -0.01, 0.01, walking
```

### Training in CreateML
```
Folder structure for CreateML:
TrainingData/
├── walking/
│   └── walking_session.csv
├── running/
│   └── running_session.csv
└── stationary/
    └── stationary_session.csv
```
1. Open CreateML (Spotlight → "Create ML")
2. New Project → **Activity Classification** template
3. Drag TrainingData folder in
4. Prediction window: 50 samples
5. Click Train (~5 minutes)
6. Export → `ActivityClassifier.mlmodel`
7. Drag into Xcode project

### Runtime integration
```swift
// In PedometerService or dedicated ActivityService
// Called every ~1 second during active mission
func classifyActivity(accel: CMAcceleration, gyro: CMRotationRate) {
    let prediction = try? activityClassifier.prediction(
        accelerometerX: accel.x, accelerometerY: accel.y, accelerometerZ: accel.z,
        gyroscopeX: gyro.x, gyroscopeY: gyro.y, gyroscopeZ: gyro.z
    )
    switch prediction?.activity {
    case "running":    expMultiplier = 2.0
    case "walking":    expMultiplier = 1.0
    default:           expMultiplier = 0.0
    }
}
```

---

## 9. Flask Backend Structure

```
cityfit_backend/
├── app.py              # Flask server, 3 endpoints
├── crews/
│   ├── chat_crew.py    # Chat Crew — 1 agent
│   ├── route_crew.py   # Route Crew — 2 agents
│   └── vision_crew.py  # Vision Crew — 1 agent
├── requirements.txt
└── .env                # GROQ_API_KEY=...
```

**requirements.txt:**
```
flask
crewai
groq
python-dotenv
```

**Endpoints:**
```
POST /chat          → Chat Crew → conversational response
POST /route         → Route Crew → waypoints + fitness metrics
POST /verify-photo  → Vision Crew → object detection result
```

**Ngrok setup:**
```bash
# Terminal 1 — run Flask
cd cityfit_backend
python app.py

# Terminal 2 — expose via Ngrok
ngrok http 5000
# Gives you: https://abc123.ngrok-free.app
```

**Update in iOS Constants.swift:**
```swift
static let backendURL = "https://abc123.ngrok-free.app"
// Update this every time Ngrok restarts (free tier changes URL)
```

---

## 10. CrewAI Summary — All 4 Agents

| Agent | Crew | Role | Skills | Triggered By |
|---|---|---|---|---|
| Personal Coach | Chat Crew | Conversational fitness coach | Reads user context, gives personalized advice | Floating chat button |
| Route Planner | Route Crew | Selects optimal mission waypoints | Analyzes mission pins, plans walking order | "Generate Route" button |
| Fitness Calculator | Route Crew | Estimates route metrics | Calculates EXP, calories, time from distance | After Route Planner (sequential) |
| Object Specialist | Vision Crew | Verifies photo contains target object | Groq Vision analysis, strict detection | "Snap" button on photo mission |

**For the report:** Each agent has a distinct role, specific skills, and clear collaboration flow. Route Crew shows agent-to-agent collaboration (sequential process). This matches the assignment requirement for "multiple AI agents, roles, skills, and collaboration documentation."

---

## 11. Project File Structure

```
CityFit/
├── CityFitApp.swift
├── CLAUDE.md
│
├── Models/
│   ├── User.swift                   # UserProfile, CharacterType enum
│   ├── Mission.swift                # Mission struct, MissionType, MissionStatus
│   ├── Community.swift              # Mock community data model
│   ├── LeaderboardEntry.swift       # Mock leaderboard data model
│   └── GameEvent.swift              # Mock map event pins
│
├── ViewModels/
│   ├── MapViewModel.swift           # Region, annotations, route overlays
│   ├── MissionViewModel.swift       # Mission progress, completion, EXP award
│   ├── ProfileViewModel.swift       # Level, EXP bar, character
│   ├── AIViewModel.swift            # All AI service calls (chat, route, vision)
│   └── CameraViewModel.swift        # Vision detection state, snap logic
│
├── Views/
│   ├── Auth/
│   │   ├── SplashView.swift
│   │   ├── LoginView.swift
│   │   └── SignUpView.swift
│   ├── Onboarding/
│   │   ├── CharacterSelectView.swift
│   │   └── OnboardingLoadingView.swift
│   ├── Main/
│   │   ├── MainTabView.swift            # Tab bar + floating chat button overlay
│   │   ├── HomeView.swift               # Map + mission overlay + generate route
│   │   ├── MissionsView.swift           # Mission list (steps + distance + photo)
│   │   ├── MissionDetailView.swift      # Mission info + start button
│   │   ├── ActiveMissionView.swift      # Live tracking: steps, distance, EXP
│   │   ├── PhotoMissionView.swift       # Camera + Vision detection UI
│   │   ├── MissionCompleteView.swift    # EXP reward celebration screen
│   │   ├── RoutePreviewView.swift       # AI route summary before starting
│   │   ├── LeaderboardView.swift        # Mock leaderboard
│   │   ├── CommunityView.swift          # Mock communities list
│   │   ├── CommunityDetailView.swift    # Mock community detail + posts
│   │   ├── ProfileView.swift            # Character, level, stats, history
│   │   └── AIChatView.swift             # Floating chat sheet UI
│   └── Components/
│       ├── EXPBarView.swift
│       ├── CharacterAvatarView.swift
│       ├── MissionCardView.swift
│       ├── MissionPinView.swift          # Custom MapAnnotation pin
│       ├── LeaderboardRowView.swift
│       ├── CommunityCardView.swift
│       └── DetectionBannerView.swift     # Green/yellow detection overlay
│
├── Services/
│   ├── LocationService.swift        # CoreLocation wrapper
│   ├── PedometerService.swift       # CoreMotion + simulator mock
│   ├── ActivityService.swift        # CoreML activity classifier
│   ├── VisionService.swift          # Apple Vision object detection
│   ├── CameraService.swift          # AVFoundation camera session
│   └── AIService.swift              # URLSession → Ngrok → Flask
│
├── ML/
│   └── ActivityClassifier.mlmodel   # Custom trained in CreateML
│
└── Utils/
    ├── Constants.swift              # backendURL, colors, EXP values
    ├── MockData.swift               # All mock data — never hardcode in Views
    └── EXPCalculator.swift          # Level math, EXP thresholds
```

---

## 12. Data Models

```swift
// User.swift
struct UserProfile: Codable {
    var id: String
    var username: String
    var character: CharacterType
    var level: Int
    var currentEXP: Int
    var totalSteps: Int
    var missionsCompleted: Int
    var joinDate: Date
    var weeklySteps: [Int]       // [today, yesterday, ...6 days ago]
    var streak: Int
}

enum CharacterType: String, Codable, CaseIterable {
    case sportsmanM = "sportsman_m"
    case sportsmanF = "sportsman_f"
    case studentF   = "student_f"
    case rabbit     = "rabbit"
}

// Mission.swift
struct Mission: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var type: MissionType
    var targetValue: Double
    var currentValue: Double
    var expReward: Int
    var difficulty: Difficulty
    var status: MissionStatus
    var timeLimit: Int?
    var targetObject: String?    // for .photo type: "bottle", "bicycle", etc.
    var coordinate: CLLocationCoordinate2D?  // optional pin location
}

enum MissionType: String, Codable {
    case steps, distance, photo
}
enum Difficulty: String, Codable { case easy, medium, hard }
enum MissionStatus: String, Codable { case available, active, completed, failed }

// EXPCalculator.swift
struct EXPCalculator {
    static func expRequired(forLevel level: Int) -> Int { level * 500 }
    static func level(forEXP exp: Int) -> Int { max(1, exp / 500) }
    static func progress(currentEXP: Int) -> Double {
        let levelEXP = currentEXP % 500
        return Double(levelEXP) / 500.0
    }
}
```

---

## 13. Seed / Mock Data

```swift
// MockData.swift

// MARK: - Missions
static let missions: [Mission] = [
    // Step missions
    Mission(id: "m1", title: "Daily Walker",
            description: "Walk 1000 steps today",
            type: .steps, targetValue: 1000, currentValue: 0,
            expReward: 100, difficulty: .easy, status: .available,
            timeLimit: nil, targetObject: nil, coordinate: nil),

    Mission(id: "m2", title: "Weekend Warrior",
            description: "Complete 3000 steps today",
            type: .steps, targetValue: 3000, currentValue: 0,
            expReward: 300, difficulty: .hard, status: .available,
            timeLimit: nil, targetObject: nil, coordinate: nil),

    // Distance missions
    Mission(id: "m3", title: "Morning Sprinter",
            description: "Run 500m before 9AM",
            type: .distance, targetValue: 500, currentValue: 0,
            expReward: 150, difficulty: .medium, status: .available,
            timeLimit: 60, targetObject: nil,
            coordinate: CLLocationCoordinate2D(latitude: 32.0620, longitude: 118.7980)),

    Mission(id: "m4", title: "City Explorer",
            description: "Walk 1km around your city",
            type: .distance, targetValue: 1000, currentValue: 0,
            expReward: 200, difficulty: .medium, status: .available,
            timeLimit: nil, targetObject: nil,
            coordinate: CLLocationCoordinate2D(latitude: 32.0590, longitude: 118.7950)),

    // Photo missions
    Mission(id: "m5", title: "Nature Spotter",
            description: "Find and photograph a plant or tree",
            type: .photo, targetValue: 1, currentValue: 0,
            expReward: 200, difficulty: .easy, status: .available,
            timeLimit: nil, targetObject: "plant", coordinate: nil),

    Mission(id: "m6", title: "Cyclist Tracker",
            description: "Spot a bicycle anywhere in the city",
            type: .photo, targetValue: 1, currentValue: 0,
            expReward: 250, difficulty: .easy, status: .available,
            timeLimit: nil, targetObject: "bicycle", coordinate: nil),

    Mission(id: "m7", title: "Bottle Hunter",
            description: "Find 2 bottles anywhere around you",
            type: .photo, targetValue: 2, currentValue: 0,
            expReward: 180, difficulty: .easy, status: .available,
            timeLimit: nil, targetObject: "bottle", coordinate: nil),
]

// MARK: - Leaderboard (current user at rank 5)
static let leaderboard: [LeaderboardEntry] = [
    LeaderboardEntry(rank: 1, username: "SpeedKing99",  exp: 8420, level: 16, character: .sportsmanM),
    LeaderboardEntry(rank: 2, username: "RunnerGirl",   exp: 7890, level: 15, character: .sportsmanF),
    LeaderboardEntry(rank: 3, username: "CityWalker",   exp: 6540, level: 13, character: .studentF),
    LeaderboardEntry(rank: 4, username: "BunnyHops",    exp: 5320, level: 10, character: .rabbit),
    LeaderboardEntry(rank: 5, username: "YouAreHere",   exp: 1340, level: 5,  character: .sportsmanM),
    LeaderboardEntry(rank: 6, username: "StepMaster",   exp: 1100, level: 4,  character: .studentF),
    LeaderboardEntry(rank: 7, username: "NightRunner",  exp: 890,  level: 3,  character: .sportsmanF),
    LeaderboardEntry(rank: 8, username: "LazyToActive", exp: 620,  level: 2,  character: .rabbit),
]

// MARK: - Communities
static let communities: [Community] = [
    Community(id: "c1", name: "Morning Runners",
              description: "Early birds who run before sunrise",
              memberCount: 1243, isJoined: false, tags: ["running", "morning"]),
    Community(id: "c2", name: "Weekend Warriors",
              description: "Make every weekend count",
              memberCount: 892, isJoined: true, tags: ["weekend", "casual"]),
    Community(id: "c3", name: "City Explorers",
              description: "Discover hidden gems on foot",
              memberCount: 567, isJoined: false, tags: ["walking", "exploration"]),
    Community(id: "c4", name: "Step Counter Squad",
              description: "Daily step challenges and accountability",
              memberCount: 2104, isJoined: false, tags: ["steps", "challenge"]),
    Community(id: "c5", name: "Campus Walkers",
              description: "Students walking beyond class",
              memberCount: 431, isJoined: false, tags: ["student", "campus"]),
]

// MARK: - Mock Map Events (Nanjing coordinates)
static let gameEvents: [GameEvent] = [
    GameEvent(id: "e1", title: "5K Fun Run",
              description: "Community run around Xuanwu Lake",
              coordinate: CLLocationCoordinate2D(latitude: 32.0742, longitude: 118.7975),
              expReward: 500, eventType: .run),
    GameEvent(id: "e2", title: "Morning Yoga",
              description: "Group yoga at Purple Mountain",
              coordinate: CLLocationCoordinate2D(latitude: 32.0603, longitude: 118.8464),
              expReward: 200, eventType: .wellness),
    GameEvent(id: "e3", title: "City Walk Challenge",
              description: "Walk the historic Qinhuai River route",
              coordinate: CLLocationCoordinate2D(latitude: 32.0176, longitude: 118.7975),
              expReward: 350, eventType: .walk),
]
```

---

## 14. Visual Design

**Theme:** Dark, urban, game-like. Inspired by the Figma prototype.

```swift
// Constants.swift — Colors
extension Color {
    static let cityBackground = Color(hex: "#0D0D1A")   // Deep dark navy
    static let cityCard       = Color(hex: "#1A1A2E")   // Card surface
    static let cityAccent     = Color(hex: "#00D4FF")   // Cyan — primary accent
    static let cityGreen      = Color(hex: "#39FF14")   // Neon green — EXP bar
    static let cityYellow     = Color(hex: "#FFD700")   // Gold — rewards
    static let cityPurple     = Color(hex: "#7B2FBE")   // Purple — secondary
    static let citySubtext    = Color(hex: "#8888AA")   // Dimmed text
}
```

**Map overlay layout (HomeView):**
```
┌─────────────────────────────┐
│ 😊 Lv.5  ████████░░ 1340EXP│  ← frosted glass top bar
│                             │
│     Apple Maps (fullscreen) │
│                             │
│   ⚡[Mission Pin]           │  ← cyan custom annotation
│         📍 (you)            │  ← CoreLocation blue dot
│   🎯[Event Pin]             │  ← mock event pin
│                             │
│ ┌─────────────────────────┐ │
│ │ 🎯 Daily Walker          │ │  ← frosted bottom card
│ │ 800 steps remaining      │ │
│ │ [Generate Route] [Start] │ │
│ └─────────────────────────┘ │
│                        💬   │  ← floating chat button
└─────────────────────────────┘
```

---

## 15. Navigation Structure

```
SplashView (2s)
  ├── LoginView → MainTabView
  └── SignUpView → CharacterSelectView → LoadingView → MainTabView

MainTabView (5 tabs)
  ├── 🗺️  HomeView
  │     ├── RoutePreviewView (sheet — after AI generates route)
  │     └── ActiveMissionView (fullscreen modal)
  │           └── MissionCompleteView (modal)
  ├── 🎯  MissionsView
  │     └── MissionDetailView (sheet)
  │           └── PhotoMissionView (for .photo type missions)
  ├── 🏆  LeaderboardView (mock)
  ├── 👥  CommunityView (mock)
  │     └── CommunityDetailView (sheet)
  └── 👤  ProfileView
        └── (stats, character display, weekly recap section)

+ Floating AIChatView (sheet — accessible from any tab)
```

---

## 16. Info.plist — Required Permissions

Add all of these via Xcode → Target → Info tab:

| Key | Value |
|---|---|
| NSLocationWhenInUseUsageDescription | CityFit needs your location to show the map and nearby missions. |
| NSLocationAlwaysAndWhenInUseUsageDescription | CityFit tracks your location during active missions. |
| NSMotionUsageDescription | CityFit uses motion sensors to detect your activity and count steps. |
| NSHealthShareUsageDescription | CityFit reads your step data from Apple Health. |
| NSHealthUpdateUsageDescription | CityFit saves workout data to Apple Health after missions. |
| NSCameraUsageDescription | CityFit uses the camera to detect objects for photo missions. |

---

## 17. Simulator Mock — PedometerService

CMPedometer does NOT work on Simulator. Always use this pattern:

```swift
class PedometerService: ObservableObject {
    @Published var stepCount: Int = 0
    @Published var distance: Double = 0.0
    @Published var activityType: String = "walking"

    #if targetEnvironment(simulator)
    private var mockTimer: Timer?

    func startMockTracking() {
        mockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.stepCount += 3
                self.distance += 2.5
            }
        }
    }

    func stopMockTracking() {
        mockTimer?.invalidate()
        mockTimer = nil
    }
    #else
    private let pedometer = CMPedometer()

    func startTracking() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedometer.startUpdates(from: Date()) { data, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                self.stepCount = data.numberOfSteps.intValue
                self.distance = data.distance?.doubleValue ?? 0
            }
        }
    }
    #endif
}
```

---

## 18. Build Phases

### Phase 1 — Core iOS App
- [ ] Create Xcode project (iOS 16.0 target)
- [ ] Add all Info.plist permissions
- [ ] Auth flow: Splash → Login → SignUp → CharacterSelect → Loading → Main
- [ ] UserDefaults persistence for UserProfile
- [ ] MainTabView with 5 tabs + floating chat button overlay
- [ ] HomeView: MapKit map, user blue dot, mission pins, game event pins
- [ ] LocationService: CoreLocation GPS
- [ ] MissionsView: step, distance, and photo mission cards
- [ ] MissionDetailView + start mission
- [ ] ActiveMissionView: live step count + distance + EXP multiplier display
- [ ] PedometerService: real on device, mocked on simulator
- [ ] EXP award + level up logic
- [ ] MissionCompleteView with animation
- [ ] ProfileView: character, level, EXP bar, stats, weekly steps
- [ ] Mock LeaderboardView
- [ ] Mock CommunityView + CommunityDetailView
- [ ] Mock GameEvent pins on MapKit

### Phase 2 — CoreML Activity Classifier
- [ ] Build data logger Swift app to record motion sensor CSV
- [ ] Record walking, running, stationary sessions (~20 min total)
- [ ] Train in CreateML (Activity Classification template)
- [ ] Export ActivityClassifier.mlmodel → add to Xcode
- [ ] Build ActivityService with real-time classification
- [ ] Connect to EXP multiplier in ActiveMissionView

### Phase 3 — AI Backend (Flask + CrewAI + Groq)
- [ ] Set up Flask project structure
- [ ] Configure Groq API key (.env)
- [ ] Build Chat Crew (1 agent) + /chat endpoint
- [ ] Build Route Crew (2 agents, sequential) + /route endpoint
- [ ] Build Vision Crew (1 agent, Groq Vision) + /verify-photo endpoint
- [ ] Test all endpoints with Postman or curl
- [ ] Set up Ngrok tunnel
- [ ] Build AIService.swift (URLSession calls)
- [ ] Build AIChatView + connect to /chat
- [ ] Build RoutePreviewView + connect to /route
- [ ] Build PhotoMissionView with Apple Vision + connect to /verify-photo

### Phase 4 — Polish + Testing
- [ ] Animations: EXP bar fill, mission complete celebration, level up
- [ ] Error states: no GPS, no network, AI unavailable
- [ ] Test GPS on simulator with Features → Location → City Run
- [ ] Physical device testing: real GPS, real pedometer
- [ ] Demo video recording (2 minutes)

---

## 19. Testing Strategy

### Simulator (Daily Development)
- MapKit: runs fine on simulator
- GPS movement: **Features → Location → City Run** preset
- Steps: PedometerService mock auto-increments every second
- AI: Ngrok URL works over any network including simulator

### Physical Device (Weekly — Lecturer's iPhone)
- Real GPS accuracy outdoors
- Real CMPedometer step counting
- Real activity classifier predictions
- Camera + Vision object detection

### Test Cases

| # | Test | Input | Expected Result |
|---|---|---|---|
| 1 | Map loads | App launch | Map renders, blue dot appears |
| 2 | Custom pins visible | Home screen | Mission pins show with correct colors |
| 3 | Mission start | Tap Start on Daily Walker | ActiveMissionView opens, counter at 0 |
| 4 | Step counting (sim) | Mock timer running | Steps increment every second |
| 5 | Mission complete | Reach target | MissionCompleteView + EXP awarded |
| 6 | Level up | EXP crosses threshold | Level increments + animation |
| 7 | Activity classifier | Walk with phone | Returns "walking" label |
| 8 | EXP multiplier | Run detected | 2x EXP applied |
| 9 | AI chat | Type message | Response in <5 seconds |
| 10 | Route generation | Tap Generate Route | Polyline drawn on map + metrics shown |
| 11 | Photo mission — high conf | Clear object in frame | Auto-detects, no snap needed |
| 12 | Photo mission — low conf | Ambiguous object | Snap button appears |
| 13 | Photo mission — Groq verify | Tap Snap | Groq confirms, mission updates |
| 14 | Mock leaderboard | Open tab | 8 entries, rank 5 highlighted |
| 15 | Mock community | Tap Join | Button toggles locally |
| 16 | AI unavailable | Backend offline | Shows "AI unavailable" gracefully |

---

## 20. How CityFit Beats FitnessCoachApp

| Technology | FitnessCoachApp | CityFit |
|---|---|---|
| CoreML | Action classifier (squat videos) | Activity classifier (motion sensors) |
| Camera AI | Apple Vision body pose | Apple Vision + Groq Vision (two-tier) |
| Multi-agent | CrewAI + Ollama | CrewAI + Groq (4 agents, 3 crews) |
| Map | ❌ None | ✅ MapKit real GPS |
| Route intelligence | ❌ | ✅ AI-generated walking routes |
| Works outdoors | ❌ Needs same WiFi | ✅ Ngrok works anywhere |
| Firebase | ✅ | ❌ UserDefaults (simpler) |
| A2A protocol | ✅ | ❌ Not needed |

**The key differentiators:**
1. Real map-based gameplay — FitnessCoachApp has no map at all
2. AI route generation — unique feature, not seen in most student projects
3. Two-tier vision detection — more sophisticated than single-model detection
4. CoreML on-device activity detection — different model type, different use case
5. Works fully outdoors over internet — FitnessCoachApp requires same WiFi

---

## 21. Report Structure (For Reference)

*The written report must be 100% your own words — no AI-generated text.*

**(1) Practical Significance (10pts)**
- Problem: Indonesian sedentary lifestyle, TikTok/gaming addiction, low exercise motivation
- Solution: CityFit gamifies fitness like Pokémon GO — turns walking into a game
- Target users: Indonesian young adults 18-25
- Real-world value: addresses both physical health and behavioral psychology

**(2) Competitor Analysis (10pts)**
- Pokémon GO: gamified + location-based but not fitness-focused
- Nike Run Club: fitness tracking but no gamification
- Strava: social fitness but no game loop
- Apple Health / Google Fit: pure data, zero engagement
- CityFit differentiator: gamification + fitness + location + AI coaching — none of the above have all four

**(3) Implementation Details (40pts)**
- System architecture diagram (iOS ↔ Ngrok ↔ Flask ↔ CrewAI ↔ Groq)
- Module design (Services, ViewModels, Views)
- Agent 1: Personal Coach — role, skills, input/output
- Agent 2: Route Planner — role, skills, input/output
- Agent 3: Fitness Calculator — role, skills, collaborates with Route Planner
- Agent 4: Object Detection Specialist — role, skills, Groq Vision
- Agent collaboration flow (sequential process in Route Crew)
- Agent tickets (task, acceptance criteria, status per agent)
- CoreML Activity Classifier — training process, data collection, integration
- Two-tier vision system — Apple Vision + Groq Vision, confidence thresholds

**(4) Testing (10pts)**
- Use test cases table from Section 19 above
- Simulator testing methodology
- Physical device testing
- Bug fixes and iterations

---

## 22. Notes for Claude Code

- **NEVER use iOS 17+ MapKit API** — always use `Map(coordinateRegion:showsUserLocation:annotationItems:)` style
- **NEVER use `#Preview {}`** — always use `PreviewProvider` struct
- Deployment target: iOS 16.0
- SwiftUI only — no UIKit unless absolutely required
- MVVM strictly — zero business logic in Views
- All mock data in `MockData.swift` — never hardcode in Views
- Backend URL in `Constants.swift` as `backendURL` — single source of truth
- PedometerService MUST have `#if targetEnvironment(simulator)` mock block
- All AI features must gracefully degrade — show error message if backend unreachable, app continues working
- When building MapKit annotations, use `MapAnnotation` not `MapMarker` for custom SwiftUI pin views
- For MKDirections walking routes, always set `request.transportType = .walking`
- GFW note: all external API calls go to Groq (works in China) — never use OpenAI, Google, etc.
