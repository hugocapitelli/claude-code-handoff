# Save Handoff

Save the current session state for future resumption.

## Instructions

### Step 1: Analyze current session

Before showing the wizard, analyze the current conversation and extract:
- **Workstream name**: What project/feature/epic is being worked on
- **Active Agent(s)**: Which agent personas are active
- **What Was Done**: Concrete actions completed THIS session
- **What's Next**: Specific pending items
- **Key Files**: Files created, modified, or essential to read when resuming
- **Decisions Registry**: Any decisions made with IDs

### Step 2: Present wizard

Use the AskUserQuestion tool to ask where to save.

**Discover existing handoffs first:**
1. Check if `.claude/handoffs/_active.md` exists and extract its workstream name
2. List files in `.claude/handoffs/archive/` to show existing contexts

**Present options:**

Question: "Where should this session's handoff be saved?"
Header: "Target"

Options (build dynamically):
1. **Label:** "Update active ([workstream name])" — **Description:** "Append this session to the current active handoff. Use when working on the same context."
2. **Label:** "Save as new context" — **Description:** "Create a separate handoff. Use when working on something different from the active context."
3. **Label:** "Replace active" — **Description:** "Discard the active handoff and create a new one with this session. Use when the active context is obsolete."

If `_active.md` does NOT exist or is the default placeholder, show only:
1. **Label:** "Create handoff" — **Description:** "Create the first handoff for this project."
2. **Label:** "Create with specific name" — **Description:** "Create handoff with a custom name to organize by topic."

### Step 3: Execute based on choice

#### Choice: "Update active"
1. Read `.claude/handoffs/_active.md`
2. Append new session entry to "What Was Done" (preserve history)
3. Update "What's Next", "Key Files", "Decisions Registry", "Last Updated"
4. Write back to `.claude/handoffs/_active.md`

#### Choice: "Save as new context"
1. Ask the user for a name using AskUserQuestion:
   - Question: "Context name (will be the filename)?"
   - Header: "Name"
   - Options: suggest 2-3 slugs based on what was discussed (e.g., "auth-refactor", "bugfix-login"), plus "Other" for custom input
2. If `_active.md` has content, move it to `archive/{current-slug}.md` first
3. Create new `.claude/handoffs/_active.md` with this session's data
4. Also save a copy to `archive/{chosen-name}.md`

#### Choice: "Replace active"
1. If `_active.md` has content, move it to `archive/{current-slug}.md` (never lose data)
2. Create fresh `.claude/handoffs/_active.md` with only this session's data

#### Choice: "Create handoff" (first time)
1. Create `.claude/handoffs/_active.md` with this session's data

#### Choice: "Create with specific name" (first time)
1. Ask for name (same as "Save as new context")
2. Create `.claude/handoffs/_active.md` with this session's data
3. Also save copy to `archive/{chosen-name}.md`

### Step 4: Write the handoff

Use this structure for the handoff content:

```markdown
# Session Handoff

> Updated automatically. Read this to resume work after /clear.

## Last Updated
[current date and brief description]

## Active Workstream
[workstream name and brief context]

## Active Agent(s)
[agent names and roles]

## Current Document
[main file being worked on, if any]

## What Was Done

### Session [N] ([date])
[bullet points of concrete actions — be specific, not vague]

### Session [N-1] ([date])
[preserve previous sessions — don't delete history]

## What's Next
1. [specific actionable item]
2. [specific actionable item]
...

## Key Files
| File | Purpose |
|------|---------|
| path/to/file | what it is |

## Decisions Registry
| # | Decision | Choice | Justification |
|---|----------|--------|---------------|
| D1 | ... | ... | ... |
```

### Step 5: Confirm

```
Handoff saved to [path]
- [1-line summary of what was recorded]
- Next steps: [count] pending items
- Available contexts: [list of all handoff names]
```

## Shortcut

If `$ARGUMENTS` is provided:
- If it matches an existing archive name: update that specific archive file directly (skip wizard)
- Otherwise: treat as the name for a new context (skip wizard, go to "Save as new context" flow)

## Important
- NEVER delete or overwrite without archiving first — always move to archive/
- PRESERVE session history — append, don't replace
- Be PRECISE — file paths, decision IDs, specific changes
- Be ACTIONABLE — someone reading cold should know exactly what to do
- Keep CONCISE — target <200 lines per handoff
- If a handoff exceeds 300 lines, summarize older sessions into "Prior Sessions Summary"
- Slug derivation: lowercase, trim, replace spaces/special chars with hyphens, max 40 chars
