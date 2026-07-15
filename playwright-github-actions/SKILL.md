---
name: playwright-github-actions
description: scaffolds a GitHub Actions workflow to run Playwright tests
---

# Playwright GitHub Actions Setup

Scaffolds a `.github/workflows/playwright.yml` that runs on every push and pull request, installs dependencies and Playwright browsers, runs UI and API tests as separate jobs, and uploads the HTML report as an artifact on failure.

## Prerequisite

This skill assumes the target repo already has a `package.json` with `test:ui` and `test:api` scripts (produced by `playwright-project-setup`). If it doesn't, stop and tell the user to run that skill first.

## What it sets up

\```
project-root/
└── .github/
    └── workflows/
        └── playwright.yml
\```

**Design choices baked in:**
- Two separate jobs (`ui-tests`, `api-tests`) so they run in parallel and a
  failure in one doesn't block seeing results from the other.
- Triggers on `push` to `main` and on every `pull_request`.
- Caches `node_modules` via `actions/setup-node`'s built-in npm cache.
- Uploads `playwright-report/` as a build artifact, but only `if: failure()`,
  so successful runs don't waste storage.

## How to run it

1. Confirm the target project has `test:ui` / `test:api` scripts in
   `package.json`. If not, stop and say so.
2. Run the setup script:
   \```bash
   bash scripts/init_workflow.sh <target-dir>
   \```
   This creates `.github/workflows/playwright.yml`, skipping if the file
   already exists (never overwrites).
3. Tell the user the workflow will run automatically on their next push or PR
   — nothing else to install locally.

## Notes

- If the user wants a different Node version, browser matrix, or trigger
  branches, edit the generated `playwright.yml` directly — don't modify the
  template in this skill's `assets/` folder, which should stay a stable
  default for future projects.
- If the user's tests need environment variables (e.g. `BASE_URL`), tell them
  to add them as repository secrets and reference them under `env:` in the
  workflow — don't hardcode values into the template.