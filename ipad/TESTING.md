# iPad verification

Local verification on 2026-09-12:

- `Info.plist` and `project.pbxproj`: `plutil -lint` passed.
- Unsigned iOS Simulator build (arm64 + x86_64): passed with Xcode iOS 26.5 SDK.
- Unsigned iPad device build (arm64): passed. This verifies compilation only; it is not a signed IPA.
- Simulator launch / UI runtime test: not verified locally. The current automation sandbox could not connect to CoreSimulatorService. Do not describe this as a successful iPad runtime test.
- Physical iPad: not tested.

The included `PlannerUITests` checks bundled HTML loads in WKWebView and captures portrait/landscape screenshots. `.github/workflows/ipad.yml` runs it on an available iPad simulator; a successful workflow run is required before calling the simulator test passed.
