---
name: automation-test-creation-with-playwright
description: Converts test cases from a generated test-plan markdown file (test-plans/*.md) into real, working Playwright spec files — verifying every selector against the live running app, never guessing from source. Requires the app and its dependencies (dev server, Firebase emulator if applicable) already running locally. Use when the user wants to automate/implement test cases from a test plan, turn a test plan into real tests, or asks to convert P0/P1 cases into Playwright code.
---

# Automation Test Creation with Playwright

Reads a test-plan markdown file (produced by `test-plan-generator`), lets the
user pick which priority tier to automate this run, then writes real
Playwright spec files — verifying every selector against the live app.

**Never skip an `AskUserQuestion` step in this skill, even if told to work
autonomously.**

## Precondition — check before doing anything else

This skill needs a live, running instance of the app to verify selectors
against. Confirm the dev server (and Firebase emulator, if applicable) is
reachable at the project's `BASE_URL` before starting. If it's not running,
stop and tell the user to start it — never fall back to guessing selectors
from HTML source as a substitute for live verification.

## Elicitation (only these, nothing else)
- Which test-plan file to automate from (confirm if only one exists;
  ask if multiple)
- Which priority tier(s) to convert this run: P0 only / P0+P1 / all / a
  specific subset by title — always ask, never assume "all"

## 1. Review existing test suite

Read all existing spec files under the project's testing folder to understand:
- What's already covered (skip cases already automated — see step 8)
- Which file/describe block a new case belongs in, based on existing structure
- Conventions already in use (naming, grouping, `beforeEach` patterns)
- Whether existing page objects (`pages/BasePage.js`, etc.) cover what's needed

## 2. For each selected test case, inspect and verify live

For each case, in priority order (P0 first):
1. Read the case's Steps to Reproduce and Expected Result from the plan.
2. Drive the live app through those exact steps (via `playwright codegen` or
   available browser tooling) to find real, resolved selectors.
3. Locator priority: `getByRole` > `getByLabel` > `getByText` >
   `getByPlaceholder` > `getByTestId` > CSS selector. Use the first one that
   reliably resolves.
4. If no reliable selector exists (no role/label/text/placeholder/testid
   resolves cleanly), do NOT add a `data-testid` to app source. Use the
   best available fallback (e.g. a scoped CSS selector) to keep moving, but
   log this case's title and the specific element in a running list as you
   go. Never block on this — the whole batch shouldn't stall waiting for a
   markup decision that isn't this skill's to make.
5. Every test starts from the app's root URL and reaches its target via UI
   interaction (clicking, filling forms) — never navigate directly to an
   inner state, since that's not how a real user gets there.

## 3. Write the test

- Place it in the correct file/describe block per existing structure —
  extend `BasePage`, reuse existing page objects, only add new ones for
  genuinely new pages/components.
- One case = one logical user flow, matching the test plan's own scope.
- No custom timeouts — use `playwright.config.js` defaults. Custom timeouts
  are only acceptable as a debugging fix (step 6) if the default genuinely
  wasn't enough, and only after confirming that's really the issue.
- Base the steps and assertions directly on the test plan's Steps to
  Reproduce / Expected Result — don't invent additional coverage the plan
  didn't ask for.

## Locator gaps report

After all selected cases are converted (or attempted), if any test needed a
fallback selector because no reliable user-visible locator existed, include
a summary in the final report to the user — one line per gap:

- Test case title
- The element/action that lacked a good locator
- What fallback was used instead (e.g. "CSS selector `.mkt-carousel-btn`
  instead of a role/label locator")

This is informational only — the skill does not act on it. It's a
QE decision whether to add `data-testid` attributes, request a markup
fix, or accept the fallback as-is.

## 4. Ask before running

`AskUserQuestion`: "Test written for [case title]. What next?"
- "Run it" → proceed to step 5
- "Something else" → follow their instructions instead

## 5. Run it

```bash
npx playwright test -g "<exact test title>" --trace on --retries 0
```
Pass → step 7. Fail → step 6.

## 6. Debug using the trace CLI (not the GUI — it blocks execution)

```bash
npx playwright trace open <path-to-trace.zip>
npx playwright trace actions          # find the ✗
npx playwright trace action <number>
npx playwright trace snapshot <number> --name after
npx playwright trace requests         # if data/API related
npx playwright trace errors
npx playwright trace close
```

Report clearly: what went wrong, the evidence, the failing line. If the
root cause is in the test (bad selector, wrong expected value), fix and
re-run. **If the root cause is in the app itself, explain it to the user
rather than guessing at a workaround** — a test shouldn't be bent to match
broken behavior just to make it pass.

Repeat 5-6 until it passes or needs user input.

## 7. Confirm and finalize

`AskUserQuestion`: "Test passed. Does it meet your expectations?"
- "Looks good" → strip inline comments, collapse extra blank lines, move on
- "Needs changes" → apply, re-run from step 5

## 8. Mark the case as automated

Append to the source test-plan file, under this case: `✅ Automated:
<spec-file-path>`. This lets future `test-plan-generator` runs see it in
"Already covered," and prevents this skill from reconverting it later.

Repeat steps 2-8 for each remaining selected case.

## 9. Report locator gaps, then offer to commit — once, after all selected cases are done

Show the Locator gaps report (if any gaps were logged) before asking about
the commit — so the QE sees it while deciding whether to commit as-is.

`AskUserQuestion`: "Should I commit the new tests?"
- "Yes" → review `git status`/`git diff`, draft a commit message matching
  the repo's existing style (check `git log`), stage and commit
- "No" → stop

## Out of scope — do not do these
- Invent test cases beyond what's in the test-plan file
- Run the full existing suite as part of this — only the newly written tests
- Push commits without being asked separately
- Start dev servers or emulators — that's a precondition, not this skill's job
- Guess selectors from source as a substitute for live verification, ever
- Add `data-testid` attributes to app source — flag gaps instead, let the
  QE decide

## Notes
- If a case's steps don't match the app's current actual behavior (plan
  might predate a recent change), say so and ask whether to adjust or skip
  — don't write a test for behavior that no longer exists.
- If browser/codegen tooling isn't available in the environment, stop and
  say so rather than falling back to guessing.