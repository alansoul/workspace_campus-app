# `campus_mobile` Project Structure & File Map

> **Auto-maintained by [`scripts/update_project_structure.mjs`](./scripts/update_project_structure.mjs)** (synced between `docs/project-structure.md` & `FILE_MAP.md`).  
> Automatically updates whenever folders/files are added, renamed, or deleted via:
> 1. **Live IDE Watcher** — `node scripts/update_project_structure.mjs --watch` (auto-starts via `.vscode/tasks.json`)
> 2. **Git Hooks** — runs automatically before every `git commit`, checkout, or merge (`node scripts/install_hooks.mjs`)
> 3. **GitHub Actions** — [`sync-docs.yml`](./.github/workflows/sync-docs.yml) updates PRs automatically if structure changes remotely

**Status Legend:** `✅` Active logic · `🎨` UI / screens / widgets / theme · `⬜` Empty scaffold (`.gitkeep`) · `🧪` Tests · `⚙️` Tooling / CI · `🖼️` Icons & graphics

- **Active Dart source files under `lib/`:** 29
- **Empty scaffold folders ready to build (`.gitkeep`):** 49

---

## Live Folder & File Tree (with Side Descriptions)

```text
campus_mobile/                                               # Flutter multi-platform client root (Android APK, Windows EXE, Web)
├── pubspec.yaml                                             # Flutter dependencies, SDK constraints, and registered assets
├── analysis_options.yaml                                    # Dart static analyzer rules & lint configuration
├── README.md                                                # Architecture overview, Mermaid diagram, and setup notes
├── FILE_MAP.md                                              # Auto-synced mirror of docs/project-structure.md in project root
├── lib/                                                     # Application Dart source root (Clean 4-Box / Feature-First layout)
│   ├── app/                                                 # App-wide shell, navigation router, and adaptive desktop/mobile frames
│   │   ├── router/                                          # ⬜ Empty scaffold (.gitkeep) — App routing layer (planned go_router setup)
│   │   └── shells/                                          # ⬜ Empty scaffold (.gitkeep) — Responsive top-level shells (planned MobileShell + DesktopShell)
│   ├── core/                                                # Shared infrastructure used across all features
│   │   ├── config/                                          # ⬜ Empty scaffold (.gitkeep) — App configuration & environment values
│   │   ├── constants/                                       # Global constants (API routes & UI color tokens)
│   │   │   ├── api_endpoints.dart                           # ✅ Backend base URL & auth/university API endpoint constants
│   │   │   └── app_colors.dart                              # 🎨 Global UI color palette (primary, aurora pastels, text, status)
│   │   ├── network/                                         # HTTP networking client & authentication interceptors
│   │   │   ├── api_client.dart                              # ✅ Configured Dio client provider with base options & interceptor wiring
│   │   │   └── auth_interceptor.dart                        # ✅ Automatic Bearer token attach, cookie handling & 401 refresh
│   │   ├── platform/                                        # ⬜ Empty scaffold (.gitkeep) — Platform-specific integrations (Windows window / OS hooks)
│   │   ├── realtime/                                        # ⬜ Empty scaffold (.gitkeep) — Realtime services (planned Socket.IO chat & LiveKit calls)
│   │   ├── responsive/                                      # ⬜ Empty scaffold (.gitkeep) — Screen breakpoints & responsive AdaptiveBuilder helpers
│   │   ├── storage/                                         # Local encrypted storage & persistence services
│   │   │   └── secure_storage_service.dart                  # ✅ Encrypted token storage (Keychain / Keystore / Win Credential Vault)
│   │   └── theme/                                           # ⬜ Empty scaffold (.gitkeep) — Global ThemeData, typography & dark/light theme definitions
│   ├── features/                                            # Feature modules (1 self-contained folder per product domain)
│   │   ├── academics/                                       # Academics domain (Timetable, Attendance, Assignments, Notes)
│   │   │   ├── data/                                        # Data layer (models, services, repositories)
│   │   │   │   ├── models/                                  # ⬜ Empty scaffold (.gitkeep) — ready for models code
│   │   │   │   ├── repositories/                            # ⬜ Empty scaffold (.gitkeep) — ready for repositories code
│   │   │   │   └── services/                                # ⬜ Empty scaffold (.gitkeep) — ready for services code
│   │   │   └── presentation/                                # UI layer (controllers, screens, widgets)
│   │   │       ├── controllers/                             # ⬜ Empty scaffold (.gitkeep) — ready for controllers code
│   │   │       ├── screens/                                 # ⬜ Empty scaffold (.gitkeep) — ready for screens code
│   │   │       └── widgets/                                 # ⬜ Empty scaffold (.gitkeep) — ready for widgets code
│   │   ├── admin/                                           # Admin Console domain (Campus moderation & telemetry)
│   │   │   ├── data/                                        # Data layer (models, services, repositories)
│   │   │   │   ├── models/                                  # ⬜ Empty scaffold (.gitkeep) — ready for models code
│   │   │   │   ├── repositories/                            # ⬜ Empty scaffold (.gitkeep) — ready for repositories code
│   │   │   │   └── services/                                # ⬜ Empty scaffold (.gitkeep) — ready for services code
│   │   │   └── presentation/                                # UI layer (controllers, screens, widgets)
│   │   │       ├── controllers/                             # ⬜ Empty scaffold (.gitkeep) — ready for controllers code
│   │   │       ├── screens/                                 # ⬜ Empty scaffold (.gitkeep) — ready for screens code
│   │   │       └── widgets/                                 # ⬜ Empty scaffold (.gitkeep) — ready for widgets code
│   │   ├── auth/                                            # ✅ Complete Authentication, OTP, Password Reset, Google OAuth & University Onboarding
│   │   │   ├── data/                                        # Auth API services, data models & repository layer
│   │   │   │   ├── models/                                  # Auth request/response & user profile models
│   │   │   │   │   ├── auth_models.dart                     # ✅ Domain resolution, OTP verification & onboarding payloads
│   │   │   │   │   └── user_model.dart                      # ✅ Authenticated campus UserModel (role, university, metadata)
│   │   │   │   ├── services/                                # HTTP auth calls & cross-platform Google OAuth handlers
│   │   │   │   │   ├── auth_api_service.dart                # ✅ Auth REST endpoints (login, register, OTP, reset, domain resolve)
│   │   │   │   │   ├── google_oauth_service_io.dart         # ✅ Android deep-link & Windows loopback localhost Google OAuth flow
│   │   │   │   │   ├── google_oauth_service_stub.dart       # ✅ Web browser redirect Google OAuth flow
│   │   │   │   │   └── google_oauth_service.dart            # ✅ Conditional export choosing IO vs Web Google OAuth implementation
│   │   │   │   └── auth_repository.dart                     # ✅ Coordinates auth API calls with secure token persistence
│   │   │   └── presentation/                                # Auth state controllers, screens & reusable auth UI widgets
│   │   │       ├── controllers/                             # Auth Riverpod state notifiers
│   │   │       │   └── auth_controller.dart                 # ✅ Main AuthController & AuthFlowController (multi-step auth state)
│   │   │       ├── screens/                                 # Auth screens
│   │   │       │   └── login_screen.dart                    # 🎨 Responsive Auth screen (fixed card + Desktop showcase + flows)
│   │   │       └── widgets/                                 # Modular Auth UI building blocks
│   │   │           ├── auth_form_fields.dart                # 🎨 Styled inputs, primary/secondary buttons & feedback banners
│   │   │           ├── domain_status_banner.dart            # 🎨 Live university domain / admin / student verification pill
│   │   │           ├── fluid_auth_backdrop.dart             # 🎨 Pastel aurora gradient & frosted glass auth background
│   │   │           ├── forgot_password_flow.dart            # 🎨 Password reset via 6-digit email OTP workflow widget
│   │   │           ├── google_oauth_button.dart             # 🎨 Branded Continue with Google OAuth button & loading state
│   │   │           ├── otp_code_boxes.dart                  # 🎨 6-digit OTP verification input boxes with auto-focus & paste
│   │   │           ├── password_strength_checklist.dart     # 🎨 Live password requirements checklist widget
│   │   │           ├── segmented_pill_switch.dart           # 🎨 Smooth pill toggle (Login/Register, Password/OTP)
│   │   │           └── university_onboarding_sheet.dart     # 🎨 Modal sheet for admins to claim & create a university workspace
│   │   ├── chat/                                            # Campus Chat domain (Channels, DMs & LiveKit calls)
│   │   │   ├── data/                                        # Data layer (models, services, repositories)
│   │   │   │   ├── models/                                  # ⬜ Empty scaffold (.gitkeep) — ready for models code
│   │   │   │   ├── repositories/                            # ⬜ Empty scaffold (.gitkeep) — ready for repositories code
│   │   │   │   └── services/                                # ⬜ Empty scaffold (.gitkeep) — ready for services code
│   │   │   └── presentation/                                # UI layer (controllers, screens, widgets)
│   │   │       ├── controllers/                             # ⬜ Empty scaffold (.gitkeep) — ready for controllers code
│   │   │       ├── screens/                                 # ⬜ Empty scaffold (.gitkeep) — ready for screens code
│   │   │       └── widgets/                                 # ⬜ Empty scaffold (.gitkeep) — ready for widgets code
│   │   ├── copilot/                                         # AI Copilot domain (Academic assistant & reasoning)
│   │   │   ├── data/                                        # Data layer (models, services, repositories)
│   │   │   │   ├── models/                                  # ⬜ Empty scaffold (.gitkeep) — ready for models code
│   │   │   │   ├── repositories/                            # ⬜ Empty scaffold (.gitkeep) — ready for repositories code
│   │   │   │   └── services/                                # ⬜ Empty scaffold (.gitkeep) — ready for services code
│   │   │   └── presentation/                                # UI layer (controllers, screens, widgets)
│   │   │       ├── controllers/                             # ⬜ Empty scaffold (.gitkeep) — ready for controllers code
│   │   │       ├── screens/                                 # ⬜ Empty scaffold (.gitkeep) — ready for screens code
│   │   │       └── widgets/                                 # ⬜ Empty scaffold (.gitkeep) — ready for widgets code
│   │   ├── dashboard/                                       # ✅ Post-login Workspace Hub, Bottom Navigation & Starter Module Views
│   │   │   ├── data/                                        # Data layer (models, services, repositories)
│   │   │   │   ├── models/                                  # ⬜ Empty scaffold (.gitkeep) — ready for models code
│   │   │   │   ├── repositories/                            # ⬜ Empty scaffold (.gitkeep) — ready for repositories code
│   │   │   │   └── services/                                # ⬜ Empty scaffold (.gitkeep) — ready for services code
│   │   │   └── presentation/                                # Dashboard UI screens & widgets
│   │   │       ├── controllers/                             # ⬜ Empty scaffold (.gitkeep) — ready for controllers code
│   │   │       ├── screens/                                 # Dashboard shell & starter module pages
│   │   │       │   ├── dashboard_shell.dart                 # 🎨 AppBar, Bottom Nav (Home/Admin/Profile) & AI Copilot sheet
│   │   │       │   └── module_screens.dart                  # 🎨 Starter screens for Academics, Channels & Freelance modules
│   │   │       └── widgets/                                 # Dashboard cards & navigation overlays
│   │   │           ├── capsule_card.dart                    # 🎨 Gradient feature launcher cards on Home Hub
│   │   │           └── edge_switcher_overlay.dart           # 🎨 Right-edge slide-out quick app switcher & Copilot trigger
│   │   ├── freelance/                                       # Freelance & Escrow domain (Gigs & milestone contracts)
│   │   │   ├── data/                                        # Data layer (models, services, repositories)
│   │   │   │   ├── models/                                  # ⬜ Empty scaffold (.gitkeep) — ready for models code
│   │   │   │   ├── repositories/                            # ⬜ Empty scaffold (.gitkeep) — ready for repositories code
│   │   │   │   └── services/                                # ⬜ Empty scaffold (.gitkeep) — ready for services code
│   │   │   └── presentation/                                # UI layer (controllers, screens, widgets)
│   │   │       ├── controllers/                             # ⬜ Empty scaffold (.gitkeep) — ready for controllers code
│   │   │       ├── screens/                                 # ⬜ Empty scaffold (.gitkeep) — ready for screens code
│   │   │       └── widgets/                                 # ⬜ Empty scaffold (.gitkeep) — ready for widgets code
│   │   └── settings/                                        # Profile & app preferences domain
│   │       ├── data/                                        # Data layer (models, services, repositories)
│   │       │   ├── models/                                  # ⬜ Empty scaffold (.gitkeep) — ready for models code
│   │       │   ├── repositories/                            # ⬜ Empty scaffold (.gitkeep) — ready for repositories code
│   │       │   └── services/                                # ⬜ Empty scaffold (.gitkeep) — ready for services code
│   │       └── presentation/                                # UI layer (controllers, screens, widgets)
│   │           ├── controllers/                             # ⬜ Empty scaffold (.gitkeep) — ready for controllers code
│   │           ├── screens/                                 # ⬜ Empty scaffold (.gitkeep) — ready for screens code
│   │           └── widgets/                                 # ⬜ Empty scaffold (.gitkeep) — ready for widgets code
│   ├── shared/                                              # Shared cross-feature UI design system & reusable widgets
│   │   └── widgets/                                         # Reusable UI components shared by multiple features
│   │       └── northstar_logo.dart                          # 🎨 Custom vector Northstar logo (3D tilt, 60 sparkles, 4 animation modes)
│   └── main.dart                                            # ✅ Entry point: Sentry init, Material 3 theme, Startup Splash & Auth gate
├── assets/                                                  # Bundled static assets declared in pubspec.yaml
│   ├── icons/                                               # ⬜ Empty scaffold (.gitkeep) — App custom icon assets directory (for SVG / PNG UI icons)
│   ├── images/                                              # ⬜ Empty scaffold (.gitkeep) — App static image assets directory (illustrations / photos)
│   └── logo/                                                # Northstar vector SVG brand assets (static badge, mark, animated)
│       ├── northstar-logo-animated.svg                      # 🖼️ Exact 4.4s CSS-animated SVG with 60 sparkles & comet sweep
│       ├── northstar-logo.svg                               # 🖼️ Static 512x512 Northstar obsidian squircle vector SVG
│       └── northstar-mark.svg                               # 🖼️ Transparent floating Northstar monogram SVG (N + orbit + star)
├── test/                                                    # Automated Flutter unit, widget & security hardening tests
│   ├── core/                                                # Core security & infrastructure test suites
│   │   └── security_hardening_test.dart                     # 🧪 Verifies HTTPS enforcement, allowBackup=false & safe OAuth rules
│   ├── auth_flow_test.dart                                  # 🧪 Multi-step login, OTP, onboarding & validation widget tests
│   └── widget_test.dart                                     # 🧪 Smoke tests ensuring app boots & auth UI renders cleanly
├── docs/                                                    # Repository documentation & live auto-generated project maps
│   ├── dev/                                                 # Developer guides (testing, local builds, workflows)
│   │   └── testing-guide.md                                 # 📘 Doc: Flutter Testing & Build Guide (`campus_mobile`)
│   └── project-structure.md                                 # 📘 Auto-generated live folder & file reference (this file)
├── scripts/                                                 # Developer automation scripts & git hook installers
│   ├── install_hooks.mjs                                    # ⚙️ Installs pre-commit / post-checkout / post-merge git hooks
│   └── update_project_structure.mjs                         # ⚙️ Auto-generates & watches docs/project-structure.md + FILE_MAP.md
├── .github/                                                 # GitHub Actions CI/CD, build workflows, templates & labels
│   ├── actions/                                             # Reusable composite GitHub Actions steps
│   │   └── setup-flutter/                                   # Composite GitHub Action to install & cache Flutter SDK
│   │       └── action.yml                                   # ⚙️ Reusable Flutter setup workflow step definition
│   ├── ISSUE_TEMPLATE/                                      # GitHub Bug Report & Feature Request issue templates
│   │   ├── bug.yml                                          # ⚙️ YAML configuration
│   │   └── feature.yml                                      # ⚙️ YAML configuration
│   ├── workflows/                                           # Automated cloud pipelines (CI, APK/EXE build, Security, Releases)
│   │   ├── build-flutter.yml                                # ⚙️ Cloud builds Android .apk & Windows .exe release artifacts
│   │   ├── ci.yml                                           # ⚙️ Runs Dart format check, flutter analyze, tests & web build on PRs
│   │   ├── label-pr.yml                                     # ⚙️ Auto-labels PRs using .github/labeler.yml
│   │   ├── release.yml                                      # ⚙️ Creates tagged GitHub Releases with APK & EXE binaries
│   │   ├── security.yml                                     # ⚙️ Gitleaks secret scan & client security hardening tests
│   │   ├── stale.yml                                        # ⚙️ Marks & closes stale GitHub issues and PRs
│   │   └── sync-docs.yml                                    # ⚙️ Auto-updates project structure docs on PRs if files change
│   ├── CODEOWNERS                                           # ⚙️ Default PR code review owners
│   ├── dependabot.yml                                       # ⚙️ Automated dependency & workflow update checks
│   ├── labeler.yml                                          # ⚙️ Rules for auto-labeling PRs based on changed paths
│   └── pull_request_template.md                             # 📘 Doc: 🔀 Flutter App Pull Request
├── android/app/src/                                         # Android native manifests, launcher icons & security config
│   ├── debug/                                               # Debug build manifest overrides
│   │   └── AndroidManifest.xml                              # 📱 Android XML resource / configuration
│   ├── main/                                                # Main Android application source & resources
│   │   ├── kotlin/                                          # Native Android Kotlin application entry point
│   │   │   └── in/                                          # Directory
│   │   │       └── edu/                                     # Directory
│   │   │           └── iiitnr/                              # Directory
│   │   │               └── campus_mobile/                   # Directory
│   │   │                   └── MainActivity.kt              # 📱 Main Android Activity hosting the Flutter engine
│   │   ├── res/                                             # Android XML resources, splash drawables & launcher icons
│   │   │   ├── drawable/                                    # Android default launch splash drawable
│   │   │   │   └── launch_background.xml                    # 📱 Android pre-v21 launch splash background XML
│   │   │   ├── drawable-v21/                                # Android API 21+ launch splash drawable
│   │   │   │   └── launch_background.xml                    # 📱 Android API 21+ launch splash background XML
│   │   │   ├── mipmap-hdpi/                                 # 🖼️ Android launcher icon density asset
│   │   │   │   └── ic_launcher.png                          # 🖼️ Image / icon asset
│   │   │   ├── mipmap-mdpi/                                 # 🖼️ Android launcher icon density asset
│   │   │   │   └── ic_launcher.png                          # 🖼️ Image / icon asset
│   │   │   ├── mipmap-xhdpi/                                # 🖼️ Android launcher icon density asset
│   │   │   │   └── ic_launcher.png                          # 🖼️ Image / icon asset
│   │   │   ├── mipmap-xxhdpi/                               # 🖼️ Android launcher icon density asset
│   │   │   │   └── ic_launcher.png                          # 🖼️ Image / icon asset
│   │   │   ├── mipmap-xxxhdpi/                              # 🖼️ Android launcher icon density asset
│   │   │   │   └── ic_launcher.png                          # 🖼️ Image / icon asset
│   │   │   ├── values/                                      # Light mode Android theme styles
│   │   │   │   └── styles.xml                               # 📱 Android light LaunchTheme & NormalTheme styles
│   │   │   ├── values-night/                                # Dark mode Android theme styles
│   │   │   │   └── styles.xml                               # 📱 Android dark LaunchTheme & NormalTheme styles
│   │   │   └── xml/                                         # Android XML security policies
│   │   │       └── network_security_config.xml              # 🔒 Enforces HTTPS globally (loopback allowed only for local OAuth)
│   │   └── AndroidManifest.xml                              # 📱 Android permissions, deep links (northstar://auth) & app metadata
│   └── profile/                                             # Profile build manifest overrides
│       └── AndroidManifest.xml                              # 📱 Android XML resource / configuration
├── windows/runner/                                          # Windows native Win32 runner, window config & taskbar icon
│   ├── resources/                                           # Windows native runner icon & bitmap resources
│   │   └── app_icon.ico                                     # 🖼️ Multi-size Windows .exe desktop & taskbar icon
│   ├── CMakeLists.txt                                       # ⚙️ CMake build definition for Windows desktop runner
│   ├── flutter_window.cpp                                   # 🪟 Native Windows C++ runner source
│   ├── flutter_window.h                                     # 🪟 Native Windows C++ runner source
│   ├── main.cpp                                             # 🪟 Native Windows C++ runner source
│   ├── resource.h                                           # 🪟 Native Windows C++ runner source
│   ├── runner.exe.manifest                                  # 🪟 Windows DPI-awareness & OS compatibility manifest
│   ├── Runner.rc                                            # 🪟 Windows version info & app_icon.ico resource script
│   ├── utils.cpp                                            # 🪟 Native Windows C++ runner source
│   ├── utils.h                                              # 🪟 Native Windows C++ runner source
│   ├── win32_window.cpp                                     # 🪟 Native Windows C++ runner source
│   └── win32_window.h                                       # 🪟 Native Windows C++ runner source
└── web/                                                     # Flutter Web & PWA entry HTML, manifest & browser/home-screen icons
    ├── icons/                                               # 🖼️ PWA & maskable launcher icons (192px & 512px)
    │   ├── Icon-192.png                                     # 🖼️ Image / icon asset
    │   ├── Icon-512.png                                     # 🖼️ Image / icon asset
    │   ├── Icon-maskable-192.png                            # 🖼️ Image / icon asset
    │   └── Icon-maskable-512.png                            # 🖼️ Image / icon asset
    ├── favicon.png                                          # 🖼️ Browser tab favicon
    ├── index.html                                           # 🌐 Flutter Web host page
    └── manifest.json                                        # 🌐 Web App / PWA metadata & icon declarations
```

---

## Quick UI Editing Guide (Where to Change What)

| UI Area | File to Edit | What It Controls |
| :--- | :--- | :--- |
| **Colors & Palette** | [`lib/core/constants/app_colors.dart`](./lib/core/constants/app_colors.dart) | Primary blue, aurora pastel gradients, text, border & status colors |
| **App Theme & Splash** | [`lib/main.dart`](./lib/main.dart) | Material 3 theme, `Inter` font & branded startup splash loader |
| **Brand Logo & Animations** | [`lib/shared/widgets/northstar_logo.dart`](./lib/shared/widgets/northstar_logo.dart) | Obsidian squircle, 3D tilt, 60 sparkles & 4 animation modes |
| **Login, OTP & Register** | [`lib/features/auth/presentation/screens/login_screen.dart`](./lib/features/auth/presentation/screens/login_screen.dart) | Responsive mobile auth card & wide desktop showcase panel |
| **Auth Reusable Widgets** | `lib/features/auth/presentation/widgets/*.dart` | Pastel backdrop, OTP boxes, password checklist, OAuth button, Org sheet |
| **Home Hub & Bottom Nav** | [`lib/features/dashboard/presentation/screens/dashboard_shell.dart`](./lib/features/dashboard/presentation/screens/dashboard_shell.dart) | Top AppBar, Home / Admin / Profile tabs & AI Copilot sheet |
| **Feature Cards & Switcher** | `lib/features/dashboard/presentation/widgets/*.dart` | `CapsuleCard` gradients & slide-out `EdgeSwitcherOverlay` |
| **Module Screens** | [`lib/features/dashboard/presentation/screens/module_screens.dart`](./lib/features/dashboard/presentation/screens/module_screens.dart) | Starter UIs for Academics, Channels & Freelance |
| **App / Taskbar Icons** | `android/app/src/main/res/mipmap-*/`, `windows/runner/resources/`, `web/icons/` | Static launcher icons installed on Android, Windows & Web |
