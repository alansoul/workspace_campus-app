#!/usr/bin/env node
/**
 * Installs lightweight Git hooks into `.git/hooks/` so `docs/project-structure.md`
 * and `FILE_MAP.md` automatically regenerate & stage before every commit and after
 * branch checkouts or merges.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const HOOKS_DIR = path.join(ROOT, '.git', 'hooks');

if (!fs.existsSync(HOOKS_DIR)) {
  console.error('Could not find .git/hooks directory.');
  process.exit(1);
}

const PRE_COMMIT = `#!/bin/sh
if command -v node >/dev/null 2>&1 && [ -f "scripts/update_project_structure.mjs" ]; then
  node scripts/update_project_structure.mjs >/dev/null 2>&1 || true
  git add docs/project-structure.md FILE_MAP.md >/dev/null 2>&1 || true
fi
`;

const POST_SWITCH = `#!/bin/sh
if command -v node >/dev/null 2>&1 && [ -f "scripts/update_project_structure.mjs" ]; then
  node scripts/update_project_structure.mjs >/dev/null 2>&1 || true
fi
`;

const hooks = {
  'pre-commit': PRE_COMMIT,
  'post-checkout': POST_SWITCH,
  'post-merge': POST_SWITCH,
};

for (const [name, content] of Object.entries(hooks)) {
  const target = path.join(HOOKS_DIR, name);
  fs.writeFileSync(target, content, { encoding: 'utf8', mode: 0o755 });
  console.log(`Installed .git/hooks/${name}`);
}
