#!/bin/bash
# claude-code-handoff — Uninstall
# Usage: curl -fsSL https://raw.githubusercontent.com/eximIA-Ventures/claude-code-handoff/main/uninstall.sh | bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_DIR="$(pwd)"
CLAUDE_DIR="$PROJECT_DIR/.claude"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  claude-code-handoff — Uninstall${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Project: ${GREEN}$PROJECT_DIR${NC}"
echo ""

if [ ! -d "$CLAUDE_DIR" ]; then
  echo -e "  ${RED}No .claude/ directory found. Nothing to uninstall.${NC}"
  exit 0
fi

# 1. Remove commands
echo -e "  ${YELLOW}[1/4]${NC} Removing commands..."
rm -f "$CLAUDE_DIR/commands/handoff.md"
rm -f "$CLAUDE_DIR/commands/resume.md"
rm -f "$CLAUDE_DIR/commands/save-handoff.md"
rm -f "$CLAUDE_DIR/commands/switch-context.md"
# Also remove legacy Portuguese commands if present
rm -f "$CLAUDE_DIR/commands/retomar.md"
rm -f "$CLAUDE_DIR/commands/salvar-handoff.md"
rm -f "$CLAUDE_DIR/commands/trocar-contexto.md"

# 2. Remove rules
echo -e "  ${YELLOW}[2/4]${NC} Removing rules..."
rm -f "$CLAUDE_DIR/rules/session-continuity.md"

# 3. Remove handoffs (with confirmation)
if [ -d "$CLAUDE_DIR/handoffs" ]; then
  # Check if there's actual content
  ACTIVE_CONTENT=$(cat "$CLAUDE_DIR/handoffs/_active.md" 2>/dev/null || echo "")
  if echo "$ACTIVE_CONTENT" | grep -q "No active session yet\|not started"; then
    echo -e "  ${YELLOW}[3/4]${NC} Removing handoffs (no session data)..."
    rm -rf "$CLAUDE_DIR/handoffs"
  else
    echo -e "  ${YELLOW}[3/4]${NC} ${RED}Handoffs contain session data!${NC}"
    echo -e "        Kept: .claude/handoffs/"
    echo -e "        Remove manually with: rm -rf .claude/handoffs/"
  fi
else
  echo -e "  ${YELLOW}[3/4]${NC} No handoffs directory found"
fi

# 4. Clean .gitignore
echo -e "  ${YELLOW}[4/4]${NC} Cleaning .gitignore..."
GITIGNORE="$PROJECT_DIR/.gitignore"
if [ -f "$GITIGNORE" ]; then
  # Remove the handoff lines
  sed -i.bak '/# claude-code-handoff/d; /^\.claude\/handoffs\/$/d' "$GITIGNORE"
  rm -f "$GITIGNORE.bak"
  # Remove trailing blank lines
  sed -i.bak -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$GITIGNORE"
  rm -f "$GITIGNORE.bak"
fi

# Clean up empty directories
rmdir "$CLAUDE_DIR/commands" 2>/dev/null || true
rmdir "$CLAUDE_DIR/rules" 2>/dev/null || true
rmdir "$CLAUDE_DIR" 2>/dev/null || true

echo ""
echo -e "${GREEN}  Uninstalled successfully!${NC}"
echo ""
echo -e "  Note: Session Continuity section in CLAUDE.md was NOT removed."
echo -e "  Edit .claude/CLAUDE.md manually if you want to remove it."
echo ""
