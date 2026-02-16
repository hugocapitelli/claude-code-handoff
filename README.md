# claude-code-handoff

Session continuity for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Pick up exactly where you left off — across `/clear`, crashes, or context switches.

## What it does

Adds 4 slash commands to any Claude Code project:

| Command | Description |
|---------|-------------|
| `/handoff` | Auto-save session state (no wizard, just save and go) |
| `/resume` | Resume from a saved session (interactive wizard) |
| `/save-handoff` | Save session state with options (interactive wizard) |
| `/switch-context <topic>` | Switch between parallel workstreams |

Session state is stored in `.claude/handoffs/` (gitignored by default) so each developer keeps their own context.

## Install

### Option A: npx (recommended)

```bash
cd your-project
npx claude-code-handoff
```

### Option B: curl

```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/hugocapitelli/claude-code-handoff/main/install.sh | bash
```

### Option C: clone & run

```bash
git clone https://github.com/hugocapitelli/claude-code-handoff.git /tmp/claude-code-handoff
cd your-project
/tmp/claude-code-handoff/install.sh
```

## What gets installed

```
your-project/
└── .claude/
    ├── commands/
    │   ├── handoff.md            # /handoff command (auto-save)
    │   ├── resume.md             # /resume command
    │   ├── save-handoff.md       # /save-handoff command
    │   └── switch-context.md     # /switch-context command
    ├── rules/
    │   └── session-continuity.md # Auto-loaded rules for Claude
    └── handoffs/                 # Session state (gitignored)
        ├── _active.md            # Current workstream
        └── archive/              # Paused workstreams
```

The installer also:
- Adds `.claude/handoffs/` to `.gitignore`
- Adds a `Session Continuity` section to `.claude/CLAUDE.md` (creates one if missing)

## Usage

### Quick save before clearing

```
> /handoff
# Claude auto-saves current context to .claude/handoffs/_active.md
> /clear
```

### Save with options

```
> /save-handoff
# Interactive wizard: update active, save as new context, or replace
```

### Resume next session

```
> /resume
# Interactive wizard shows available sessions
# Select one → Claude loads full context and shows next steps
```

### Switch workstreams

```
> /switch-context auth-refactor
# Archives current session, loads auth-refactor context
```

## How it works

The handoff file (`.claude/handoffs/_active.md`) captures:

- **Active Workstream** — what you're working on
- **Active Agent(s)** — which agents/personas are active
- **What Was Done** — session-by-session log of completed work
- **What's Next** — prioritized pending items
- **Key Files** — important files for context reload
- **Decisions Registry** — architectural decisions made

When you `/resume`, Claude reads this file and presents a summary so you can continue exactly where you left off.

The `_active.md` file acts like `HEAD` in git — it points to your current workstream. The `archive/` folder holds paused workstreams you can switch to anytime with `/switch-context`.

## Uninstall

```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/hugocapitelli/claude-code-handoff/main/uninstall.sh | bash
```

Or manually remove:
```bash
rm -rf .claude/commands/handoff.md .claude/commands/resume.md .claude/commands/save-handoff.md .claude/commands/switch-context.md
rm -rf .claude/rules/session-continuity.md
rm -rf .claude/handoffs/
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- A project directory with (or without) an existing `.claude/` folder

## License

MIT
