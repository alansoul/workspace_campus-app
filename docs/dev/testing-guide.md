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

## Cloud Development & Live Preview (GitHub Codespaces — 0% Laptop Heat/RAM)

1. **Open Codespace:** On GitHub (`alansoul/workspace_campus-app`), click **`<> Code` -> `Codespaces` -> `Create codespace on main`**.
   - `.devcontainer/devcontainer.json` + `.devcontainer/setup.sh` install Flutter automatically and forward port `8080`.
2. **Start Live Preview Server:**
   ```bash
   flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
   ```
   - Press `r` in the terminal anytime for instant hot reload.
3. **Preview on Mobile Browser (Phone) & Desktop:**
   - **Laptop Chrome/Edge:** Click the forwarded `8080` URL popup (press `F12` -> Device Toolbar to toggle phone vs desktop width).
   - **Phone Chrome/Safari:** Open the **Ports** tab in Codespaces, right-click port `8080` -> **Port Visibility -> Public**, and open the `https://<codespace>-8080.app.github.dev` URL on your phone (or scan it via QR / sign into GitHub on your phone browser if kept Private).

## GitHub Actions Workflows

- **CI Pipeline (`.github/workflows/ci.yml`):** Runs lightweight `validate` checks (format check, `flutter analyze`, `flutter test --coverage`) on every push/PR to `main`/`develop` without burning build minutes on binaries.
- **Manual / Tag Build Pipeline (`.github/workflows/build-flutter.yml`):** Trigger manually via **Actions → Build Flutter APK & Windows EXE → Run workflow** (or push a `v*` tag) to build `Northstar-Android-APK` and `Northstar-Windows-EXE` (`Northstar-Windows.zip`).
- **Release Pipeline (`.github/workflows/release.yml`):** Pushing a version tag (`v1.0.0`) builds both platforms and publishes `campus_mobile-android.apk` + `campus_mobile-windows-x64.zip` to a GitHub Release.
- **PR Automation:** `.github/workflows/label-pr.yml` applies domain/platform labels via `labeler.yml`, and `.github/workflows/stale.yml` manages inactive issues/PRs.
