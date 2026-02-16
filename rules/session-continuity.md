---
paths: **/*
---

# Session Continuity

This project uses `.claude/handoffs/` for session continuity across `/clear`.

- Do NOT read `_active.md` automatically — wait for `/resume` or user saying "continue"/"resume"
- After significant milestones, remind: "Want me to save the handoff?"
- Commands: `/resume`, `/handoff`, `/save-handoff`, `/switch-context`, `/delete-handoff`, `/auto-handoff`
