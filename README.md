# playwright-foundation

A personal library of [Claude Skills](https://docs.claude.com/en/docs/claude-code/skills)
for Playwright test automation. Each skill scaffolds one piece of a Playwright
testing setup, so new projects start from a consistent baseline instead of
rebuilding the same boilerplate every time.

## Skills in this repo

| Skill | Does | Does NOT do |
|---|---|---|
| `playwright-project-setup` | Installs Playwright + dependencies, creates folder structure, `playwright.config.js`, ESLint/Prettier, dotenv, generic placeholder tests | Explore any target app, write real selectors/tests, decide on auth or environments |
| `playwright-github-actions` | Scaffolds `.github/workflows/playwright.yml` (UI + API jobs, runs on push/PR) | Anything beyond CI config — requires `playwright-project-setup` to have run first |

These are deliberately narrow. Test authoring, auth/login discovery, and
environment architecture are **not** covered by either skill in this repo —
if you build a skill for that later, give it its own name and its own
explicit scope, and update this table.

## Layout convention

Every skill lives in its own top-level folder, named after the skill:

\```
<skill-name>/
├── SKILL.md      # required: frontmatter (name, description) + instructions
├── scripts/      # executable scripts the skill runs
└── assets/       # template files the skill copies into a target project
\```

`SKILL.md`'s frontmatter `description` is what Claude Code uses to decide
when to trigger the skill — it should list concrete trigger phrases, not
just a vague summary.

## Installing a skill

**Skills directory:** Claude Code reads skills from `~/.claude/skills/`
(global) or `<project>/.claude/skills/` (project-scoped, that project only).
If you use other agent tools that read from a different path (e.g.
`~/.agents/skills/`), install there separately and explicitly — don't assume
one install covers both. Check `ls ~/.claude/skills/` after installing to
confirm.

**Global install** (available in every project):
\```bash
cp -r playwright-project-setup ~/.claude/skills/playwright-project-setup
cp -r playwright-github-actions ~/.claude/skills/playwright-github-actions
\```

**Project-scoped install** (only inside one target repo):
\```bash
mkdir -p /path/to/target-repo/.claude/skills
cp -r playwright-project-setup /path/to/target-repo/.claude/skills/playwright-project-setup
\```

Symlink instead of `cp -r` if you want edits to this source repo to apply
immediately everywhere without reinstalling:
\```bash
ln -s "$(pwd)/playwright-project-setup" ~/.claude/skills/playwright-project-setup
\```

## Testing a skill after installing

1. Use a clean, empty test directory — not an existing project with partial
   state, or you won't be able to tell what the skill actually did.
2. Open Claude Code in that directory and use a natural trigger phrase
   (not copy-pasted from `SKILL.md` — that only proves exact-match works).
3. Inspect the actual generated files, not just whether Claude said it
   succeeded.
4. Deliberately ask for something in the skill's "Out of scope" section
   and confirm it declines/redirects rather than doing it anyway.

## Verifying which skill actually ran

If a skill's behavior doesn't match what you expect, check
`~/.claude/skills/` for name collisions or overlapping trigger phrases
before assuming the `SKILL.md` is wrong — Claude Code picks between
whatever skills are installed and visible, and an unrelated skill with a
similar description can fire instead of the one you meant.

## Status

- `playwright-project-setup` — done, tested against a clean sandbox.
- `playwright-github-actions` — done, tested against a clean sandbox.