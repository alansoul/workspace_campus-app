# `campus_mobile` — Clean Project Map (Active Files & UI Guide)

> **Filtered live view** — shows **only your active code, assets, tests, and recent changes** (OS boilerplate & empty `.gitkeep` scaffolds are hidden automatically until you add code inside them).  
> Auto-updates via live watcher (`--watch`), Git `pre-commit` hook, and GitHub Actions [`sync-docs.yml`](../.github/workflows/sync-docs.yml).

## 🕒 Created & Edited Recently

| Status | File | What It Is For |
| :--- | :--- | :--- |
| `✏️ Edited` | [`.github/workflows/sync-docs.yml`](../.github/workflows/sync-docs.yml) | ⚙️ Auto-updates this doc on PRs if files change |
| `✏️ Edited` | [`scripts/update_project_structure.mjs`](../scripts/update_project_structure.mjs) | ⚙️ Auto-updates & watches this filtered project map |
| `🆕 New` | [`scripts/install_hooks.mjs`](../scripts/install_hooks.mjs) | ⚙️ Installs pre-commit / post-checkout / post-merge git hooks |
| `🆕 New` | [`.github/workflows/security.yml`](../.github/workflows/security.yml) | ⚙️ Secret scan & client security hardening checks |
| `✏️ Edited` | [`android/app/src/main/AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml) | 📱 Android permissions, deep links & app name |
| `✏️ Edited` | [`lib/core/constants/api_endpoints.dart`](../lib/core/constants/api_endpoints.dart) | ✅ Backend base URL & auth/university API routes |
| `🆕 New` | [`test/core/security_hardening_test.dart`](../test/core/security_hardening_test.dart) | 🧪 Enforces HTTPS config, allowBackup=false & safe OAuth |
| `✏️ Edited` | [`android/app/src/main/res/mipmap-hdpi/ic_launcher.png`](../android/app/src/main/res/mipmap-hdpi/ic_launcher.png) | 🖼️ Brand / icon asset |
| `✏️ Edited` | [`android/app/src/main/res/mipmap-mdpi/ic_launcher.png`](../android/app/src/main/res/mipmap-mdpi/ic_launcher.png) | 🖼️ Brand / icon asset |
| `✏️ Edited` | [`android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`](../android/app/src/main/res/mipmap-xhdpi/ic_launcher.png) | 🖼️ Brand / icon asset |
| `✏️ Edited` | [`android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`](../android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png) | 🖼️ Brand / icon asset |
| `✏️ Edited` | [`android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`](../android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png) | 🖼️ Brand / icon asset |

---

## 📂 Active Project Structure (with Side Descriptions)

```text
campus_mobile/                                         # Flutter multi-platform app (Android APK, Windows EXE, Web)
├── pubspec.yaml                                       # Dependencies, SDK version & bundled asset paths
├── analysis_options.yaml                              # Dart static analyzer & lint rules
├── README.md                                          # Architecture diagram & setup guide
├── lib/                                               # Your main Dart & Flutter app code
│   ├── core/                                          # Shared app-wide foundations
│   │   ├── constants/                                 # API URLs & global UI color palette
│   │   │   ├── api_endpoints.dart                     # ✅ Backend base URL & auth/university API routes [Edited]
│   │   │   └── app_colors.dart                        # 🎨 Global UI colors (primary, aurora pastels, text, borders)
│   │   ├── network/                                   # HTTP client & auth token interceptor
│   │   │   ├── api_client.dart                        # ✅ Configured Dio client provider
│   │   │   └── auth_interceptor.dart                  # ✅ Auto Bearer token attach, cookies & 401 refresh
│   │   └── storage/                                   # Encrypted local storage
│   │       └── secure_storage_service.dart            # ✅ Secure JWT token persistence (Keystore / Credential Vault)
│   ├── features/                                      # Feature modules (active code only; empty scaffolds summarized below)
│   │   ├── auth/                                      # ✅ Login, Register, OTP, Password Reset, Google OAuth & Org Onboarding
│   │   │   ├── data/                                  # Auth API calls, models & token repository
│   │   │   │   ├── models/                            # Auth & user data models
│   │   │   │   │   ├── auth_models.dart               # ✅ Domain resolution, OTP & onboarding payloads
│   │   │   │   │   └── user_model.dart                # ✅ Campus UserModel (role, university, profile)
│   │   │   │   ├── services/                          # REST auth service & platform-safe Google OAuth
│   │   │   │   │   ├── auth_api_service.dart          # ✅ Login, register, OTP, password reset & domain check calls
│   │   │   │   │   ├── google_oauth_service_io.dart   # ✅ Android deep-link & Windows loopback Google OAuth
│   │   │   │   │   ├── google_oauth_service_stub.dart   # ✅ Flutter Web redirect Google OAuth
│   │   │   │   │   └── google_oauth_service.dart      # ✅ Cross-platform Google OAuth entry export
│   │   │   │   └── auth_repository.dart               # ✅ Connects Auth API endpoints to secure storage
│   │   │   └── presentation/                          # Auth controllers, screen & UI widgets
│   │   │       ├── controllers/                       # Riverpod auth state management
│   │   │       │   └── auth_controller.dart           # ✅ Multi-step AuthController & AuthFlowController
│   │   │       ├── screens/                           # Auth screens
│   │   │       │   └── login_screen.dart              # 🎨 Main Auth card, OTP/Reset views & Desktop split showcase [Edited]
│   │   │       └── widgets/                           # Auth UI components
│   │   │           ├── auth_form_fields.dart          # 🎨 Inputs, buttons & error/info banners
│   │   │           ├── domain_status_banner.dart      # 🎨 University verified / admin badge banner
│   │   │           ├── fluid_auth_backdrop.dart       # 🎨 Aurora pastel frosted glass background
│   │   │           ├── forgot_password_flow.dart      # 🎨 Email OTP password reset widget
│   │   │           ├── google_oauth_button.dart       # 🎨 Branded Google Sign-In button
│   │   │           ├── otp_code_boxes.dart            # 🎨 6-digit OTP boxes with paste & auto-advance
│   │   │           ├── password_strength_checklist.dart   # 🎨 Password strength checklist
│   │   │           ├── segmented_pill_switch.dart     # 🎨 Login/Register & Password/OTP pill toggle
│   │   │           └── university_onboarding_sheet.dart   # 🎨 Admin onboarding bottom sheet to create an org
│   │   └── dashboard/                                 # ✅ Post-login Home Hub, Bottom Nav, Cards & Starter Modules
│   │       └── presentation/                          # Dashboard screens & cards
│   │           ├── screens/                           # Dashboard pages
│   │           │   ├── dashboard_shell.dart           # 🎨 Top AppBar, Home/Admin/Profile tabs & Copilot sheet [Edited]
│   │           │   └── module_screens.dart            # 🎨 Starter screens for Academics, Channels & Freelance
│   │           └── widgets/                           # Dashboard cards & overlays
│   │               ├── capsule_card.dart              # 🎨 Feature launcher gradient cards
│   │               └── edge_switcher_overlay.dart     # 🎨 Right-edge slide-out quick app switcher
│   ├── shared/                                        # Shared UI components used across screens
│   │   └── widgets/                                   # Reusable UI widgets
│   │       └── northstar_logo.dart                    # 🎨 Custom vector Northstar logo (3D tilt, 60 sparkles, 4 modes) [Edited]
│   └── main.dart                                      # ✅ App entry: Sentry setup, Material 3 theme, Splash & Auth gate [Edited]
├── assets/logo/                                       # 🖼️ Northstar vector SVG logo files (static, mark & 4.4s animated)
│   ├── northstar-logo-animated.svg                    # 🖼️ Exact 4.4s CSS-animated SVG (60 sparkles + comet) [Edited]
│   ├── northstar-logo.svg                             # 🖼️ Static 512x512 Northstar obsidian squircle SVG [Edited]
│   └── northstar-mark.svg                             # 🖼️ Transparent floating Northstar mark SVG [Edited]
├── test/                                              # 🧪 Automated tests (smoke, auth UI, security hardening)
│   ├── core/                                          # Core security tests
│   │   └── security_hardening_test.dart               # 🧪 Enforces HTTPS config, allowBackup=false & safe OAuth [New]
│   ├── auth_flow_test.dart                            # 🧪 Auth flow, OTP & onboarding widget tests
│   └── widget_test.dart                               # 🧪 App boot & login screen smoke tests
├── docs/                                              # 📘 Guides & this auto-filtered structure map
│   └── dev/                                           # Developer guides
│       └── testing-guide.md                           # 📘 Testing & APK/EXE cloud build guide
├── scripts/                                           # ⚙️ Automation scripts
│   ├── install_hooks.mjs                              # ⚙️ Installs pre-commit / post-checkout / post-merge git hooks [New]
│   └── update_project_structure.mjs                   # ⚙️ Auto-updates & watches this filtered project map [Edited]
├── .github/workflows/                                 # ⚙️ Cloud CI, security & APK/EXE build pipelines
│   ├── build-flutter.yml                              # ⚙️ Cloud build Android .apk & Windows .exe
│   ├── ci.yml                                         # ⚙️ PR validation (analyze, test, web build)
│   ├── label-pr.yml                                   # ⚙️ Auto-labels PRs
│   ├── release.yml                                    # ⚙️ GitHub Release binaries on tags
│   ├── security.yml                                   # ⚙️ Secret scan & client security hardening checks [New]
│   ├── stale.yml                                      # ⚙️ Closes stale issues/PRs
│   └── sync-docs.yml                                  # ⚙️ Auto-updates this doc on PRs if files change [Edited]
├── android/app/src/main/AndroidManifest.xml           # 📱 Android permissions, deep links & app name [Edited]
├── android/app/src/main/res/xml/network_security_config.xml   # 🔒 Forces HTTPS (loopback allowed for OAuth) [New]
├── windows/runner/resources/app_icon.ico              # 🖼️ Windows desktop app & taskbar icon
└── web/manifest.json                                  # 🌐 Flutter Web / PWA app icon & name config
```

> **⬜ Empty scaffold folders (auto-expand as soon as you add a `.dart` file inside):**  
> `app, core/config, core/platform, core/realtime, core/responsive, core/theme, features/academics, features/admin, features/chat, features/copilot, features/dashboard/data, features/dashboard/presentation/controllers, features/freelance, features/settings`

---

## 🎨 Quick UI Editing Guide (Where to Change What)

| UI Area | File to Edit | What It Controls |
| :--- | :--- | :--- |
| **Colors & Palette** | [`lib/core/constants/app_colors.dart`](../lib/core/constants/app_colors.dart) | Primary blue, aurora pastel gradients, text, border & status colors |
| **App Theme & Splash** | [`lib/main.dart`](../lib/main.dart) | Material 3 theme, `Inter` font & branded startup splash loader |
| **Brand Logo & Animations** | [`lib/shared/widgets/northstar_logo.dart`](../lib/shared/widgets/northstar_logo.dart) | Obsidian squircle, 3D tilt, 60 sparkles & 4 animation modes |
| **Login, OTP & Register** | [`lib/features/auth/presentation/screens/login_screen.dart`](../lib/features/auth/presentation/screens/login_screen.dart) | Responsive mobile auth card & wide desktop showcase panel |
| **Auth Reusable Widgets** | `lib/features/auth/presentation/widgets/*.dart` | Pastel backdrop, OTP boxes, password checklist, OAuth button, Org sheet |
| **Home Hub & Bottom Nav** | [`lib/features/dashboard/presentation/screens/dashboard_shell.dart`](../lib/features/dashboard/presentation/screens/dashboard_shell.dart) | Top AppBar, Home / Admin / Profile tabs & AI Copilot sheet |
| **Feature Cards & Switcher** | `lib/features/dashboard/presentation/widgets/*.dart` | `CapsuleCard` gradients & slide-out `EdgeSwitcherOverlay` |
| **Module Screens** | [`lib/features/dashboard/presentation/screens/module_screens.dart`](../lib/features/dashboard/presentation/screens/module_screens.dart) | Starter UIs for Academics, Channels & Freelance |
| **App / Taskbar Icons** | `android/app/src/main/res/mipmap-*/`, `windows/runner/resources/`, `web/icons/` | Static launcher icons installed on Android, Windows & Web |
