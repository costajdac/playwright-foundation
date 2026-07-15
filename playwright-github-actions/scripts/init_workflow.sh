#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/../assets"

WORKFLOW_DIR="$TARGET_DIR/.github/workflows"
WORKFLOW_FILE="$WORKFLOW_DIR/playwright.yml"

if [[ ! -f "$TARGET_DIR/package.json" ]]; then
  echo "No package.json found in $TARGET_DIR."
  echo "Run the playwright-project-setup skill first, then re-run this."
  exit 1
fi

mkdir -p "$WORKFLOW_DIR"

if [[ -f "$WORKFLOW_FILE" ]]; then
  echo "Skipping: $WORKFLOW_FILE already exists."
else
  cp "$ASSETS_DIR/playwright.yml" "$WORKFLOW_FILE"
  echo "Created: $WORKFLOW_FILE"
fi

echo ""
echo "Next steps:"
echo "  1. Commit and push .github/workflows/playwright.yml"
echo "  2. If your tests need env vars (e.g. BASE_URL), add them as repo secrets:"
echo "     Settings > Secrets and variables > Actions > New repository secret"
echo "  3. Open a PR — the workflow runs automatically."