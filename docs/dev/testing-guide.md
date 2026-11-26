# Flutter Testing & Build Guide (`campus_mobile`)

## Local Verification Commands

Run these checks inside `campus_mobile/` before opening a pull request:

```powershell
# 1. Fetch dependencies
flutter pub get

# 2. Check formatting
dart format --output=none --set-exit-if-changed lib test

# 3. Static analysis
flutter analyze --no-fatal-infos

# 4. Unit & widget tests (with coverage)
flutter test --coverage
```

## Building Release Binaries

### Android (`.apk`)
```powershell
flutter build apk --release
```
- Output: `build/app/outputs/flutter-apk/app-release.apk`
- Note: Update `android/app/build.gradle.kts` with a release keystore before Play Store distribution.

### Windows Desktop (`.exe`)
```powershell
flutter build windows --release
```
- Output: `build/windows/x64/runner/Release/campus_mobile.exe`
- Ship the entire `Release/` folder (or package it into a ZIP / installer), because `.exe` depends on the sibling `.dll` files and `data/` directory.

## GitHub Actions Workflows

- **CI Pipeline (`.github/workflows/ci.yml`):** Runs `validate` (format check, `flutter analyze`, `flutter test --coverage`) on every push/PR to `main`/`develop`, and builds both the Android `.apk` and Windows `.exe` artifacts on pushes to `main`/`develop` or manual `workflow_dispatch`.
- **Release Pipeline (`.github/workflows/release.yml`):** Pushing a version tag (`v1.0.0`) builds both platforms and publishes `campus_mobile-android.apk` + `campus_mobile-windows-x64.zip` to a GitHub Release.
- **PR Automation:** `.github/workflows/label-pr.yml` applies domain/platform labels via `labeler.yml`, and `.github/workflows/stale.yml` manages inactive issues/PRs.
