#!/usr/bin/env node
/**
 * Generates and maintains `docs/project-structure.md` and `FILE_MAP.md`
 * for `campus_mobile`, keeping side-by-side descriptions for every file and folder.
 *
 * Modes:
 *   node scripts/update_project_structure.mjs          # One-shot update
 *   node scripts/update_project_structure.mjs --watch  # Auto-update on any add/delete/rename
 *   node scripts/update_project_structure.mjs --check  # Exit 1 if docs are out of date
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const TARGETS = ['docs/project-structure.md', 'FILE_MAP.md'];

const INCLUDED_ROOT_FILES = [
  'pubspec.yaml',
  'analysis_options.yaml',
  'README.md',
  'FILE_MAP.md',
];

const INCLUDED_TOP_DIRS = [
  'lib',
  'assets',
  'test',
  'docs',
  'scripts',
  '.github',
  'android/app/src',
  'windows/runner',
  'web',
];

const IGNORED_NAMES = new Set([
  '.dart_tool',
  '.git',
  '.idea',
  '.widget_preview',
  'build',
  '.gradle',
  '.kotlin',
  'ephemeral',
  'CMakeFiles',
  'generated_plugin_registrant.cc',
  'generated_plugin_registrant.h',
  'generated_plugins.cmake',
  'GeneratedPluginRegistrant.java',
  'java',
  '.DS_Store',
  'Thumbs.db',
]);

// Curated side descriptions (POSIX relative paths)
const PATH_DESCRIPTIONS = {
  '.': 'Flutter multi-platform client root (Android APK, Windows EXE, Web)',
  'pubspec.yaml': 'Flutter dependencies, SDK constraints, and registered assets',
  'analysis_options.yaml': 'Dart static analyzer rules & lint configuration',
  'README.md': 'Architecture overview, Mermaid diagram, and setup notes',
  'flutter_export.js': 'Utility script to export essential Dart/YAML files to text',
  'FILE_MAP.md': 'Auto-synced mirror of docs/project-structure.md in project root',

  lib: 'Application Dart source root (Clean 4-Box / Feature-First layout)',
  'lib/main.dart': '✅ Entry point: Sentry init, Material 3 theme, Startup Splash & Auth gate',

  'lib/app': 'App-wide shell, navigation router, and adaptive desktop/mobile frames',
  'lib/app/router': 'App routing layer (planned go_router setup)',
  'lib/app/shells': 'Responsive top-level shells (planned MobileShell + DesktopShell)',

  'lib/core': 'Shared infrastructure used across all features',
  'lib/core/config': 'App configuration & environment values',
  'lib/core/constants': 'Global constants (API routes & UI color tokens)',
  'lib/core/constants/api_endpoints.dart': '✅ Backend base URL & auth/university API endpoint constants',
  'lib/core/constants/app_colors.dart': '🎨 Global UI color palette (primary, aurora pastels, text, status)',
  'lib/core/network': 'HTTP networking client & authentication interceptors',
  'lib/core/network/api_client.dart': '✅ Configured Dio client provider with base options & interceptor wiring',
  'lib/core/network/auth_interceptor.dart': '✅ Automatic Bearer token attach, cookie handling & 401 refresh',
  'lib/core/platform': 'Platform-specific integrations (Windows window / OS hooks)',
  'lib/core/realtime': 'Realtime services (planned Socket.IO chat & LiveKit calls)',
  'lib/core/responsive': 'Screen breakpoints & responsive AdaptiveBuilder helpers',
  'lib/core/storage': 'Local encrypted storage & persistence services',
  'lib/core/storage/secure_storage_service.dart': '✅ Encrypted token storage (Keychain / Keystore / Win Credential Vault)',
  'lib/core/theme': 'Global ThemeData, typography & dark/light theme definitions',

  'lib/shared': 'Shared cross-feature UI design system & reusable widgets',
  'lib/shared/widgets': 'Reusable UI components shared by multiple features',
  'lib/shared/widgets/northstar_logo.dart': '🎨 Custom vector Northstar logo (3D tilt, 60 sparkles, 4 animation modes)',

  'lib/features': 'Feature modules (1 self-contained folder per product domain)',
  'lib/features/auth': '✅ Complete Authentication, OTP, Password Reset, Google OAuth & University Onboarding',
  'lib/features/auth/data': 'Auth API services, data models & repository layer',
  'lib/features/auth/data/auth_repository.dart': '✅ Coordinates auth API calls with secure token persistence',
  'lib/features/auth/data/models': 'Auth request/response & user profile models',
  'lib/features/auth/data/models/auth_models.dart': '✅ Domain resolution, OTP verification & onboarding payloads',
  'lib/features/auth/data/models/user_model.dart': '✅ Authenticated campus UserModel (role, university, metadata)',
  'lib/features/auth/data/services': 'HTTP auth calls & cross-platform Google OAuth handlers',
  'lib/features/auth/data/services/auth_api_service.dart': '✅ Auth REST endpoints (login, register, OTP, reset, domain resolve)',
  'lib/features/auth/data/services/google_oauth_service.dart': '✅ Conditional export choosing IO vs Web Google OAuth implementation',
  'lib/features/auth/data/services/google_oauth_service_io.dart': '✅ Android deep-link & Windows loopback localhost Google OAuth flow',
  'lib/features/auth/data/services/google_oauth_service_stub.dart': '✅ Web browser redirect Google OAuth flow',
  'lib/features/auth/presentation': 'Auth state controllers, screens & reusable auth UI widgets',
  'lib/features/auth/presentation/controllers': 'Auth Riverpod state notifiers',
  'lib/features/auth/presentation/controllers/auth_controller.dart': '✅ Main AuthController & AuthFlowController (multi-step auth state)',
  'lib/features/auth/presentation/screens': 'Auth screens',
  'lib/features/auth/presentation/screens/login_screen.dart': '🎨 Responsive Auth screen (fixed card + Desktop showcase + flows)',
  'lib/features/auth/presentation/widgets': 'Modular Auth UI building blocks',
  'lib/features/auth/presentation/widgets/auth_form_fields.dart': '🎨 Styled inputs, primary/secondary buttons & feedback banners',
  'lib/features/auth/presentation/widgets/domain_status_banner.dart': '🎨 Live university domain / admin / student verification pill',
  'lib/features/auth/presentation/widgets/fluid_auth_backdrop.dart': '🎨 Pastel aurora gradient & frosted glass auth background',
  'lib/features/auth/presentation/widgets/forgot_password_flow.dart': '🎨 Password reset via 6-digit email OTP workflow widget',
  'lib/features/auth/presentation/widgets/google_oauth_button.dart': '🎨 Branded Continue with Google OAuth button & loading state',
  'lib/features/auth/presentation/widgets/otp_code_boxes.dart': '🎨 6-digit OTP verification input boxes with auto-focus & paste',
  'lib/features/auth/presentation/widgets/password_strength_checklist.dart': '🎨 Live password requirements checklist widget',
  'lib/features/auth/presentation/widgets/segmented_pill_switch.dart': '🎨 Smooth pill toggle (Login/Register, Password/OTP)',
  'lib/features/auth/presentation/widgets/university_onboarding_sheet.dart': '🎨 Modal sheet for admins to claim & create a university workspace',

  'lib/features/dashboard': '✅ Post-login Workspace Hub, Bottom Navigation & Starter Module Views',
  'lib/features/dashboard/presentation': 'Dashboard UI screens & widgets',
  'lib/features/dashboard/presentation/screens': 'Dashboard shell & starter module pages',
  'lib/features/dashboard/presentation/screens/dashboard_shell.dart': '🎨 AppBar, Bottom Nav (Home/Admin/Profile) & AI Copilot sheet',
  'lib/features/dashboard/presentation/screens/module_screens.dart': '🎨 Starter screens for Academics, Channels & Freelance modules',
  'lib/features/dashboard/presentation/widgets': 'Dashboard cards & navigation overlays',
  'lib/features/dashboard/presentation/widgets/capsule_card.dart': '🎨 Gradient feature launcher cards on Home Hub',
  'lib/features/dashboard/presentation/widgets/edge_switcher_overlay.dart': '🎨 Right-edge slide-out quick app switcher & Copilot trigger',

  'lib/features/academics': 'Academics domain (Timetable, Attendance, Assignments, Notes)',
  'lib/features/admin': 'Admin Console domain (Campus moderation & telemetry)',
  'lib/features/chat': 'Campus Chat domain (Channels, DMs & LiveKit calls)',
  'lib/features/copilot': 'AI Copilot domain (Academic assistant & reasoning)',
  'lib/features/freelance': 'Freelance & Escrow domain (Gigs & milestone contracts)',
  'lib/features/settings': 'Profile & app preferences domain',

  assets: 'Bundled static assets declared in pubspec.yaml',
  'assets/icons': 'App custom icon assets directory (for SVG / PNG UI icons)',
  'assets/images': 'App static image assets directory (illustrations / photos)',
  'assets/logo': 'Northstar vector SVG brand assets (static badge, mark, animated)',
  'assets/logo/northstar-logo.svg': '🖼️ Static 512x512 Northstar obsidian squircle vector SVG',
  'assets/logo/northstar-mark.svg': '🖼️ Transparent floating Northstar monogram SVG (N + orbit + star)',
  'assets/logo/northstar-logo-animated.svg': '🖼️ Exact 4.4s CSS-animated SVG with 60 sparkles & comet sweep',

  test: 'Automated Flutter unit, widget & security hardening tests',
  'test/widget_test.dart': '🧪 Smoke tests ensuring app boots & auth UI renders cleanly',
  'test/auth_flow_test.dart': '🧪 Multi-step login, OTP, onboarding & validation widget tests',
  'test/core': 'Core security & infrastructure test suites',
  'test/core/security_hardening_test.dart': '🧪 Verifies HTTPS enforcement, allowBackup=false & safe OAuth rules',

  docs: 'Repository documentation & live auto-generated project maps',
  'docs/dev': 'Developer guides (testing, local builds, workflows)',
  'docs/project-structure.md': '📘 Auto-generated live folder & file reference (this file)',

  scripts: 'Developer automation scripts & git hook installers',
  'scripts/update_project_structure.mjs': '⚙️ Auto-generates & watches docs/project-structure.md + FILE_MAP.md',
  'scripts/install_hooks.mjs': '⚙️ Installs pre-commit / post-checkout / post-merge git hooks',

  '.github': 'GitHub Actions CI/CD, build workflows, templates & labels',
  '.github/CODEOWNERS': '⚙️ Default PR code review owners',
  '.github/dependabot.yml': '⚙️ Automated dependency & workflow update checks',
  '.github/labeler.yml': '⚙️ Rules for auto-labeling PRs based on changed paths',
  '.github/actions': 'Reusable composite GitHub Actions steps',
  '.github/actions/setup-flutter': 'Composite GitHub Action to install & cache Flutter SDK',
  '.github/actions/setup-flutter/action.yml': '⚙️ Reusable Flutter setup workflow step definition',
  '.github/ISSUE_TEMPLATE': 'GitHub Bug Report & Feature Request issue templates',
  '.github/workflows': 'Automated cloud pipelines (CI, APK/EXE build, Security, Releases)',
  '.github/workflows/ci.yml': '⚙️ Runs Dart format check, flutter analyze, tests & web build on PRs',
  '.github/workflows/build-flutter.yml': '⚙️ Cloud builds Android .apk & Windows .exe release artifacts',
  '.github/workflows/label-pr.yml': '⚙️ Auto-labels PRs using .github/labeler.yml',
  '.github/workflows/security.yml': '⚙️ Gitleaks secret scan & client security hardening tests',
  '.github/workflows/release.yml': '⚙️ Creates tagged GitHub Releases with APK & EXE binaries',
  '.github/workflows/stale.yml': '⚙️ Marks & closes stale GitHub issues and PRs',
  '.github/workflows/sync-docs.yml': '⚙️ Auto-updates project structure docs on PRs if files change',

  'android/app/src': 'Android native manifests, launcher icons & security config',
  'android/app/src/debug': 'Debug build manifest overrides',
  'android/app/src/profile': 'Profile build manifest overrides',
  'android/app/src/main': 'Main Android application source & resources',
  'android/app/src/main/java': 'Generated Flutter Android Java plugin bridge root',
  'android/app/src/main/kotlin': 'Native Android Kotlin application entry point',
  'android/app/src/main/kotlin/in/edu/iiitnr/campus_mobile/MainActivity.kt': '📱 Main Android Activity hosting the Flutter engine',
  'android/app/src/main/res': 'Android XML resources, splash drawables & launcher icons',
  'android/app/src/main/res/drawable': 'Android default launch splash drawable',
  'android/app/src/main/res/drawable/launch_background.xml': '📱 Android pre-v21 launch splash background XML',
  'android/app/src/main/res/drawable-v21': 'Android API 21+ launch splash drawable',
  'android/app/src/main/res/drawable-v21/launch_background.xml': '📱 Android API 21+ launch splash background XML',
  'android/app/src/main/res/values': 'Light mode Android theme styles',
  'android/app/src/main/res/values/styles.xml': '📱 Android light LaunchTheme & NormalTheme styles',
  'android/app/src/main/res/values-night': 'Dark mode Android theme styles',
  'android/app/src/main/res/values-night/styles.xml': '📱 Android dark LaunchTheme & NormalTheme styles',
  'android/app/src/main/res/xml': 'Android XML security policies',
  'android/app/src/main/AndroidManifest.xml': '📱 Android permissions, deep links (northstar://auth) & app metadata',
  'android/app/src/main/res/xml/network_security_config.xml': '🔒 Enforces HTTPS globally (loopback allowed only for local OAuth)',

  'windows/runner': 'Windows native Win32 runner, window config & taskbar icon',
  'windows/runner/resources': 'Windows native runner icon & bitmap resources',
  'windows/runner/resources/app_icon.ico': '🖼️ Multi-size Windows .exe desktop & taskbar icon',
  'windows/runner/CMakeLists.txt': '⚙️ CMake build definition for Windows desktop runner',
  'windows/runner/runner.exe.manifest': '🪟 Windows DPI-awareness & OS compatibility manifest',
  'windows/runner/Runner.rc': '🪟 Windows version info & app_icon.ico resource script',

  web: 'Flutter Web & PWA entry HTML, manifest & browser/home-screen icons',
  'web/index.html': '🌐 Flutter Web host page',
  'web/manifest.json': '🌐 Web App / PWA metadata & icon declarations',
  'web/favicon.png': '🖼️ Browser tab favicon',
  'web/icons': '🖼️ PWA & maskable launcher icons (192px & 512px)',
};

function toPosix(relPath) {
  return relPath.split(path.sep).join('/');
}

function isPlaceholderDir(absDir) {
  let entries;
  try {
    entries = fs.readdirSync(absDir, { withFileTypes: true });
  } catch {
    return false;
  }
  const visible = entries.filter((e) => !IGNORED_NAMES.has(e.name));
  return visible.length === 1 && visible[0].isFile() && visible[0].name === '.gitkeep';
}

function inferMarkdownHeading(absPath) {
  try {
    const lines = fs.readFileSync(absPath, 'utf8').split(/\r?\n/, 20);
    for (const line of lines) {
      const m = line.match(/^#\s+(.+)/);
      if (m) return `📘 Doc: ${m[1].trim()}`;
    }
  } catch {}
  return '📘 Documentation file';
}

function inferWorkflowName(absPath) {
  try {
    const lines = fs.readFileSync(absPath, 'utf8').split(/\r?\n/, 15);
    for (const line of lines) {
      const m = line.match(/^name:\s*(.+)/i);
      if (m) return `⚙️ GitHub workflow: ${m[1].trim().replace(/^['"]|['"]$/g, '')}`;
    }
  } catch {}
  return '⚙️ GitHub Actions workflow';
}

function inferDartDescription(absPath, relPosix) {
  const fileName = path.basename(absPath);
  let docComment = '';
  let primarySymbol = '';
  let isWidget = false;

  try {
    const lines = fs.readFileSync(absPath, 'utf8').split(/\r?\n/, 40);
    for (const line of lines) {
      const docMatch = line.match(/^\s*\/\/\/\s*(.+)/);
      if (docMatch && !docComment) {
        docComment = docMatch[1].trim();
      }
      const classMatch = line.match(/^\s*(?:abstract\s+)?(?:class|enum|mixin)\s+([A-Za-z0-9_]+)/);
      if (classMatch && !primarySymbol) {
        primarySymbol = classMatch[1];
      }
      if (/extends\s+(?:Consumer)?(?:Stateful|Stateless)Widget\b/.test(line)) {
        isWidget = true;
      }
    }
  } catch {}

  if (docComment) {
    const prefix = isWidget || relPosix.includes('/presentation/screens/') || relPosix.includes('/presentation/widgets/')
      ? '🎨 '
      : relPosix.startsWith('test/')
        ? '🧪 '
        : '✅ ';
    return `${prefix}${docComment}`;
  }

  const label = primarySymbol ? ` (${primarySymbol})` : '';
  if (relPosix.startsWith('test/') || fileName.endsWith('_test.dart')) {
    return `🧪 Automated tests${label}`;
  }
  if (fileName.endsWith('_screen.dart') || relPosix.includes('/screens/')) {
    return `🎨 UI screen${label}`;
  }
  if (fileName.endsWith('_widget.dart') || relPosix.includes('/widgets/')) {
    return `🎨 UI widget${label}`;
  }
  if (fileName.endsWith('_controller.dart') || fileName.endsWith('_provider.dart')) {
    return `✅ State controller${label}`;
  }
  if (fileName.endsWith('_repository.dart') || relPosix.includes('/repositories/')) {
    return `✅ Data repository${label}`;
  }
  if (fileName.endsWith('_service.dart') || relPosix.includes('/services/')) {
    return `✅ External/platform service${label}`;
  }
  if (fileName.endsWith('_model.dart') || fileName.endsWith('_models.dart') || relPosix.includes('/models/')) {
    return `✅ Data model${label}`;
  }
  return `${isWidget ? '🎨 Flutter widget' : '✅ Dart module'}${label}`;
}

function inferDirDescription(absDir, relPosix) {
  if (PATH_DESCRIPTIONS[relPosix]) {
    if (isPlaceholderDir(absDir)) {
      return `⬜ Empty scaffold (.gitkeep) — ${PATH_DESCRIPTIONS[relPosix]}`;
    }
    return PATH_DESCRIPTIONS[relPosix];
  }
  if (isPlaceholderDir(absDir)) {
    const base = path.basename(absDir);
    return `⬜ Empty scaffold (.gitkeep) — ready for ${base} code`;
  }
  const base = path.basename(absDir);
  if (base === 'screens') return '🎨 Screen UI pages';
  if (base === 'widgets') return '🎨 Reusable UI widgets';
  if (base === 'controllers') return 'Riverpod / state controllers';
  if (base === 'models') return 'Domain data models';
  if (base === 'repositories') return 'Repositories (cache + API mediation)';
  if (base === 'services') return 'API & native platform services';
  if (base === 'data') return 'Data layer (models, services, repositories)';
  if (base === 'presentation') return 'UI layer (controllers, screens, widgets)';
  if (base.startsWith('mipmap-')) return '🖼️ Android launcher icon density asset';
  return 'Directory';
}

function describeEntry(absPath, relPosix, isDir) {
  if (isDir) {
    return inferDirDescription(absPath, relPosix);
  }
  if (PATH_DESCRIPTIONS[relPosix]) {
    return PATH_DESCRIPTIONS[relPosix];
  }
  const name = path.basename(absPath);
  if (name === '.gitkeep') return '⬜ Scaffold keepalive placeholder (auto-removes when real code is added)';
  if (name.endsWith('.dart')) return inferDartDescription(absPath, relPosix);
  if (name.endsWith('.md')) return inferMarkdownHeading(absPath);
  if (name.endsWith('.yml') || name.endsWith('.yaml')) {
    return relPosix.includes('.github/workflows/')
      ? inferWorkflowName(absPath)
      : '⚙️ YAML configuration';
  }
  if (/\.(png|jpg|jpeg|svg|ico|webp)$/i.test(name)) return '🖼️ Image / icon asset';
  if (/\.(js|mjs|cjs|ts)$/i.test(name)) return '⚙️ Tooling / helper script';
  if (/\.(cpp|h|cc|rc)$/i.test(name)) return '🪟 Native Windows C++ runner source';
  if (name.endsWith('.xml')) return '📱 Android XML resource / configuration';
  if (name.endsWith('.json')) return '⚙️ JSON configuration';
  return 'Project file';
}

function collectTreeLines(absDir, relPosix, prefix, rows) {
  let entries;
  try {
    entries = fs.readdirSync(absDir, { withFileTypes: true });
  } catch {
    return;
  }

  const filtered = entries.filter((e) => !IGNORED_NAMES.has(e.name));
  // Hide `.gitkeep` when real files sit alongside it; keep showing folder state cleanly
  const hasRealContent = filtered.some((e) => e.name !== '.gitkeep');
  const visible = hasRealContent
    ? filtered.filter((e) => e.name !== '.gitkeep')
    : filtered;

  visible.sort((a, b) => {
    if (a.isDirectory() && !b.isDirectory()) return -1;
    if (!a.isDirectory() && b.isDirectory()) return 1;
    return a.name.localeCompare(b.name);
  });

  visible.forEach((entry, index) => {
    const isLast = index === visible.length - 1;
    const connector = isLast ? '└── ' : '├── ';
    const nextPrefix = prefix + (isLast ? '    ' : '│   ');
    const childAbs = path.join(absDir, entry.name);
    const childRel = relPosix === '.' ? entry.name : `${relPosix}/${entry.name}`;
    const isDir = entry.isDirectory();

    const label = `${prefix}${connector}${entry.name}${isDir ? '/' : ''}`;
    const desc = describeEntry(childAbs, childRel, isDir);
    rows.push({ label, desc, isDir, rel: childRel });

    if (isDir && !isPlaceholderDir(childAbs)) {
      collectTreeLines(childAbs, childRel, nextPrefix, rows);
    }
  });
}

function buildTreeRows() {
  const rows = [
    {
      label: 'campus_mobile/',
      desc: PATH_DESCRIPTIONS['.'],
      isDir: true,
      rel: '.',
    },
  ];

  const topEntries = [];

  for (const name of INCLUDED_ROOT_FILES) {
    const abs = path.join(ROOT, name);
    if (fs.existsSync(abs)) {
      topEntries.push({ name, abs, rel: name, isDir: false });
    }
  }

  for (const dirRel of INCLUDED_TOP_DIRS) {
    const abs = path.join(ROOT, dirRel);
    if (fs.existsSync(abs)) {
      topEntries.push({ name: dirRel, abs, rel: dirRel, isDir: true });
    }
  }

  topEntries.forEach((item, idx) => {
    const isLast = idx === topEntries.length - 1;
    const connector = isLast ? '└── ' : '├── ';
    const nextPrefix = isLast ? '    ' : '│   ';
    const label = `${connector}${item.name}${item.isDir ? '/' : ''}`;
    const desc = describeEntry(item.abs, item.rel, item.isDir);
    rows.push({ label, desc, isDir: item.isDir, rel: item.rel });

    if (item.isDir && !isPlaceholderDir(item.abs)) {
      collectTreeLines(item.abs, item.rel, nextPrefix, rows);
    }
  });

  return rows;
}

function renderMarkdown(linkPrefix = '../') {
  const rows = buildTreeRows();
  const padWidth = 60;

  const treeText = rows
    .map((r) => `${(r.label.length >= padWidth ? `${r.label}  ` : r.label.padEnd(padWidth))} # ${r.desc}`)
    .join('\n');

  const activeDartCount = rows.filter((r) => !r.isDir && r.rel.startsWith('lib/') && r.rel.endsWith('.dart')).length;
  const emptyScaffoldCount = rows.filter((r) => r.desc.startsWith('⬜')).length;

  return `# \`campus_mobile\` Project Structure & File Map

> **Auto-maintained by [\`scripts/update_project_structure.mjs\`](${linkPrefix}scripts/update_project_structure.mjs)** (synced between \`docs/project-structure.md\` & \`FILE_MAP.md\`).  
> Automatically updates whenever folders/files are added, renamed, or deleted via:
> 1. **Live IDE Watcher** — \`node scripts/update_project_structure.mjs --watch\` (auto-starts via \`.vscode/tasks.json\`)
> 2. **Git Hooks** — runs automatically before every \`git commit\`, checkout, or merge (\`node scripts/install_hooks.mjs\`)
> 3. **GitHub Actions** — [\`sync-docs.yml\`](${linkPrefix}.github/workflows/sync-docs.yml) updates PRs automatically if structure changes remotely

**Status Legend:** \`✅\` Active logic · \`🎨\` UI / screens / widgets / theme · \`⬜\` Empty scaffold (\`.gitkeep\`) · \`🧪\` Tests · \`⚙️\` Tooling / CI · \`🖼️\` Icons & graphics

- **Active Dart source files under \`lib/\`:** ${activeDartCount}
- **Empty scaffold folders ready to build (\`.gitkeep\`):** ${emptyScaffoldCount}

---

## Live Folder & File Tree (with Side Descriptions)

\`\`\`text
${treeText}
\`\`\`

---

## Quick UI Editing Guide (Where to Change What)

| UI Area | File to Edit | What It Controls |
| :--- | :--- | :--- |
| **Colors & Palette** | [\`lib/core/constants/app_colors.dart\`](${linkPrefix}lib/core/constants/app_colors.dart) | Primary blue, aurora pastel gradients, text, border & status colors |
| **App Theme & Splash** | [\`lib/main.dart\`](${linkPrefix}lib/main.dart) | Material 3 theme, \`Inter\` font & branded startup splash loader |
| **Brand Logo & Animations** | [\`lib/shared/widgets/northstar_logo.dart\`](${linkPrefix}lib/shared/widgets/northstar_logo.dart) | Obsidian squircle, 3D tilt, 60 sparkles & 4 animation modes |
| **Login, OTP & Register** | [\`lib/features/auth/presentation/screens/login_screen.dart\`](${linkPrefix}lib/features/auth/presentation/screens/login_screen.dart) | Responsive mobile auth card & wide desktop showcase panel |
| **Auth Reusable Widgets** | \`lib/features/auth/presentation/widgets/*.dart\` | Pastel backdrop, OTP boxes, password checklist, OAuth button, Org sheet |
| **Home Hub & Bottom Nav** | [\`lib/features/dashboard/presentation/screens/dashboard_shell.dart\`](${linkPrefix}lib/features/dashboard/presentation/screens/dashboard_shell.dart) | Top AppBar, Home / Admin / Profile tabs & AI Copilot sheet |
| **Feature Cards & Switcher** | \`lib/features/dashboard/presentation/widgets/*.dart\` | \`CapsuleCard\` gradients & slide-out \`EdgeSwitcherOverlay\` |
| **Module Screens** | [\`lib/features/dashboard/presentation/screens/module_screens.dart\`](${linkPrefix}lib/features/dashboard/presentation/screens/module_screens.dart) | Starter UIs for Academics, Channels & Freelance |
| **App / Taskbar Icons** | \`android/app/src/main/res/mipmap-*/\`, \`windows/runner/resources/\`, \`web/icons/\` | Static launcher icons installed on Android, Windows & Web |
`;
}

const TARGET_SPECS = [
  { rel: 'docs/project-structure.md', prefix: '../' },
  { rel: 'FILE_MAP.md', prefix: './' },
];

function writeDocs({ silent = false } = {}) {
  let updated = 0;

  for (const { rel, prefix } of TARGET_SPECS) {
    const markdown = renderMarkdown(prefix);
    const absTarget = path.join(ROOT, rel);
    fs.mkdirSync(path.dirname(absTarget), { recursive: true });
    const prev = fs.existsSync(absTarget)
      ? fs.readFileSync(absTarget, 'utf8').replace(/\r\n/g, '\n')
      : '';
    if (prev !== markdown) {
      fs.writeFileSync(absTarget, markdown, 'utf8');
      updated++;
      if (!silent) {
        console.log(`Updated ${rel}`);
      }
    }
  }

  return updated;
}

function checkDocs() {
  let stale = false;
  for (const { rel, prefix } of TARGET_SPECS) {
    const markdown = renderMarkdown(prefix);
    const absTarget = path.join(ROOT, rel);
    const prev = fs.existsSync(absTarget)
      ? fs.readFileSync(absTarget, 'utf8').replace(/\r\n/g, '\n')
      : '';
    if (prev !== markdown) {
      console.error(`Out of date: ${rel}`);
      stale = true;
    }
  }
  if (stale) {
    console.error('Run: node scripts/update_project_structure.mjs');
    process.exit(1);
  }
  console.log('Project structure docs are up to date.');
}

function watchDocs() {
  writeDocs();
  console.log('Watching campus_mobile for folder/file additions, renames, or deletions...');

  const watchRoots = [
    'lib',
    'assets',
    'test',
    'docs',
    'scripts',
    '.github',
    'android/app/src',
    'windows/runner',
    'web',
  ];

  let timer = null;
  const scheduleRebuild = (changedRel) => {
    if (!changedRel) return;
    const norm = toPosix(String(changedRel));
    if (
      norm === 'docs/project-structure.md' ||
      norm === 'FILE_MAP.md' ||
      norm.includes('build/') ||
      norm.includes('.dart_tool/')
    ) {
      return;
    }
    clearTimeout(timer);
    timer = setTimeout(() => {
      try {
        const count = writeDocs({ silent: false });
        if (count > 0) {
          console.log(`[${new Date().toLocaleTimeString()}] Synced project structure after change in "${norm}"`);
        }
      } catch (err) {
        console.error('Watcher rebuild error:', err);
      }
    }, 350);
  };

  for (const rel of watchRoots) {
    const abs = path.join(ROOT, rel);
    if (!fs.existsSync(abs)) continue;
    try {
      fs.watch(abs, { recursive: true }, (_eventType, filename) => {
        scheduleRebuild(filename ? `${rel}/${filename}` : rel);
      });
    } catch {
      // Fallback for platforms without recursive fs.watch support
      fs.watch(abs, (_eventType, filename) => {
        scheduleRebuild(filename ? `${rel}/${filename}` : rel);
      });
    }
  }

  for (const rootFile of INCLUDED_ROOT_FILES) {
    const abs = path.join(ROOT, rootFile);
    if (!fs.existsSync(abs)) continue;
    fs.watch(abs, () => scheduleRebuild(rootFile));
  }
}

const args = new Set(process.argv.slice(2));
if (args.has('--watch')) {
  watchDocs();
} else if (args.has('--check')) {
  checkDocs();
} else {
  const count = writeDocs();
  if (count === 0) {
    console.log('Project structure docs already up to date.');
  }
}
