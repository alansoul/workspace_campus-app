#!/usr/bin/env node
/**
 * Generates a compact, filtered `docs/project-structure.md` (mirrored to `FILE_MAP.md`)
 * for `campus_mobile` showing ONLY useful/active code files, side descriptions,
 * and recently created / edited files — hiding OS boilerplate and empty `.gitkeep` noise.
 *
 * Modes:
 *   node scripts/update_project_structure.mjs          # One-shot update
 *   node scripts/update_project_structure.mjs --watch  # Auto-update live on file/folder changes
 *   node scripts/update_project_structure.mjs --check  # Exit 1 if docs are out of date
 */

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');

const INCLUDED_ROOT_FILES = ['pubspec.yaml', 'analysis_options.yaml', 'README.md'];

// Only key useful top-level areas (skips verbose Android C++/mipmap & Windows Win32 C++ boilerplate)
const FILTERED_TREE_DIRS = ['lib', 'assets/logo', 'test', 'docs', 'scripts', '.github/workflows'];

// Selected single key native/config files worth knowing without dumping entire native folders
const KEY_NATIVE_FILES = [
  'android/app/src/main/AndroidManifest.xml',
  'android/app/src/main/res/xml/network_security_config.xml',
  'windows/runner/resources/app_icon.ico',
  'web/manifest.json',
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
  '.DS_Store',
  'Thumbs.db',
  'project-structure.md',
  'FILE_MAP.md',
]);

// Curated side descriptions (POSIX relative paths)
const PATH_DESCRIPTIONS = {
  '.': 'Flutter multi-platform app (Android APK, Windows EXE, Web)',
  'pubspec.yaml': 'Dependencies, SDK version & bundled asset paths',
  'analysis_options.yaml': 'Dart static analyzer & lint rules',
  'README.md': 'Architecture diagram & setup guide',

  lib: 'Your main Dart & Flutter app code',
  'lib/main.dart': '✅ App entry: Sentry setup, Material 3 theme, Splash & Auth gate',

  'lib/core': 'Shared app-wide foundations',
  'lib/core/constants': 'API URLs & global UI color palette',
  'lib/core/constants/api_endpoints.dart': '✅ Backend base URL & auth/university API routes',
  'lib/core/constants/app_colors.dart': '🎨 Global UI colors (primary, aurora pastels, text, borders)',
  'lib/core/network': 'HTTP client & auth token interceptor',
  'lib/core/network/api_client.dart': '✅ Configured Dio client provider',
  'lib/core/network/auth_interceptor.dart': '✅ Auto Bearer token attach, cookies & 401 refresh',
  'lib/core/storage': 'Encrypted local storage',
  'lib/core/storage/secure_storage_service.dart': '✅ Secure JWT token persistence (Keystore / Credential Vault)',

  'lib/shared': 'Shared UI components used across screens',
  'lib/shared/widgets': 'Reusable UI widgets',
  'lib/shared/widgets/northstar_logo.dart': '🎨 Custom vector Northstar logo (3D tilt, 60 sparkles, 4 modes)',

  'lib/features': 'Feature modules (active code only; empty scaffolds summarized below)',
  'lib/features/auth': '✅ Login, Register, OTP, Password Reset, Google OAuth & Org Onboarding',
  'lib/features/auth/data': 'Auth API calls, models & token repository',
  'lib/features/auth/data/auth_repository.dart': '✅ Connects Auth API endpoints to secure storage',
  'lib/features/auth/data/models': 'Auth & user data models',
  'lib/features/auth/data/models/auth_models.dart': '✅ Domain resolution, OTP & onboarding payloads',
  'lib/features/auth/data/models/user_model.dart': '✅ Campus UserModel (role, university, profile)',
  'lib/features/auth/data/services': 'REST auth service & platform-safe Google OAuth',
  'lib/features/auth/data/services/auth_api_service.dart': '✅ Login, register, OTP, password reset & domain check calls',
  'lib/features/auth/data/services/google_oauth_service.dart': '✅ Cross-platform Google OAuth entry export',
  'lib/features/auth/data/services/google_oauth_service_io.dart': '✅ Android deep-link & Windows loopback Google OAuth',
  'lib/features/auth/data/services/google_oauth_service_stub.dart': '✅ Flutter Web redirect Google OAuth',
  'lib/features/auth/presentation': 'Auth controllers, screen & UI widgets',
  'lib/features/auth/presentation/controllers': 'Riverpod auth state management',
  'lib/features/auth/presentation/controllers/auth_controller.dart': '✅ Multi-step AuthController & AuthFlowController',
  'lib/features/auth/presentation/screens': 'Auth screens',
  'lib/features/auth/presentation/screens/login_screen.dart': '🎨 Main Auth card, OTP/Reset views & Desktop split showcase',
  'lib/features/auth/presentation/widgets': 'Auth UI components',
  'lib/features/auth/presentation/widgets/auth_form_fields.dart': '🎨 Inputs, buttons & error/info banners',
  'lib/features/auth/presentation/widgets/domain_status_banner.dart': '🎨 University verified / admin badge banner',
  'lib/features/auth/presentation/widgets/fluid_auth_backdrop.dart': '🎨 Aurora pastel frosted glass background',
  'lib/features/auth/presentation/widgets/forgot_password_flow.dart': '🎨 Email OTP password reset widget',
  'lib/features/auth/presentation/widgets/google_oauth_button.dart': '🎨 Branded Google Sign-In button',
  'lib/features/auth/presentation/widgets/otp_code_boxes.dart': '🎨 6-digit OTP boxes with paste & auto-advance',
  'lib/features/auth/presentation/widgets/password_strength_checklist.dart': '🎨 Password strength checklist',
  'lib/features/auth/presentation/widgets/segmented_pill_switch.dart': '🎨 Login/Register & Password/OTP pill toggle',
  'lib/features/auth/presentation/widgets/university_onboarding_sheet.dart': '🎨 Admin onboarding bottom sheet to create an org',

  'lib/features/dashboard': '✅ Post-login Home Hub, Bottom Nav, Cards & Starter Modules',
  'lib/features/dashboard/presentation': 'Dashboard screens & cards',
  'lib/features/dashboard/presentation/screens': 'Dashboard pages',
  'lib/features/dashboard/presentation/screens/dashboard_shell.dart': '🎨 Top AppBar, Home/Admin/Profile tabs & Copilot sheet',
  'lib/features/dashboard/presentation/screens/module_screens.dart': '🎨 Starter screens for Academics, Channels & Freelance',
  'lib/features/dashboard/presentation/widgets': 'Dashboard cards & overlays',
  'lib/features/dashboard/presentation/widgets/capsule_card.dart': '🎨 Feature launcher gradient cards',
  'lib/features/dashboard/presentation/widgets/edge_switcher_overlay.dart': '🎨 Right-edge slide-out quick app switcher',

  'assets/logo': '🖼️ Northstar vector SVG logo files (static, mark & 4.4s animated)',
  'assets/logo/northstar-logo.svg': '🖼️ Static 512x512 Northstar obsidian squircle SVG',
  'assets/logo/northstar-mark.svg': '🖼️ Transparent floating Northstar mark SVG',
  'assets/logo/northstar-logo-animated.svg': '🖼️ Exact 4.4s CSS-animated SVG (60 sparkles + comet)',

  test: '🧪 Automated tests (smoke, auth UI, security hardening)',
  'test/widget_test.dart': '🧪 App boot & login screen smoke tests',
  'test/auth_flow_test.dart': '🧪 Auth flow, OTP & onboarding widget tests',
  'test/core': 'Core security tests',
  'test/core/security_hardening_test.dart': '🧪 Enforces HTTPS config, allowBackup=false & safe OAuth',

  docs: '📘 Guides & this auto-filtered structure map',
  'docs/dev': 'Developer guides',
  'docs/dev/testing-guide.md': '📘 Testing & APK/EXE cloud build guide',

  scripts: '⚙️ Automation scripts',
  'scripts/update_project_structure.mjs': '⚙️ Auto-updates & watches this filtered project map',
  'scripts/install_hooks.mjs': '⚙️ Installs pre-commit / post-checkout / post-merge git hooks',

  '.github/workflows': '⚙️ Cloud CI, security & APK/EXE build pipelines',
  '.github/workflows/ci.yml': '⚙️ PR validation (analyze, test, web build)',
  '.github/workflows/build-flutter.yml': '⚙️ Cloud build Android .apk & Windows .exe',
  '.github/workflows/security.yml': '⚙️ Secret scan & client security hardening checks',
  '.github/workflows/release.yml': '⚙️ GitHub Release binaries on tags',
  '.github/workflows/sync-docs.yml': '⚙️ Auto-updates this doc on PRs if files change',
  '.github/workflows/label-pr.yml': '⚙️ Auto-labels PRs',
  '.github/workflows/stale.yml': '⚙️ Closes stale issues/PRs',

  'android/app/src/main/AndroidManifest.xml': '📱 Android permissions, deep links & app name',
  'android/app/src/main/res/xml/network_security_config.xml': '🔒 Forces HTTPS (loopback allowed for OAuth)',
  'windows/runner/resources/app_icon.ico': '🖼️ Windows desktop app & taskbar icon',
  'web/manifest.json': '🌐 Flutter Web / PWA app icon & name config',
};

function runGit(args) {
  try {
    return execFileSync('git', args, { cwd: ROOT, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
  } catch {
    return '';
  }
}

/**
 * Returns a Map<posixRelPath, 'New' | 'Edited'> prioritizing live uncommitted changes,
 * followed by recently created/edited files in the last 5 non-doc commits.
 */
function getRecentActivityMap() {
  const activity = new Map();
  const skipFiles = new Set([
    'docs/project-structure.md',
    'FILE_MAP.md',
    'windows/flutter/generated_plugin_registrant.cc',
    'windows/flutter/generated_plugins.cmake',
  ]);

  // 1. Live uncommitted/staged changes take top priority
  let hasStagedNonDoc = false;
  const staged = runGit(['diff', '--cached', '--name-only']);
  if (staged) {
    for (const rel of staged.split(/\r?\n/)) {
      if (rel && !skipFiles.has(rel) && !rel.endsWith('.gitkeep')) {
        hasStagedNonDoc = true;
        break;
      }
    }
  }

  const porcelain = runGit(['status', '--porcelain']);
  if (porcelain) {
    for (const rawLine of porcelain.split(/\r?\n/)) {
      if (!rawLine || rawLine.length < 4) continue;
      const code = rawLine.slice(0, 2);
      const rel = rawLine.slice(3).replace(/^"|"$/g, '').split(' -> ').pop();
      if (!rel || skipFiles.has(rel) || rel.endsWith('.gitkeep')) continue;
      const tag = code.includes('?') || code.includes('A') ? 'New' : 'Edited';
      activity.set(rel, tag);
    }
  }

  // 2. Recent commits (matches pre-commit + post-commit 1:1 on CI)
  const commitDepth = hasStagedNonDoc ? '4' : '5';
  const logOut = runGit(['log', '-n', commitDepth, '--no-merges', '--name-status', '--pretty=format:']);
  if (logOut) {
    for (const rawLine of logOut.split(/\r?\n/)) {
      const m = rawLine.match(/^([AMDTR])\d*\t([^\t]+)(?:\t([^\t]+))?/);
      if (!m) continue;
      const status = m[1];
      const rel = m[3] || m[2];
      if (!rel || skipFiles.has(rel) || rel.endsWith('.gitkeep')) continue;
      if (status === 'D') continue;
      if (!activity.has(rel)) {
        activity.set(rel, status === 'A' ? 'New' : 'Edited');
      }
    }
  }

  return activity;
}

function isUsefulFile(name) {
  if (IGNORED_NAMES.has(name) || name === '.gitkeep') return false;
  return true;
}

/** Recursively checks whether a directory has at least one real (non-.gitkeep) useful file. */
function hasActiveContent(absDir) {
  let entries;
  try {
    entries = fs.readdirSync(absDir, { withFileTypes: true });
  } catch {
    return false;
  }
  for (const entry of entries) {
    if (IGNORED_NAMES.has(entry.name) || entry.name === '.gitkeep') continue;
    const child = path.join(absDir, entry.name);
    if (entry.isFile()) return true;
    if (entry.isDirectory() && hasActiveContent(child)) return true;
  }
  return false;
}

function collectEmptyScaffoldNames(absDir, relPosix, outList) {
  let entries;
  try {
    entries = fs.readdirSync(absDir, { withFileTypes: true });
  } catch {
    return;
  }
  const hasReal = hasActiveContent(absDir);
  if (!hasReal) {
    outList.push(relPosix);
    return;
  }
  for (const entry of entries.sort((a, b) => a.name.localeCompare(b.name))) {
    if (!entry.isDirectory() || IGNORED_NAMES.has(entry.name)) continue;
    collectEmptyScaffoldNames(path.join(absDir, entry.name), `${relPosix}/${entry.name}`, outList);
  }
}

function inferDescription(absPath, relPosix, isDir) {
  if (PATH_DESCRIPTIONS[relPosix]) return PATH_DESCRIPTIONS[relPosix];
  const name = path.basename(absPath);

  if (isDir) {
    if (name === 'screens') return '🎨 Screen UI pages';
    if (name === 'widgets') return '🎨 Reusable UI widgets';
    if (name === 'controllers') return 'Riverpod state controllers';
    if (name === 'models') return 'Data models';
    if (name === 'repositories') return 'Data repositories (API + cache)';
    if (name === 'services') return 'API & platform services';
    if (name === 'data') return 'Data layer';
    if (name === 'presentation') return 'UI presentation layer';
    return 'Feature module folder';
  }

  if (name.endsWith('.dart')) {
    let docComment = '';
    let symbol = '';
    let isWidget = false;
    try {
      const lines = fs.readFileSync(absPath, 'utf8').split(/\r?\n/, 40);
      for (const line of lines) {
        const dm = line.match(/^\s*\/\/\/\s*(.+)/);
        if (dm && !docComment) docComment = dm[1].trim();
        const cm = line.match(/^\s*(?:abstract\s+)?(?:class|enum|mixin)\s+([A-Za-z0-9_]+)/);
        if (cm && !symbol) symbol = cm[1];
        if (/extends\s+(?:Consumer)?(?:Stateful|Stateless)Widget\b/.test(line)) isWidget = true;
      }
    } catch {}
    if (docComment) {
      const icon = isWidget || relPosix.includes('/screens/') || relPosix.includes('/widgets/') ? '🎨' : relPosix.startsWith('test/') ? '🧪' : '✅';
      return `${icon} ${docComment}`;
    }
    const sym = symbol ? ` (${symbol})` : '';
    if (relPosix.startsWith('test/') || name.endsWith('_test.dart')) return `🧪 Tests${sym}`;
    if (name.endsWith('_screen.dart') || relPosix.includes('/screens/')) return `🎨 Screen UI${sym}`;
    if (name.endsWith('_widget.dart') || relPosix.includes('/widgets/')) return `🎨 UI widget${sym}`;
    if (name.endsWith('_controller.dart') || name.endsWith('_provider.dart')) return `✅ State controller${sym}`;
    if (name.endsWith('_repository.dart')) return `✅ Repository${sym}`;
    if (name.endsWith('_service.dart')) return `✅ Service${sym}`;
    if (name.endsWith('_model.dart') || name.endsWith('_models.dart')) return `✅ Model${sym}`;
    return `${isWidget ? '🎨 Widget' : '✅ Dart module'}${sym}`;
  }

  if (name.endsWith('.md')) {
    try {
      const m = fs.readFileSync(absPath, 'utf8').match(/^#\s+(.+)/m);
      if (m) return `📘 Doc: ${m[1].trim()}`;
    } catch {}
    return '📘 Documentation';
  }

  if (name.endsWith('.yml') || name.endsWith('.yaml')) {
    try {
      const m = fs.readFileSync(absPath, 'utf8').match(/^name:\s*(.+)/im);
      if (m) return `⚙️ Workflow: ${m[1].trim().replace(/^['"]|['"]$/g, '')}`;
    } catch {}
    return '⚙️ YAML config';
  }

  if (/\.(svg|png|ico|jpg|jpeg|webp)$/i.test(name)) return '🖼️ Brand / icon asset';
  if (/\.(js|mjs|ts)$/i.test(name)) return '⚙️ Automation script';
  return 'Project file';
}

function collectFilteredTree(absDir, relPosix, prefix, rows, activityMap) {
  let entries;
  try {
    entries = fs.readdirSync(absDir, { withFileTypes: true });
  } catch {
    return;
  }

  const visible = entries.filter((entry) => {
    const childAbs = path.join(absDir, entry.name);
    if (entry.isDirectory()) return !IGNORED_NAMES.has(entry.name) && hasActiveContent(childAbs);
    return isUsefulFile(entry.name);
  });

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
    const childRel = `${relPosix}/${entry.name}`;
    const isDir = entry.isDirectory();

    const tag = !isDir && activityMap.has(childRel) ? ` [${activityMap.get(childRel)}]` : '';
    const label = `${prefix}${connector}${entry.name}${isDir ? '/' : ''}`;
    const desc = `${inferDescription(childAbs, childRel, isDir)}${tag}`;
    rows.push({ label, desc, isDir, rel: childRel });

    if (isDir) {
      collectFilteredTree(childAbs, childRel, nextPrefix, rows, activityMap);
    }
  });
}

function buildFilteredRows(activityMap) {
  const rows = [
    { label: 'campus_mobile/', desc: PATH_DESCRIPTIONS['.'], isDir: true, rel: '.' },
  ];

  const topItems = [];
  for (const name of INCLUDED_ROOT_FILES) {
    const abs = path.join(ROOT, name);
    if (fs.existsSync(abs)) topItems.push({ labelName: name, abs, rel: name, isDir: false });
  }
  for (const dirRel of FILTERED_TREE_DIRS) {
    const abs = path.join(ROOT, dirRel);
    if (fs.existsSync(abs) && hasActiveContent(abs)) {
      topItems.push({ labelName: dirRel, abs, rel: dirRel, isDir: true });
    }
  }
  for (const nativeRel of KEY_NATIVE_FILES) {
    const abs = path.join(ROOT, nativeRel);
    if (fs.existsSync(abs)) topItems.push({ labelName: nativeRel, abs, rel: nativeRel, isDir: false });
  }

  topItems.forEach((item, idx) => {
    const isLast = idx === topItems.length - 1;
    const connector = isLast ? '└── ' : '├── ';
    const nextPrefix = isLast ? '    ' : '│   ';
    const tag = !item.isDir && activityMap.has(item.rel) ? ` [${activityMap.get(item.rel)}]` : '';
    const label = `${connector}${item.labelName}${item.isDir ? '/' : ''}`;
    const desc = `${inferDescription(item.abs, item.rel, item.isDir)}${tag}`;
    rows.push({ label, desc, isDir: item.isDir, rel: item.rel });

    if (item.isDir) {
      collectFilteredTree(item.abs, item.rel, nextPrefix, rows, activityMap);
    }
  });

  return rows;
}

function renderMarkdown(linkPrefix = '../') {
  const activityMap = getRecentActivityMap();
  const rows = buildFilteredRows(activityMap);
  const padWidth = 54;

  const treeText = rows
    .map((r) => `${r.label.length >= padWidth ? `${r.label}  ` : r.label.padEnd(padWidth)} # ${r.desc}`)
    .join('\n');

  const emptyDirs = [];
  collectEmptyScaffoldNames(path.join(ROOT, 'lib'), 'lib', emptyDirs);
  const emptySummary = emptyDirs
    .map((d) => d.replace(/^lib\//, ''))
    .join(', ');

  const recentEntries = [];
  for (const [rel, tag] of activityMap.entries()) {
    const abs = path.join(ROOT, rel);
    if (!fs.existsSync(abs)) continue;
    const desc = inferDescription(abs, rel, false);
    recentEntries.push(`| \`${tag === 'New' ? '🆕 New' : '✏️ Edited'}\` | [\`${rel}\`](${linkPrefix}${rel}) | ${desc} |`);
  }

  const recentSection =
    recentEntries.length > 0
      ? `## 🕒 Created & Edited Recently\n\n| Status | File | What It Is For |\n| :--- | :--- | :--- |\n${recentEntries.slice(0, 12).join('\n')}\n`
      : '';

  return `# \`campus_mobile\` — Clean Project Map (Active Files & UI Guide)

> **Filtered live view** — shows **only your active code, assets, tests, and recent changes** (OS boilerplate & empty \`.gitkeep\` scaffolds are hidden automatically until you add code inside them).  
> Auto-updates via live watcher (\`--watch\`), Git \`pre-commit\` hook, and GitHub Actions [\`sync-docs.yml\`](${linkPrefix}.github/workflows/sync-docs.yml).

${recentSection}
---

## 📂 Active Project Structure (with Side Descriptions)

\`\`\`text
${treeText}
\`\`\`

> **⬜ Empty scaffold folders (auto-expand as soon as you add a \`.dart\` file inside):**  
> \`${emptySummary || 'None'}\`

---

## 🎨 Quick UI Editing Guide (Where to Change What)

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
      if (!silent) console.log(`Updated ${rel}`);
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
  console.log('Watching campus_mobile for folder/file additions, edits, or deletions...');

  const watchRoots = ['lib', 'assets', 'test', 'docs', 'scripts', '.github', 'android/app/src', 'windows/runner', 'web'];
  let timer = null;

  const scheduleRebuild = (changedRel) => {
    if (!changedRel) return;
    const norm = String(changedRel).split(path.sep).join('/');
    if (norm.endsWith('project-structure.md') || norm.endsWith('FILE_MAP.md') || norm.includes('build/') || norm.includes('.dart_tool/')) {
      return;
    }
    clearTimeout(timer);
    timer = setTimeout(() => {
      try {
        const count = writeDocs({ silent: false });
        if (count > 0) {
          console.log(`[${new Date().toLocaleTimeString()}] Synced filtered project structure (${norm})`);
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
      fs.watch(abs, (_eventType, filename) => {
        scheduleRebuild(filename ? `${rel}/${filename}` : rel);
      });
    }
  }

  for (const rootFile of INCLUDED_ROOT_FILES) {
    const abs = path.join(ROOT, rootFile);
    if (fs.existsSync(abs)) fs.watch(abs, () => scheduleRebuild(rootFile));
  }
}

const args = new Set(process.argv.slice(2));
if (args.has('--watch')) {
  watchDocs();
} else if (args.has('--check')) {
  checkDocs();
} else {
  const count = writeDocs();
  if (count === 0) console.log('Project structure docs already up to date.');
}
