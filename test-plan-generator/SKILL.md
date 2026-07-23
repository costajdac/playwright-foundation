---
name: test-plan-generator
description: Analyzes the code changes on the current branch (vs. a base branch, typically main) and generates a prioritized manual test plan as a markdown file — title, short description, and up to 6 steps to reproduce per test case, ranked P0/P1/P2 by business and user impact. Checks existing automated tests and any prior test plan to avoid duplicating coverage. Use when the user wants a test plan, wants to know what to test for a branch/PR, or asks to review changes for test coverage. Does NOT write automated test code — that is a separate skill.
---

# Test Plan Generator

Reads the diff between the current branch and a base branch, reasons about the
user/business impact of what changed, checks what's already covered by
existing tests, and writes a prioritized manual test plan to a markdown file.

This skill is judgment-based, not a deterministic scaffold: the script only
gathers raw context (diff, file list, existing test titles). Claude does the
actual analysis — deciding what's meaningfully changed, what impact it has,
and what's already covered — then writes the plan directly.

## Elicitation (only these, nothing else)

- Base branch to compare against (default: `main`) — OR confirm this is a
  **baseline run** (see "Baseline mode" below) if there's no meaningful diff
  to compare against yet
- Where existing automated tests live (default: look for `**/*.spec.js` under the repo; ask if none found)
- Whether a prior test plan file already exists to check against for
  duplicates (ask for its path, or confirm there isn't one yet)
- Output file name/location. Don't hardcode a folder name — detect it:
  1. Look for an existing Playwright config (`playwright.config.js` or
     `.ts`) anywhere in the repo. If found, place test plans in a
     `test-plans/` folder next to it (e.g. if config is at
     `e2e/playwright.config.js`, use `e2e/test-plans/`; if config is at
     repo root, use `test-plans/` at repo root).
  2. If no config is found, look for a folder matching common testing
     conventions (`e2e/`, `e2e-testing/`, `tests/`, `playwright/`,
     `cypress/`, `__tests__/`) and ask the user to confirm before using it.
  3. If neither exists, ask the user directly where test plans should go —
     don't guess a name.
  Filename itself: `<branch-name>-<date>-test-plan.md`, or
  `baseline-<date>-test-plan.md` for a baseline run.
- Maximum number of test cases to include (default: 12 total). Don't ask
  this as an open question, but you MUST explicitly say it out loud as part
  of your response before running the script/analysis — e.g. "I'll cap this
  at 12 test cases (the default) — let me know if you want more or fewer
  before I continue." Do not silently apply the default without stating it;
  the user should never have to notice the cap only after reading the
  finished plan.

Do not ask anything beyond these five. If the user's request already answers
one (e.g. "compare against develop"), don't re-ask it.

## Baseline mode (first run, or running on main with nothing to diff)

If the current branch IS the base branch, or the diff is empty, don't fall
back to comparing against the branch's own full history against some older
point — that produces a noisy, unfocused plan. Instead, ask the user to
confirm: **"There's no diff to compare — do you want a baseline test plan
covering the app's current functionality instead?"**

If yes:
1. Skip `gather-diff-context.sh` entirely — there's no diff to gather.
2. Read the app's actual code directly (entry points, main user flows,
   forms, auth, anything that reads/writes data) to identify what exists
   today worth testing.
3. Still check existing automated tests / prior test plans for what's
   already covered, same as diff mode.
4. Write the test plan the same way, using the same template and priority
   rules — just sourced from "what the app does today" instead of "what
   changed."
5. Label the output clearly as a baseline plan (the template's title line
   should read "Baseline Test Plan" instead of naming a comparison branch).

This is a heavier, slower operation than diff mode — reading and reasoning
about an entire app is more work than reasoning about a focused diff. Warn
the user this will take longer and may need a second pass as the app grows,
rather than trying to enumerate every possible test case in one shot.

## How to run it

1. Ask the elicitation questions above.
2. Run the context-gathering script:
   ```bash
   bash scripts/gather-diff-context.sh <base-branch>
   ```
   This prints:
   - The list of changed files (`git diff --name-status`)
   - The full diff content
   - Titles of existing automated tests found (grepped `test(...)` /
     `it(...)` / `describe(...)` calls), so you have a baseline of what's
     already covered
3. If the user pointed you at a prior test-plan markdown file, read it too —
   its test case titles/descriptions are additional "already covered" context.
4. Analyze the diff yourself (see "How to prioritize" and "How to avoid
   duplicates" below). Do not just summarize the diff — reason about what a
   real user or the business would actually be affected by.
5. Before writing, resolve every `{{...}}` placeholder in the template —
   including conditional blocks like `{{#IF_DIFF_MODE}}...{{/IF_DIFF_MODE}}`
   (keep the block's content and drop the markers if the condition applies,
   remove the whole block if it doesn't) and `{{IF_NONE_OMITTED: "..."}}`
   (replace with the quoted text if true, delete if false). The written
   file must contain no literal `{{` or `}}` characters anywhere.
6. Write the test plan using the template in `assets/test-plan-template.md`,
   to the output location confirmed in elicitation.
7. Also write a machine-readable JSON version alongside the markdown file,
   same base filename with a `.json` extension (e.g.
   `baseline-2026-07-23-test-plan.md` and
   `baseline-2026-07-23-test-plan.json`). This is for import into external
   tools (Jira, Xray, Zephyr, etc.) without manual field mapping. Schema:

```json
   {
     "generatedDate": "2026-07-23",
     "mode": "baseline",
     "branch": null,
     "baseBranch": null,
     "maxCases": 12,
     "testCases": [
       {
         "id": "P0-1",
         "priority": "P0",
         "title": "string",
         "description": "string",
         "steps": ["string", "string"],
         "expectedResult": "string",
         "automated": false,
         "automatedSpecFile": null
       }
     ],
     "alreadyCovered": ["string"],
     "notIncluded": [
       { "priority": "P2", "title": "string" }
     ],
     "unclearImpact": ["string"]
   }
```

   For diff-mode runs, populate `branch`/`baseBranch`; set `mode: "diff"`.
   Field names are fixed — don't rename or nest differently between runs,
   since the whole point is a stable schema an external tool can map once
   and reuse.
8. Tell the user where the file(s) were written and give a one-line summary

## How to prioritize

Assign exactly one priority per test case:
- **P0** — breaks a core user flow entirely, causes data loss/corruption,
  exposes private data, or blocks basic app usability. Test this first.
- **P1** — breaks a significant feature or a commonly-used path, but a
  workaround exists, or it's not on the critical path.
- **P2** — edge cases, rarely-used paths, cosmetic/UI-only issues, or
  low-traffic admin-only functionality.

Order the test plan P0 first, then P1, then P2 — not in diff order or file
order.

If you genuinely can't tell the business/user impact of a change from the
code alone (e.g. an internal refactor with no visible behavior change), say
so in the test case's description rather than guessing at a priority you
can't justify. It's fine to mark something "P2 — unclear user-facing impact,
confirm with the author" rather than inventing a confident-sounding reason.

## Applying the test case limit

The point of the limit is a focused, actually-usable plan — not an
exhaustive list padded to look thorough. If your analysis surfaces more
legitimate candidate test cases than the limit allows:

1. Keep all P0 cases first, even if that alone reaches or exceeds the limit.
   P0s are never cut to make room for lower-priority cases.
2. Fill remaining slots with P1, then P2, in that order.
3. If cases are cut, do NOT silently drop them and say nothing. List what
   was omitted, by title only, in a short "Not included this round" section
   at the bottom of the plan — one line each, no full write-up. This keeps
   the plan honest about what it didn't cover, without bloating it back up.
4. Never inflate a case's priority just to justify including it under the
   limit. If something is genuinely P2, it stays P2 even if that means it
   gets cut — the limit should shrink the plan's scope, not distort its
   priorities.

If the number of P0 cases alone exceeds the limit, say so explicitly rather
than quietly cutting P0s — that's a signal the branch may be too large or
risky to review as one unit, worth surfacing to the user directly.

## Re-running against unchanged code

If a baseline run finds the app is unchanged since the last baseline plan
(same commit, or the compared branch has no new diff), tell the user
explicitly before reusing prior analysis: "The app hasn't changed since the
last baseline plan on [date] — I'll reuse that analysis rather than
re-deriving it from scratch. Say so if you'd like a fresh pass instead."
Never silently reuse a prior run's conclusions without surfacing that
choice — the user should get the option to force a fresh analysis, not
just receive an efficiency shortcut they didn't ask for.

## When "overwrite" would produce identical content

If the user chooses to overwrite an existing same-day file and the new
content would be byte-for-byte identical to what's already there, say so
explicitly rather than silently deciding whether to rewrite or skip — e.g.
"The content would be identical to the existing file — I'll leave it
as-is rather than rewriting, unless you'd rather I overwrite anyway." Don't
silently choose either option; let the user confirm which they actually
want, since "overwrite" and "skip because it's the same" are different
outcomes even when the file contents end up equivalent.

## How to avoid duplicates

Before writing a new test case, check it against:
1. Existing automated test titles/descriptions from the script's output
2. Every prior test-plan file under the test-plans folder confirmed/detected
   in this run's elicitation, not just one — scan the whole directory for
   overlapping coverage, since plans are now generated per branch/run
   rather than accumulated into a single file

If a change is already covered by an existing automated test that still
applies (i.e. the change doesn't break that test's assumptions), don't
create a manual test case for it — note in your summary that it's already
covered instead. Only write new test cases for genuinely new or changed
behavior that isn't already exercised.

## Test case format

Each test case, using the template:
- **Title** — short, specific, describes the scenario (not just the file
  that changed)
- **Priority** — P0 / P1 / P2
- **Description** — one to two sentences, plain language, what this is
  testing and why it matters
- **Steps to Reproduce** — numbered, maximum 6 steps, concrete and
  actionable (not vague like "test the form" — say what to click/enter)
- **Expected Result** — one line, what should happen if it works correctly

The Expected Result field is a default addition beyond what was explicitly
asked for, since a test case without a pass/fail criterion isn't
executable — flag this to the user on first use and let them tell you to
drop it if they'd rather not have it.

## Out of scope — do not do these

This skill produces a manual test plan document only. It must NOT:
- Write, generate, or scaffold automated test code (Playwright specs,
  page objects, etc.) — that's a separate skill
- Run any existing tests
- Modify any existing test files
- Commit or push the generated test plan on the user's behalf
- Invent business/user impact context that isn't evidenced by the code or
  visible UI — if impact is unclear, say so rather than guessing confidently

## Notes

- If the base branch doesn't exist locally, tell the user to `git fetch`
  first rather than guessing at the diff.
- If there are no changes between the current branch and the base branch,
  don't generate an empty or padded-out test plan — offer baseline mode
  instead (see above).
- If a plan already exists for this exact branch name and date (re-running
  the skill twice in one day), ask whether to overwrite it or append a
  suffix (`-v2`) rather than silently overwriting.
- If the diff is very large (e.g. a branch with many unrelated commits),
  consider asking the user to confirm the scope rather than generating a
  huge, unfocused plan — quality and relevance matter more than covering
  every line changed.
