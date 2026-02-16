# Auto Handoff

Automatically save session state and prepare for context clear. No wizard — just save and go.

## Instructions

### Step 1: Analyze conversation

Scan the full conversation and extract:
- **Workstream name**: The project/feature/topic being worked on
- **Active Agent(s)**: Any agent personas active (e.g., @dev, @architect) or "none"
- **What Was Done**: All concrete actions completed THIS session (files created/modified, decisions made, features implemented, bugs fixed)
- **What's Next**: Unfinished work, pending items, logical next steps
- **Key Files**: Every file that was created, modified, or is essential to resume
- **Current Document**: The main file being worked on (if any)
- **Decisions**: Any architectural or design decisions made

Be thorough — this is the only record of the session.

### Step 2: Determine save target

1. Read `.claude/handoffs/_active.md` (if it exists)
2. Check if it has real content (not the default placeholder)

**If active handoff exists with content:**
- Compare the active workstream name with what was worked on this session
- If same workstream: **append** to existing handoff (preserve session history)
- If different workstream: **archive** the old one, create new active

**If no active handoff or placeholder only:**
- Create new active handoff

**If `$ARGUMENTS` is provided:**
- Use it as the workstream name/slug
- Save directly without comparison logic

### Step 3: Write the handoff

Ensure `.claude/handoffs/` and `.claude/handoffs/archive/` directories exist.

**When appending** to an existing handoff:
1. Read the current `_active.md`
2. Add a new session entry under "## What Was Done" with current date
3. Update "## What's Next" (replace with current pending items)
4. Merge new files into "## Key Files" (don't duplicate)
5. Append any new decisions to "## Decisions Registry"
6. Update "## Last Updated"

**When creating fresh:**
Write `.claude/handoffs/_active.md` with this template:

```markdown
# Session Handoff

> Updated automatically. Read this to resume work after /clear.

## Last Updated
[YYYY-MM-DD HH:MM] — [brief description of session]

## Active Workstream
**[workstream name]** — [one-line description]

## Active Agent(s)
[agents or "none"]

## Current Document
[main file path or "none"]

## What Was Done

### Session 1 ([YYYY-MM-DD HH:MM])
- [concrete action 1]
- [concrete action 2]
- ...

## What's Next
1. [specific actionable item]
2. [specific actionable item]
...

## Key Files
| File | Purpose |
|------|---------|
| path/to/file | what it does |

## Decisions Registry
[decisions table or "(none)"]
```

### Step 4: Confirm and instruct

Output exactly this:

```
## Handoff saved

**Workstream:** [name]
**File:** `.claude/handoffs/_active.md`
**Recorded:** [count] actions done, [count] next steps

You can now type `/clear` to free context.
Then start a new session and use `/resume` to pick up where you left off.
```

## Design Rationale

This command exists because:
1. **No wizard friction** — `/save-handoff` has a wizard for choosing where to save. `/handoff` just saves and goes.
2. **Context-aware** — it appends to the active handoff if the workstream matches, or creates a new one if it doesn't.
3. **Pre-clear workflow** — the natural flow is: work → `/handoff` → `/clear` → `/resume`.

## Compaction Rule

When a handoff exceeds 3 session entries in "What Was Done":
1. Keep the **last 3 sessions** in full detail
2. Merge all older sessions into a single **"Prior Sessions Summary (1-N)"** section with 1-2 bullet points each
3. Example:
```markdown
### Prior Sessions Summary (1-5)
- Sessions 1-2: Initial setup, D1-D4 decided
- Session 3: Refactored auth module
- Sessions 4-5: API integration, E2E tests added
```
4. Target: keep the entire handoff under **100 lines**
5. The Decisions Registry is NEVER compacted — all decisions are preserved

## Important
- Be THOROUGH — extract everything relevant from the conversation
- Be PRECISE — file paths, specific changes, exact error messages
- Be ACTIONABLE — next steps should be specific enough to execute cold
- NEVER delete existing handoff data — always append or archive
- Keep under 100 lines — compact older sessions aggressively
- If conversation is very short or trivial, still save (even a one-liner is better than nothing)
