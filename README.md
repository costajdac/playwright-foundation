# playwright-foundation

A personal library of [Claude Skills](https://docs.claude.com/en/docs/claude-code/skills)
for Playwright test automation. Each skill handles one piece of a testing
workflow, so projects get consistent scaffolding, CI, and test planning
instead of rebuilding the same boilerplate — or reasoning — every time.

## Skills in this repo

| Skill | Does | Does NOT do |
|---|---|---|
| `playwright-project-setup` | Installs Playwright + dependencies, creates folder structure, `playwright.config.js`, ESLint/Prettier, dotenv, generic placeholder tests | Explore any target app, write real selectors/tests, decide on auth or environments |
| `playwright-github-actions` | Scaffolds `.github/workflows/playwright.yml` (UI + API jobs, runs on push/PR) | Anything beyond CI config — requires `playwright-project-setup` to have run first |
| `test-plan-generator` | Analyzes the diff between the current branch and a base branch (or the whole app, in baseline mode), and writes a prioritized (P0/P1/P2) manual test plan as a markdown file — checks existing automated tests and prior plans to avoid duplicate coverage | Write or scaffold automated test code, run any tests, modify existing test files, or guess at business impact it can't justify from the code |

These are deliberately narrow, each with an explicit scope. If you build a
skill that does something new, give it its own name and its own scope —
update this table rather than letting an existing skill's job quietly grow.

## Layout convention

Every skill lives in its own top-level folder, named after the skill:

```
<skill-name>/
├── SKILL.md      # required: frontmatter (name, description) + instructions
├── scripts/      # executable scripts the skill runs
└── assets/       # template files the skill copies into a target project
```

`SKILL.md`'s frontmatter `description` is what Claude Code uses to decide
when to trigger the skill — it should list concrete trigger phrases, not
just a vague summary.

Not every skill's script does the same kind of work. `playwright-project-setup`
and `playwright-github-actions` are deterministic scaffolds — their scripts
do the actual file creation. `test-plan-generator` is judgment-based — its
script (`gather-diff-context.sh`) only collects raw context (diff, existing
test titles); the analysis and writing is done by Claude directly, following
the rules in `SKILL.md`. Keep this distinction in mind when writing new
skills: don't try to force a scripted deterministic output out of a task
that actually requires reasoning, and don't leave a purely mechanical task
to open-ended judgment when a script would produce more consistent results.

## Installing a skill

**Skills directory:** Claude Code reads skills from `~/.claude/skills/`
(global) or `<project>/.claude/skills/` (project-scoped, that project only).
If you use other agent tools that read from a different path (e.g.
`~/.agents/skills/`), install there separately and explicitly — don't assume
one install covers both. Check `ls ~/.claude/skills/` after installing to
confirm.

**Global install** (available in every project) — symlink, not copy, so
edits to this source repo apply immediately without reinstalling:
```bash
ln -s "$(pwd)/playwright-project-setup" ~/.claude/skills/playwright-project-setup
ln -s "$(pwd)/playwright-github-actions" ~/.claude/skills/playwright-github-actions
ln -s "$(pwd)/test-plan-generator" ~/.claude/skills/test-plan-generator
```

**Project-scoped install** (only inside one target repo):
```bash
mkdir -p /path/to/target-repo/.claude/skills
cp -r playwright-project-setup /path/to/target-repo/.claude/skills/playwright-project-setup
```

## Testing a skill after installing

1. Use a clean, empty test directory for the two setup skills — not an
   existing project with partial state, or you won't be able to tell what
   the skill actually did. `test-plan-generator` is the exception: it needs
   a real repo with real branches/diffs to be meaningful.
2. Open Claude Code and use a natural trigger phrase (not copy-pasted from
   `SKILL.md` — that only proves exact-match works).
3. Inspect the actual generated files, not just whether Claude said it
   succeeded. For `test-plan-generator`, check that the output file has no
   leftover literal `{{...}}` template markers.
4. Deliberately ask for something in the skill's "Out of scope" section
   and confirm it declines/redirects rather than doing it anyway.

## Verifying which skill actually ran

If a skill's behavior doesn't match what you expect, check
`~/.claude/skills/` for name collisions or overlapping trigger phrases
before assuming the `SKILL.md` is wrong — Claude Code picks between
whatever skills are installed and visible, and an unrelated skill with a
similar description can fire instead of the one you meant.

## Status

- `playwright-project-setup` — done, tested against a clean sandbox and a
  real repo (DS-Directory).
- `playwright-github-actions` — done, tested end-to-end in CI against a
  real repo, including a Firebase Emulator-backed test run.
- `test-plan-generator` — built, pending first real-world test run.