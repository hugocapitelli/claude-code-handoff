# Resume Session

Resume work from a previous session using the handoff system.

## Instructions

### Step 1: Discover all handoffs

1. List all `.md` files in `.claude/handoffs/` (root) and `.claude/handoffs/archive/`
2. For each file found, read the first 10 lines to extract: **Active Workstream**, **Last Updated**, and the first line of **What's Next**
3. Skip files that are empty or contain only the default placeholder

### Step 2: Present wizard

Use the AskUserQuestion tool to present available handoffs as options.

Build the options list:
- For each handoff found: add as option with label "[workstream name]" and description showing last updated date + first pending item
- All handoffs are listed equally — no "active" or "archived" distinction in the UI
- If NO handoffs exist at all, skip the wizard and tell the user: "No handoffs found. Use `/save-handoff` at the end of this session to create the first one."

Question: "Which session do you want to resume?"
Header: "Handoff"

### Step 3: Load selected handoff

Once the user selects, read the full handoff file and extract:
- Active Workstream
- Active Agent(s)
- What Was Done (last session summary only)
- What's Next (pending items)
- Key Files (list only — do NOT read the files)
- Decisions Registry (if any)

### Step 4: Present context

```
## Resuming session

**Workstream:** [name]
**Agent(s):** [active agents]
**Last updated:** [date]

### Last session summary
[3-5 lines from What Was Done, focusing on the MOST RECENT session entry]

### Next steps
1. [item from What's Next]
2. [item]
...

What would you like to do?
```

### Step 5: Wait

Wait for user instruction before proceeding.

## Shortcut

If `$ARGUMENTS` is provided (e.g., `/resume auth-refactor`), skip the wizard:
- Search for a `.md` file matching `$ARGUMENTS` in `.claude/handoffs/` and `.claude/handoffs/archive/`
- If still not found, show the wizard with a note: "Handoff '$ARGUMENTS' not found. Choose from available:"

## Important
- Do NOT activate any agent automatically — let the user decide
- Do NOT start working — only present context and wait
- Do NOT read Key Files — just list them. The user can ask to read specific files when needed
- If the handoff references an agent (e.g., @architect), mention it but don't activate
