#!/usr/bin/env bash
# Gathers raw context for the test-plan-generator skill:
#   1. Changed files between the current branch and a base branch
#   2. The full diff
#   3. Existing automated test titles, for duplicate-avoidance context
#
# This script does NOT analyze or prioritize anything — that's Claude's job.
# It only collects information.
#
# Usage:
#   ./gather-diff-context.sh <base-branch>
# Defaults to "main" if no argument given.

set -euo pipefail

BASE_BRANCH="${1:-main}"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

if ! git rev-parse --verify "$BASE_BRANCH" >/dev/null 2>&1; then
  echo "Base branch '$BASE_BRANCH' not found locally."
  echo "Try: git fetch origin $BASE_BRANCH:$BASE_BRANCH"
  exit 1
fi

echo "=================================================="
echo "Current branch: $CURRENT_BRANCH"
echo "Base branch:    $BASE_BRANCH"
echo "=================================================="

echo ""
echo "--- Changed files (status) ---"
git diff --name-status "$BASE_BRANCH"..."$CURRENT_BRANCH"

echo ""
echo "--- Full diff ---"
git diff "$BASE_BRANCH"..."$CURRENT_BRANCH"

echo ""
echo "--- Existing automated test titles (for duplicate-avoidance) ---"
# Looks for common Playwright/Jest-style test declarations across the repo.
# This is a best-effort scan, not a full parse — Claude should treat it as
# a starting point for checking coverage, not a guaranteed-complete list.
if command -v rg >/dev/null 2>&1; then
  rg -n --no-heading -e "^\s*(test|it)\s*\(\s*['\"\`]" -e "^\s*describe\s*\(\s*['\"\`]" \
    --glob '*.spec.js' --glob '*.spec.ts' --glob '*.test.js' --glob '*.test.ts' \
    . || echo "(no matches found)"
else
  grep -rnE "^\s*(test|it|describe)\s*\(\s*['\"\`]" \
    --include="*.spec.js" --include="*.spec.ts" \
    --include="*.test.js" --include="*.test.ts" \
    . || echo "(no matches found)"
fi

echo ""
echo "=================================================="
echo "Context gathering complete. Analysis and test plan"
echo "writing happens next, done by Claude directly — not"
echo "by this script."
echo "=================================================="
