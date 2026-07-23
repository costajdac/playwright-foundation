---
name: playwright-project-setup
description: Scaffolds a new Playwright project (JavaScript) — installs Playwright and dependencies, and creates folder structure, playwright.config.js, ESLint/Prettier, and dotenv boilerplate. Does NOT write app-specific tests or discover an app's login/selectors — that is a separate skill. Use this whenever the user wants to install Playwright, scaffold a new test project's folder structure, or set up a testing repo from scratch. Trigger even if they just say "set up Playwright" or "new test project."
---

# Playwright Project Setup (installation + structure only)

Scaffolds a consistent, reusable Playwright project **skeleton** for JavaScript projects. This skill installs tooling and creates folders/config files — it does not explore any target application, does not write app-specific tests, and does not make architectural decisions about auth or environments. Always produces the same structure so every project built with this skill looks and behaves the same way.

## Elicitation (only these, nothing else)
- Target directory
- JS project
- UI + API, or UI only
- Local dev server or deployed URL for BASE_URL (do not inspect the target app to determine this — ask the user directly, or leave .env.example blank for them to fill in)

## UI-only handling

The scaffold script always generates both UI and API structure — it has no
`--ui-only` flag. If the user chooses "UI only":

1. Run the script normally (it will create both).
2. Then remove the API-specific pieces:
   - `tests/api/` (entire directory)
   - `utils/apiClient.js`, and `utils/` itself if now empty
   - The `api` project block in `playwright.config.js`
   - The `test:api` script in `package.json`
   - Any `API_BASE_URL`/API-token lines in `.env.example`
3. Grep the remaining config files (`playwright.config.js`, `package.json`,
   `eslint.config.js`) for lingering `api` references and remove any found.
4. Verify the result with `npx playwright test --list` and confirm only UI
   tests/projects resolve — don't just trust that the deletions succeeded.

This is expected, standard behavior for a "UI only" choice — not a
deviation to flag or ask about.

## Out of scope — do not do these

This skill is installation + folder structure only. It must NOT:
- Read, grep, or explore any target application's source code (e.g. a site the user says they'll eventually test)
- Discover or hardcode real login flows, selectors, or any app-specific behavior
- Write test files containing real assertions or app-specific logic — example/placeholder files only, with generic TODO content
- Create auth setup files (e.g. `auth.setup.ts`) with real credentials or flows
- Copy any rules/docs files into the target project
- Ask elicitation questions about auth roles or CI
- Ask about environments beyond the single BASE_URL question already listed in Elicitation (e.g. don't ask about staging, multiple environments, or environment-specific config — that belongs to a separate skill)
- Do not read, grep, cat, or otherwise inspect any file belonging to the target application, even to check feasibility of the generic scaffold. If the generic scaffold might not fit, ask the user — don't investigate to find out.

If the user's request touches any of the above, tell them that belongs to a separate skill and stop after completing only the installation/structure portion.

## What it sets up

project-root/
├── tests/
│   ├── ui/example.spec.js       # placeholder UI test — generic, no real app logic
│   └── api/example.spec.js      # placeholder API test — generic, no real app logic
├── fixtures/
│   └── index.js                 # placeholder fixtures file — generic, no real app logic
├── pages/
│   ├── BasePage.js              # empty base class, ready for extension
│   └── HomePage.js              # empty example page object (structure only, no real selectors)
├── utils/
│   └── apiClient.js             # thin wrapper skeleton for shared API request logic
├── playwright.config.js         # 3 projects: ui-chromium, ui-firefox, api
├── .eslintrc.json               # eslint-plugin-playwright + prettier integration
├── .prettierrc
├── .env.example                 # BASE_URL template — real value if the user gave one, otherwise a blank placeholder for them to fill in
├── .gitignore
└── package.json                 # test/lint/format scripts (only created if missing)


**Note:** the tree above shows the default (UI + API) output. If the user
chose UI only, see "UI-only handling" above for what gets removed.

**Design choices baked in** (don't relitigate these unless the user asks):
- API tests use Playwright's built-in `request` fixture — no axios/supertest dependency needed.
- UI tests use Page Object Model via a `pages/` folder — structure only, no populated selectors.
- `playwright.config.js` splits UI (Chromium + Firefox) and API into separate projects, so `npm run test:ui` and `npm run test:api` run independently.

## How to run it

1. Ask the applicable Elicitation questions above (target directory, UI+API vs UI only, BASE_URL source) before running anything. "JS project" is fixed, not a question — no need to ask about it.
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
   - If they want real tests written against a specific app, that's a separate skill — point them to it, don't start writing app-specific tests yourself.

## Notes

- The script is idempotent-safe: re-running it on a project that already has some of these files will skip existing ones rather than overwriting them, so it's safe to run again after adding custom tests.
- If the user already has a `package.json`, the script leaves it alone and only prints a reminder to add scripts manually — it does not merge into existing package.json content, to avoid corrupting existing scripts/deps.
- If the user wants CI (GitHub Actions) for this project, that's a separate skill — don't try to add workflow files here.
- If the user wants a different browser matrix, auth setup (e.g. storageState for logged-in sessions), or TypeScript instead of JS, treat those as follow-up customizations after the base scaffold is in place — ask what they need and edit the generated files directly rather than modifying the templates in this skill (those templates are meant to stay a stable default for future projects).
- If mid-conversation the user starts describing a real application (URLs, login flows, what to test), that's a signal they want the *other* skill — stop and say so rather than following along.