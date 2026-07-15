#!/usr/bin/env bash
# Scaffolds a Playwright UI+API test project structure into a target directory.
#
# Usage:
#   ./init_project.sh <target-dir> [--no-install]
#
# --no-install skips `npm install` (useful offline / for review before installing)

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS_DIR="$SKILL_DIR/assets"

TARGET_DIR="${1:-}"
NO_INSTALL="${2:-}"

if [ -z "$TARGET_DIR" ]; then
  echo "Usage: $0 <target-dir> [--no-install]"
  exit 1
fi

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

echo "==> Scaffolding Playwright UI + API project in: $TARGET_DIR"

# --- Folder structure ---
mkdir -p tests/ui tests/api pages utils

# --- Copy templates (skip files that already exist, to avoid clobbering) ---
copy_if_absent() {
  local src="$1"
  local dest="$2"
  if [ -f "$dest" ]; then
    echo "    skip (exists): $dest"
  else
    cp "$src" "$dest"
    echo "    created: $dest"
  fi
}

copy_if_absent "$ASSETS_DIR/playwright.config.js"      "playwright.config.js"
copy_if_absent "$ASSETS_DIR/eslint.config.js"           "eslint.config.js"
copy_if_absent "$ASSETS_DIR/.prettierrc"                ".prettierrc"
copy_if_absent "$ASSETS_DIR/.env.example"               ".env.example"
copy_if_absent "$ASSETS_DIR/.gitignore"                 ".gitignore"
copy_if_absent "$ASSETS_DIR/pages/BasePage.js"          "pages/BasePage.js"
copy_if_absent "$ASSETS_DIR/pages/HomePage.js"          "pages/HomePage.js"
copy_if_absent "$ASSETS_DIR/utils/apiClient.js"         "utils/apiClient.js"
copy_if_absent "$ASSETS_DIR/tests/ui/example.spec.js"   "tests/ui/example.spec.js"
copy_if_absent "$ASSETS_DIR/tests/api/example.spec.js"  "tests/api/example.spec.js"

# --- package.json: create if missing, otherwise leave alone ---
if [ ! -f "package.json" ]; then
  cat > package.json <<'EOF'
{
  "name": "playwright-tests",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "test": "playwright test",
    "test:ui": "playwright test --project=ui-chromium --project=ui-firefox",
    "test:api": "playwright test --project=api",
    "test:headed": "playwright test --headed",
    "test:report": "playwright show-report",
    "lint": "eslint .",
    "format": "prettier --write ."
  }
}
EOF
  echo "    created: package.json"
else
  echo "    skip (exists): package.json  -- add scripts manually if needed, see README below"
fi

echo "==> Structure ready."

if [ "$NO_INSTALL" = "--no-install" ]; then
  echo "==> Skipping npm install (--no-install passed)."
  echo "    Run manually: npm install --save-dev @playwright/test dotenv eslint eslint-plugin-playwright eslint-config-prettier prettier && npx playwright install --with-deps"
  exit 0
fi

echo "==> Installing dependencies..."
npm install --save-dev @playwright/test dotenv eslint eslint-plugin-playwright eslint-config-prettier prettier

echo "==> Installing Playwright browsers..."
npx playwright install --with-deps

echo "==> Done. Next steps:"
echo "    1. cp .env.example .env   (fill in real values)"
echo "    2. npm run test:ui        (run UI tests)"
echo "    3. npm run test:api       (run API tests)"
