# Resume Session

Resume work from a previous session using the handoff system.

## Instructions

### Step 1: Discover all handoffs

1. Check if `.claude/handoffs/_active.md` exists and has content (not the default placeholder)
2. List all `.md` files in `.claude/handoffs/archive/`
3. For each file found, read the first 10 lines to extract: **Active Workstream**, **Last Updated**, and the first line of **What's Next**

### Step 2: Present wizard

Use the AskUserQuestion tool to present available handoffs as options.

Build the options list:
- If `_active.md` has content: add it as first option with label "(active) [workstream name]" and description showing last updated date + first pending item
- For each file in `archive/`: add as option with label "[workstream name]" and description showing last updated date + first pending item
- If NO handoffs exist at all, skip the wizard and tell the user: "No handoffs found. Use `/save-handoff` at the end of this session to create the first one."

Question: "Which session do you want to resume?"
Header: "Handoff"

### Step 3: Load selected handoff

Once the user selects, read the full handoff file and extract:
- Active Workstream
- Active Agent(s)
- What Was Done (last session summary)
- What's Next (pending items)
- Key Files
- Decisions Registry (if any)

### Step 4: Refresh context

If **Key Files** lists a main document (Current Document field), read the first 50 lines of it.

### Step 5: Present context

```
## Resuming session

**Workstream:** [name]
**Agent(s):** [active agents]
**Document:** [main file]
**Last updated:** [date]

### Last session summary
[3-5 lines from What Was Done, focusing on the MOST RECENT session entry]

### Next steps
1. [item from What's Next]
2. [item]
...

What would you like to do?
```

### Step 6: Wait

Wait for user instruction before proceeding.

## Shortcut

If `$ARGUMENTS` is provided (e.g., `/resume auth-refactor`), skip the wizard:
- Look for `.claude/handoffs/archive/$ARGUMENTS.md` first
- If not found, check if `_active.md` workstream slug matches `$ARGUMENTS`
- If still not found, show the wizard with a note: "Handoff '$ARGUMENTS' not found. Choose from available:"

## Important
- Do NOT activate any agent automatically — let the user decide
- Do NOT start working — only present context and wait
- If the handoff references an agent (e.g., @architect), mention it but don't activate
- The wizard should clearly show which is the ACTIVE handoff vs archived ones
