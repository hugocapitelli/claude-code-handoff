#!/bin/bash
# claude-code-handoff — Session continuity for Claude Code
# Install: curl -fsSL https://raw.githubusercontent.com/eximIA-Ventures/claude-code-handoff/main/install.sh | bash
#
# Or clone and run:
#   git clone https://github.com/eximIA-Ventures/claude-code-handoff.git /tmp/claude-code-handoff
#   cd /your/project && /tmp/claude-code-handoff/install.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO="eximIA-Ventures/claude-code-handoff"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$BRANCH"
PROJECT_DIR="$(pwd)"
CLAUDE_DIR="$PROJECT_DIR/.claude"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  claude-code-handoff — Session Continuity${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Project: ${GREEN}$PROJECT_DIR${NC}"
echo ""

# Detect if running from cloned repo or via curl
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" 2>/dev/null && pwd 2>/dev/null || echo "")"

download_file() {
  local src="$1"
  local dst="$2"

  # If running from cloned repo, copy locally
  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/$src" ]; then
    cp "$SCRIPT_DIR/$src" "$dst"
  else
    # Download from GitHub
    curl -fsSL "$RAW_BASE/$src" -o "$dst"
  fi
}

# 1. Create directories
echo -e "  ${YELLOW}[1/7]${NC} Creating directories..."
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/rules"
mkdir -p "$CLAUDE_DIR/handoffs/archive"

# 2. Download/copy commands
echo -e "  ${YELLOW}[2/7]${NC} Installing commands..."
download_file "commands/resume.md" "$CLAUDE_DIR/commands/resume.md"
download_file "commands/save-handoff.md" "$CLAUDE_DIR/commands/save-handoff.md"
download_file "commands/switch-context.md" "$CLAUDE_DIR/commands/switch-context.md"
download_file "commands/handoff.md" "$CLAUDE_DIR/commands/handoff.md"

# 3. Download/copy rules
echo -e "  ${YELLOW}[3/7]${NC} Installing rules..."
download_file "rules/session-continuity.md" "$CLAUDE_DIR/rules/session-continuity.md"

# 4. Create initial _active.md if not exists
if [ ! -f "$CLAUDE_DIR/handoffs/_active.md" ]; then
  echo -e "  ${YELLOW}[4/7]${NC} Creating initial handoff..."
  cat > "$CLAUDE_DIR/handoffs/_active.md" << 'HANDOFF'
# Session Handoff

> No active session yet. Use `/handoff` or `/save-handoff` to save your first session state.

## Last Updated
(not started)

## Active Workstream
(none)

## Active Agent(s)
(none)

## What Was Done
(nothing yet)

## What's Next
(define your first task)

## Key Files
(none)

## Decisions Registry
(none)
HANDOFF
else
  echo -e "  ${YELLOW}[4/7]${NC} Handoff already exists, keeping it"
fi

# 5. Add to .gitignore
echo -e "  ${YELLOW}[5/7]${NC} Updating .gitignore..."
GITIGNORE="$PROJECT_DIR/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! grep -q ".claude/handoffs/" "$GITIGNORE" 2>/dev/null; then
    echo "" >> "$GITIGNORE"
    echo "# claude-code-handoff (personal session state)" >> "$GITIGNORE"
    echo ".claude/handoffs/" >> "$GITIGNORE"
  fi
else
  echo "# claude-code-handoff (personal session state)" > "$GITIGNORE"
  echo ".claude/handoffs/" >> "$GITIGNORE"
fi

# 6. Add to CLAUDE.md
echo -e "  ${YELLOW}[6/7]${NC} Updating CLAUDE.md..."
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
CONTINUITY_BLOCK='## Session Continuity (MANDATORY)

At the START of every session, read `.claude/handoffs/_active.md` to recover context from prior sessions.
During work, update the handoff proactively after significant milestones.
Use `/handoff` before `/clear`. Use `/resume` to pick up. Use `/switch-context <topic>` to switch workstreams.'

if [ -f "$CLAUDE_MD" ]; then
  if ! grep -q "Session Continuity" "$CLAUDE_MD" 2>/dev/null; then
    TEMP_FILE=$(mktemp)
    awk '
      /^# / && !done {
        print
        print ""
        print "## Session Continuity (MANDATORY)"
        print ""
        print "At the START of every session, read `.claude/handoffs/_active.md` to recover context from prior sessions."
        print "During work, update the handoff proactively after significant milestones."
        print "Use `/handoff` before `/clear`. Use `/resume` to pick up. Use `/switch-context <topic>` to switch workstreams."
        print ""
        done=1
        next
      }
      { print }
    ' "$CLAUDE_MD" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$CLAUDE_MD"
  fi
else
  cat > "$CLAUDE_MD" << 'CLAUDEMD'
# Project Rules

## Session Continuity (MANDATORY)

At the START of every session, read `.claude/handoffs/_active.md` to recover context from prior sessions.
During work, update the handoff proactively after significant milestones.
Use `/handoff` before `/clear`. Use `/resume` to pick up. Use `/switch-context <topic>` to switch workstreams.
CLAUDEMD
fi

# 7. Summary
echo -e "  ${YELLOW}[7/7]${NC} Verifying installation..."
INSTALLED=0
for f in resume.md save-handoff.md switch-context.md handoff.md; do
  [ -f "$CLAUDE_DIR/commands/$f" ] && INSTALLED=$((INSTALLED + 1))
done

echo ""
if [ "$INSTALLED" -eq 4 ]; then
  echo -e "${GREEN}  Installed successfully! ($INSTALLED/4 commands)${NC}"
else
  echo -e "${YELLOW}  Partial install: $INSTALLED/4 commands${NC}"
fi
echo ""
echo -e "  Commands available:"
echo -e "    ${CYAN}/handoff${NC}              Auto-save session (no wizard)"
echo -e "    ${CYAN}/resume${NC}               Resume with wizard"
echo -e "    ${CYAN}/save-handoff${NC}         Save session state (wizard)"
echo -e "    ${CYAN}/switch-context${NC}       Switch workstream"
echo ""
echo -e "  Files:"
echo -e "    .claude/commands/     4 command files"
echo -e "    .claude/rules/        session-continuity.md"
echo -e "    .claude/handoffs/     session state (gitignored)"
echo ""
echo -e "  ${YELLOW}Start Claude Code and use /resume to begin.${NC}"
echo ""
