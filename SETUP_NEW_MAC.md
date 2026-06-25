# Setting Up CityFit on a New Mac

## Before you build, do these steps manually (not in git):

### 1. Add GoogleService-Info.plist
`GoogleService-Info.plist` is gitignored (contains Firebase API keys) and never
travels via git — every machine needs its own copy.
- Go to [Firebase Console](https://console.firebase.google.com) → CityFit project →
  Project Settings → Your apps → the iOS app for bundle ID **`com.kenneth.cityfit`**
- Download `GoogleService-Info.plist`
- Drag it into Xcode under `CityFit iOS Project/` folder
- Make sure "Copy items if needed" is checked and the app target is selected
- Confirm its `REVERSED_CLIENT_ID` matches the URL scheme already committed in
  `CityFit-iOS-Project-Info.plist` — if it doesn't, update that file's
  `CFBundleURLSchemes` entry to match.

### 2. Set Signing Team to your own Apple ID
- Xcode → Target → Signing & Capabilities → **Team**
- Click **Add an Account…** if your Apple ID isn't listed, then select it
- Bundle Identifier should already read `com.kenneth.cityfit` from git — don't
  change it
- **Why this matters:** App IDs are global across Apple's developer accounts.
  Whichever Apple ID is selected in Team the first time a machine builds is the
  one that registers `com.kenneth.cityfit`. If you build with the wrong Apple ID
  selected, that account claims the bundle ID and locks everyone else out of it —
  this already happened once with an earlier bundle ID
  (`com.yakhekenneth.CityFit`, registered under a friend's Apple ID), which is
  why the project switched to `com.kenneth.cityfit`. Don't repeat it: always
  double check Team is set to *your own* Apple ID before the first build on any
  new machine.

### 3. Firebase SDK packages (should auto-resolve)
SPM packages are declared in `project.pbxproj` — Xcode should resolve them
automatically on open (File → Packages → Resolve Package Versions if it doesn't
happen on its own).

If you hit **"Package.resolved file is corrupted or malformed... unknown
'PinsStorage' version '3'"**: this project uses Xcode 14.3.1, which only
understands the older v1/v2 `Package.resolved` format. If a different machine's
newer Xcode re-resolved and pushed a v3-format file, delete
`CityFit iOS Project.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
and let Xcode 14.3.1 regenerate it from the package references in `pbxproj`.

If you hit **"package product 'nanopb' requires minimum platform version 12.0...
but this target supports 11.0"**: this is a known Firebase 10.29.0 SPM bug — it
allows nanopb up to a version that bumped its iOS floor to 12.0, while Firebase's
own manifest still claims iOS 11. This is already fixed by pinning `nanopb` to an
exact version (`2.30910.0`) as an explicit package dependency in this project —
it should just work via git pull. If it ever resurfaces, **don't** run
"Update to Latest Package Versions" on Xcode 14.3.1 for this project; use plain
"Resolve Package Versions" instead, which respects the exact pin.

Do NOT try upgrading Firebase past 10.x to "fix" this — Firebase 11.x+ requires
`swift-tools-version:5.9` (Swift 5.9), but Xcode 14.3.1 only ships Swift 5.8.1
and can't even parse that manifest.

If packages fail to download entirely (not a format/version error, just stuck or
failing fetches), check connectivity to `dl.google.com` specifically — Firebase's
binary artifacts (grpc, abseil, Firestore binary) are hosted there separately
from `github.com`, and this domain has been blocked from mainland China even over
VPN in the past.

### 4. GoogleSignIn URL Scheme
Already committed in `CityFit-iOS-Project-Info.plist` — just verify it matches
the `REVERSED_CLIENT_ID` from the `GoogleService-Info.plist` you downloaded in
step 1 (see note there).
