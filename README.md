# playwright-foundation

A personal library of [Claude Skills](https://docs.claude.com/en/docs/claude-code/skills) for Playwright
test automation. Each skill scaffolds or automates a piece of a Playwright testing setup, so new projects
can be bootstrapped consistently instead of rebuilding the same boilerplate every time.

## Layout convention

Every skill lives in its own top-level folder, named after the skill, with the same internal anatomy:

```
<skill-name>/
├── SKILL.md            # required: frontmatter (name, description) + instructions for Claude
├── scripts/             # optional: executable scripts the skill runs (e.g. a scaffold script)
└── assets/               # optional: template files the skill copies into a target project
```

- `SKILL.md` is the entry point — its frontmatter `description` is what tells Claude Code when to
  trigger the skill, and the body is the instructions Claude follows when it does.
- `scripts/` holds anything the skill executes directly (shell scripts, codegen, etc.).
- `assets/` holds static templates/config files the skill copies as-is (or with light templating)
  into whatever project it's scaffolding.

## Skills in this repo

- **`playwright-project-setup`** — scaffolds a JavaScript Playwright project preconfigured for both
  UI and API testing (Page Object Model, `tests/ui/` + `tests/api/`, ESLint + Prettier, dotenv).
- **`playwright-github-actions`** — scaffolds a GitHub Actions workflow to run the
  tests produced by `playwright-project-setup`.

## Installing a skill from this repo

Skills can be used either globally (available in every Claude Code session) or scoped to a single
project.

**Global install** — copy or symlink the skill folder into `~/.claude/skills/`:

```bash
cp -r playwright-project-setup ~/.claude/skills/playwright-project-setup
# or, to track changes back to this repo:
ln -s "$(pwd)/playwright-project-setup" ~/.claude/skills/playwright-project-setup
```

**Project-scoped install** — copy or symlink it into `.claude/skills/` inside the target repo:

```bash
mkdir -p /path/to/target-repo/.claude/skills
cp -r playwright-project-setup /path/to/target-repo/.claude/skills/playwright-project-setup
```

Claude Code picks up skills from both locations automatically; project-scoped skills only apply
when working inside that project.
