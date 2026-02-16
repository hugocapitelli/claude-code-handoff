---
paths: **/*
---

# Session Continuity Rules

## Handoff System

This project uses a handoff system for session continuity. Handoff files are stored in `.claude/handoffs/`.

### On Session Start
- If `.claude/handoffs/_active.md` exists and has content, be aware of it but do NOT read it automatically unless the user invokes `/resume` or says "continue"/"resume"

### During Work
- After completing significant milestones (major edits, decisions made, features implemented), proactively update the handoff by writing to `.claude/handoffs/_active.md`
- If the session has been going for a while and substantial work was done, remind the user: "Want me to save the handoff before continuing?"

### Handoff Structure
- `_active.md` — current active workstream (the ONE thing being worked on now)
- `archive/` — paused or completed workstreams (switched via `/switch-context`)

### Commands Available
- `/resume` — resume from active handoff (interactive wizard)
- `/resume <topic>` — resume from a specific archived handoff
- `/save-handoff` — save current state (interactive wizard)
- `/switch-context <topic>` — switch workstream (archives current, loads target)
- `/handoff` — auto-save session state (no wizard, just save and go)
