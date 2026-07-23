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
against, AND — for any app backed by a real database — confirmed proof
that writes are going to a dev/emulated environment, not production.

1. Confirm the dev server is reachable at `BASE_URL`.
2. If the app uses Firebase (or any backend with a real/prod data store),
   confirm the emulator is actually running and actually connected —
   don't just check the server responds. For DS-Directory specifically:
   check the browser console log for "Connected to Firebase emulators"
   after loading the page, or check the emulator's own UI
   (`http://127.0.0.1:4000`) for activity.
3. If you cannot positively confirm the emulator connection, STOP before
   writing or running any test that creates/edits/deletes data. Say so
   explicitly. Never assume "localhost" alone means emulator-connected —
   verify it.
4. This check applies every run, not just the first — a rebuild, branch
   switch, or reverted file can silently remove the emulator snippet from
   app source without anyone noticing until a test writes to production.

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
- Whether existing fixtures (`fixtures/index.js`) cover the data
  creation/cleanup any selected case will need — see "Test data cleanup"
  below for the default behavior this skill follows

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
   log this case's title and the specific element to a running list as you
   go — this is logging only, not reporting. The aggregate report happens
   once, at step 9, after the full loop finishes — see "Locator gaps
   report" below.
5. Every test starts from the app's root URL and reaches its target via UI
   interaction (clicking, filling forms) — never navigate directly to an
   inner state, since that's not how a real user gets there.

## 3. Write the test

- Before writing manual setup/teardown (creating test data, logging in as
  admin), check `fixtures/index.js` (or equivalent) for an existing fixture
  that already covers it — reuse it the same way you reuse existing page
  objects. Only write inline setup/teardown if no matching fixture exists,
  and if you write meaningfully reusable setup for the first time, flag to
  the user that it might be worth promoting to a fixture rather than
  leaving it duplicated across future specs.
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

## 4. Ask before running

`AskUserQuestion`: "Test written for [case title]. What next?"
- "Run it" → proceed to step 5
- "Something else" → follow their instructions instead

## 5. Run it

```bash
npx playwright test -g "<exact test title>" --trace on --retries 0
```

If this test creates, edits, or deletes data: state explicitly, as part of
the result, which destination it actually wrote to — `"Wrote to: emulator"`
or `"Wrote to: production (unverified)"` — based on the precondition check
above, not an assumption. Never report a data-writing test as passed without
this line. If you couldn't positively confirm the emulator connection per
the precondition, do not run the test at all — go back and stop there.

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

## 8. Mark the case as automated — mandatory, do not skip

Immediately after a case's test passes (step 7), before moving to the next
case:
1. Append to the source markdown test-plan file, under that case:
   `✅ Automated: <spec-file-path>`.
2. If a matching `.json` version of that test-plan file exists (per
   `test-plan-generator`'s schema), update the same case's entry there too:
   set `"automated": true` and `"automatedSpecFile": "<spec-file-path>"`.
   Don't let the JSON silently go stale while the markdown gets updated.

Do this per-case, not as a batch at the end — it's easy to forget in a
final summary. Not optional even when reporting a batch summary to the
user; verify at the end of the run that every converted case's entry in
both files (markdown and JSON, if present) actually has the marker before
declaring the run complete.

Repeat steps 2-8 for each remaining selected case.

## Test data cleanup — default behavior, not a per-run question

Any test case that creates, edits, or deletes real data must clean up
after itself by default. Do not ask whether cleanup should happen — that's
decided; only inform the user that it's happening.

1. Before writing setup/teardown inline, check `fixtures/index.js` for an
   existing fixture that already creates-and-cleans-up the data type needed
   (e.g. `testProfessional`). Use it if it exists.
2. If no matching fixture exists yet, write one in `fixtures/index.js`
   rather than inline `try/finally` in the spec file — cleanup logic
   belongs in fixtures, not duplicated per-spec, per the "Write the test"
   rule above.
3. State plainly, once per case that creates data, that cleanup will run
   automatically — e.g. "This test creates a throwaway professional record
   and deletes it in teardown regardless of pass/fail." Don't bury this in
   a batch summary at the end; say it when writing that specific case.
4. The only exception: if the user explicitly asks for a specific case to
   leave data behind (e.g. to manually inspect it after a failure), confirm
   that's what they mean, do it for that case only, and say so clearly in
   both the test's comments and the final report — don't let one
   exception's lack of cleanup go unnoticed among cases that do clean up.
5. Teardown must run even if the test fails or throws — this is what
   fixtures guarantee via their `use()` pattern, which is another reason to
   prefer fixtures over manual `afterEach` blocks that can be skipped on
   certain failure paths.

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