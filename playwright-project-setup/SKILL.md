---
name: playwright-project-setup
description: Scaffolds a new Playwright project (JavaScript) preconfigured for both UI and API testing — folder structure, playwright.config.js, ESLint/Prettier, dotenv, and Page Object Model boilerplate. Use this whenever the user wants to start a new Playwright test project, set up Playwright from scratch, add a testing structure to an existing repo, or asks to scaffold/bootstrap/initialize UI and API test automation. Trigger even if they just say "set up Playwright" or "new test project" without mentioning UI/API explicitly — this skill covers both.
---

# Playwright Project Setup (UI + API)

Scaffolds a consistent, reusable Playwright project structure for JavaScript projects that need both UI and API test coverage. Always produces the same structure so every project built with this skill looks and behaves the same way.

## What it sets up

```
project-root/
├── tests/
│   ├── ui/example.spec.js       # UI test using Page Object Model
│   └── api/example.spec.js      # API test using Playwright's request fixture
├── pages/
│   ├── BasePage.js              # Base class all page objects extend
│   └── HomePage.js              # Example page object
├── utils/
│   └── apiClient.js             # Thin wrapper for shared API request logic (auth headers, etc.)
├── playwright.config.js         # 3 projects: ui-chromium, ui-firefox, api
├── .eslintrc.json               # eslint-plugin-playwright + prettier integration
├── .prettierrc
├── .env.example                 # BASE_URL / API_BASE_URL template
├── .gitignore
└── package.json                 # test/lint/format scripts (only created if missing)
```

**Design choices baked in** (don't relitigate these unless the user asks):
- API tests use Playwright's built-in `request` fixture — no axios/supertest dependency needed.
- UI tests use Page Object Model via a `pages/` folder.
- `playwright.config.js` splits UI (Chromium + Firefox) and API into separate projects, so `npm run test:ui` and `npm run test:api` run independently.

## How to run it

1. Ask the user for the target directory if it's not obvious from context (current project root vs. a new folder).
2. Run the setup script:

```bash
bash scripts/init_project.sh <target-dir>
```

This creates the folder structure, copies all template files (skipping any that already exist — it never clobbers existing files), creates `package.json` if absent, installs npm dependencies, and installs Playwright browsers.

3. If the user is offline, wants to review before installing, or is scripting this into a larger flow, use `--no-install` to skip the npm/browser install step:

```bash
bash scripts/init_project.sh <target-dir> --no-install
```

4. After running, tell the user the next steps (also printed by the script):
   - Copy `.env.example` to `.env` and fill in real values.
   - `npm run test:ui` to run UI tests.
   - `npm run test:api` to run API tests.

## Notes

- The script is idempotent-safe: re-running it on a project that already has some of these files will skip existing ones rather than overwriting them, so it's safe to run again after adding custom tests.
- If the user already has a `package.json`, the script leaves it alone and only prints a reminder to add scripts manually — it does not merge into existing package.json content, to avoid corrupting existing scripts/deps.
- If the user wants CI (GitHub Actions) for this project, that's a separate skill — don't try to add workflow files here.
- If the user wants a different browser matrix, auth setup (e.g. storageState for logged-in sessions), or TypeScript instead of JS, treat those as follow-up customizations after the base scaffold is in place — ask what they need and edit the generated files directly rather than modifying the templates in this skill (those templates are meant to stay a stable default for future projects).
