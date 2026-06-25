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

### 2. Create your own Config/Local.xcconfig (per-machine signing identity)
Two Apple IDs are permanently in play on this project — Marcellino's personal
team (owns `com.yakhekenneth.CityFit`) and Kenneth's personal team (owns
`com.kenneth.cityfit`). App IDs are global across Apple's developer accounts,
so the same bundle ID can never be signed by both — this already caused a
breakage loop once (switching the committed bundle ID back and forth every
time the project moved between machines).

The fix: `PRODUCT_BUNDLE_IDENTIFIER` and `DEVELOPMENT_TEAM` are **not**
hardcoded in `project.pbxproj` anymore. They come from
`Config/Shared.xcconfig` (committed, holds Kenneth's identity as the
canonical default) optionally overridden by `Config/Local.xcconfig`
(gitignored — every machine has its own, never committed).

On a new machine:
- Create `Config/Local.xcconfig` (it won't exist after a fresh clone) with:
  ```
  PRODUCT_BUNDLE_IDENTIFIER = com.yourbundleid.here
  DEVELOPMENT_TEAM = YOURTEAMID
  ```
- Find your Team ID via `security find-identity -v -p codesigning`, then
  `security find-certificate -c "Apple Development: <name/email shown>" -p | openssl x509 -noout -subject`
  — the `OU=` field is the real Team ID (the parenthetical after your name in
  the identity list is **not** the Team ID, don't use that one).
- **Do not** set Team or Bundle Identifier via Xcode's Signing & Capabilities
  UI after this — picking a value there writes it back as an inline override
  in `project.pbxproj`, which is committed and will silently re-break the
  *other* machine on next pull. Edit `Config/Local.xcconfig` by hand instead.
- This machine's values: `com.yakhekenneth.CityFit` / `9F2TJU8B45`
  (Marcellino). Lab Mac's values: `com.kenneth.cityfit` / `MGUFYQ4S2L`
  (Kenneth) — already the Shared.xcconfig default, so the lab Mac doesn't
  strictly need its own Local.xcconfig, but creating one explicitly is safer
  against future default changes.

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
