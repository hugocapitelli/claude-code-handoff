# Context Doctor

Diagnose context usage and recommend optimizations to maximize your usable context window.

## Instructions

### Step 1: Audit always-loaded files

These files are loaded into Claude's context on **every single message**:

1. **CLAUDE.md**: Read `.claude/CLAUDE.md` and count lines
2. **Rules**: List all `.md` files in `.claude/rules/` — for each, count lines and note the filename
3. **Global CLAUDE.md**: Check if the project has a parent CLAUDE.md (from `~/.claude/CLAUDE.md`) — note if it exists

Calculate total "always-on" lines (CLAUDE.md + all rules).

### Step 2: Audit handoff size

1. Read `.claude/handoffs/_active.md` and count lines
2. Count session entries (### Session N patterns)
3. Check if compaction is needed (>3 sessions or >100 lines)

### Step 3: Scan for bloat patterns

Check CLAUDE.md for common bloat patterns:
- Code examples (```...```) — these consume many tokens for little value
- Generic rules that Claude already knows (error handling patterns, "write clean code", "follow best practices")
- Duplicate instructions (same info in CLAUDE.md AND rules/)
- Environment setup / debugging tips
- Long lists of "NEVER do X" (>10 items)

Check rules/ for:
- Files >50 lines (likely too verbose)
- Content that could be a command/skill instead (loaded on-demand)

### Step 4: Present report

```
## Context Health Report

### Always-on context (loaded every message)
| Source | Lines | Est. tokens | Status |
|--------|-------|-------------|--------|
| CLAUDE.md | X | ~Y | [OK/BLOATED] |
| rules/file1.md | X | ~Y | [OK/BLOATED] |
| rules/file2.md | X | ~Y | [OK/BLOATED] |
| **Total** | **X** | **~Y** | — |

### Handoff state
- Active handoff: X lines, N sessions
- [NEEDS COMPACTION / OK]

### Recommendations
[numbered list of specific, actionable recommendations]
```

### Token estimation
Use this rough formula: `tokens ≈ lines × 15` (average for markdown with code).

### Recommendation templates

Use these as appropriate:

1. **"Move rules/X.md to commands/"** — When a rules file is >50 lines and contains reference material (not behavioral rules). Moving to commands/ makes it a skill that's only loaded when invoked.
   - Action: `mv .claude/rules/X.md .claude/commands/X.md` and remove the `paths:` frontmatter

2. **"Trim CLAUDE.md"** — When CLAUDE.md has code examples, generic best practices, or debug tips.
   - Action: Remove generic content. Keep only project-specific rules and critical guardrails.

3. **"Compact handoff"** — When handoff has >3 sessions or >100 lines.
   - Action: Run `/handoff` which will auto-compact, or manually edit `_active.md`.

4. **"Split rules file"** — When a rules file has both behavioral rules AND reference docs.
   - Action: Keep behavioral rules (short, <20 lines) in rules/. Move reference docs to commands/.

5. **"Remove duplicate instructions"** — When the same info appears in CLAUDE.md and rules/.
   - Action: Keep in one place only.

### Step 5: Offer to fix

After presenting the report, ask:

Question: "Want me to apply any of these optimizations?"
Header: "Fix"
Options:
- "Apply all recommendations" — "Automatically fix all issues found"
- "Let me choose" — "I'll tell you which ones to apply"
- "Just the report" — "No changes, I'll handle it manually"

If the user chooses "Apply all" or specific fixes, execute them.

## Important
- This is a READ-ONLY diagnostic by default — only modify files if the user explicitly approves
- Be specific in recommendations — "Remove lines 45-80 from CLAUDE.md (code examples)" not "trim CLAUDE.md"
- Show before/after line counts when making changes
- Never remove content from rules/ without explaining what it does and confirming
