# Setting Up CityFit on a New Mac

## Before you build, do these steps manually (not in git):

### 1. Add GoogleService-Info.plist
`GoogleService-Info.plist` is gitignored (contains Firebase API keys).
- Go to [Firebase Console](https://console.firebase.google.com) → CityFit iOS App → Project Settings → Your apps → iOS app
- Download `GoogleService-Info.plist`
- Drag it into Xcode under `CityFit iOS Project/` folder
- Make sure "Copy items if needed" is checked and the app target is selected

### 2. Switch Signing Team
- Xcode → Target → Signing & Capabilities
- Change **Team** to your personal Apple ID (Marcellino Nathanael)
- Bundle ID should already be `com.yakhekenneth.CityFit` from git

### 3. Firebase SDK (if not already resolved)
SPM packages are in git via `project.pbxproj` — Xcode should resolve them automatically.
If not, add manually via File → Add Package Dependencies:
- `https://github.com/firebase/firebase-ios-sdk` → FirebaseAuth + FirebaseFirestore
- `https://github.com/google/GoogleSignIn-iOS` → GoogleSignIn

### 4. GoogleSignIn URL Scheme
In Xcode → Target → Info → URL Types, make sure there's an entry with:
- URL Scheme = your `REVERSED_CLIENT_ID` from `GoogleService-Info.plist`
(looks like `com.googleusercontent.apps.1085245035670-xxxx`)
