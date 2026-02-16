#!/bin/bash
# claude-code-handoff — Update
# Usage: curl -fsSL https://raw.githubusercontent.com/eximIA-Ventures/claude-code-handoff/main/update.sh | bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

REPO="eximIA-Ventures/claude-code-handoff"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$BRANCH"
PROJECT_DIR="$(pwd)"
CLAUDE_DIR="$PROJECT_DIR/.claude"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  claude-code-handoff — Update v2.1${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Project: ${GREEN}$PROJECT_DIR${NC}"
echo ""

# Check if installed
if [ ! -d "$CLAUDE_DIR/commands" ] || [ ! -f "$CLAUDE_DIR/commands/resume.md" ]; then
  echo -e "  ${RED}claude-code-handoff is not installed in this project.${NC}"
  echo -e "  Run: npx claude-code-handoff"
  exit 1
fi

# Detect if running from cloned repo or via curl
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" 2>/dev/null && pwd 2>/dev/null || echo "")"

download_file() {
  local src="$1"
  local dst="$2"
  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/$src" ]; then
    cp "$SCRIPT_DIR/$src" "$dst"
  else
    curl -fsSL "$RAW_BASE/$src" -o "$dst"
  fi
}

# 1. Update commands
echo -e "  ${YELLOW}[1/6]${NC} Updating commands..."
download_file "commands/handoff.md" "$CLAUDE_DIR/commands/handoff.md"
download_file "commands/resume.md" "$CLAUDE_DIR/commands/resume.md"
download_file "commands/save-handoff.md" "$CLAUDE_DIR/commands/save-handoff.md"
download_file "commands/switch-context.md" "$CLAUDE_DIR/commands/switch-context.md"
download_file "commands/delete-handoff.md" "$CLAUDE_DIR/commands/delete-handoff.md"
download_file "commands/auto-handoff.md" "$CLAUDE_DIR/commands/auto-handoff.md"
download_file "commands/context-doctor.md" "$CLAUDE_DIR/commands/context-doctor.md"

# 2. Update rules
echo -e "  ${YELLOW}[2/6]${NC} Updating rules..."
download_file "rules/session-continuity.md" "$CLAUDE_DIR/rules/session-continuity.md"
download_file "rules/auto-handoff.md" "$CLAUDE_DIR/rules/auto-handoff.md"

# 3. Update hooks (preserving user configuration)
echo -e "  ${YELLOW}[3/6]${NC} Updating hooks..."
mkdir -p "$CLAUDE_DIR/hooks"

# Save user's custom settings before overwriting
SAVED_THRESHOLD=""
SAVED_MAX_CONTEXT=""
if [ -f "$CLAUDE_DIR/hooks/context-monitor.sh" ]; then
  SAVED_THRESHOLD=$(grep -oP 'CLAUDE_CONTEXT_THRESHOLD:-\K[0-9]+' "$CLAUDE_DIR/hooks/context-monitor.sh" 2>/dev/null || echo "")
  SAVED_MAX_CONTEXT=$(grep -oP 'CLAUDE_MAX_CONTEXT:-\K[0-9]+' "$CLAUDE_DIR/hooks/context-monitor.sh" 2>/dev/null || echo "")
fi

download_file "hooks/context-monitor.sh" "$CLAUDE_DIR/hooks/context-monitor.sh"
download_file "hooks/session-cleanup.sh" "$CLAUDE_DIR/hooks/session-cleanup.sh"
chmod +x "$CLAUDE_DIR/hooks/context-monitor.sh"
chmod +x "$CLAUDE_DIR/hooks/session-cleanup.sh"

# Restore user's custom settings
if [ -n "$SAVED_THRESHOLD" ] && [ "$SAVED_THRESHOLD" != "80" ]; then
  sed -i.bak "s/CLAUDE_CONTEXT_THRESHOLD:-80/CLAUDE_CONTEXT_THRESHOLD:-${SAVED_THRESHOLD}/" "$CLAUDE_DIR/hooks/context-monitor.sh"
  rm -f "$CLAUDE_DIR/hooks/context-monitor.sh.bak"
  echo -e "    Preserved threshold: ${CYAN}${SAVED_THRESHOLD}%${NC}"
fi
if [ -n "$SAVED_MAX_CONTEXT" ] && [ "$SAVED_MAX_CONTEXT" != "200000" ]; then
  sed -i.bak "s/CLAUDE_MAX_CONTEXT:-200000/CLAUDE_MAX_CONTEXT:-${SAVED_MAX_CONTEXT}/" "$CLAUDE_DIR/hooks/context-monitor.sh"
  rm -f "$CLAUDE_DIR/hooks/context-monitor.sh.bak"
  echo -e "    Preserved max context: ${CYAN}${SAVED_MAX_CONTEXT} tokens${NC}"
fi

# 4. Ensure hooks are configured in settings.json
echo -e "  ${YELLOW}[4/6]${NC} Checking settings.json hooks..."
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
  if ! grep -q "context-monitor" "$SETTINGS_FILE" 2>/dev/null; then
    if command -v jq &>/dev/null; then
      HOOKS_JSON='{"Stop":[{"hooks":[{"type":"command","command":"\"$CLAUDE_PROJECT_DIR/.claude/hooks/context-monitor.sh\"","timeout":10}]}],"SessionStart":[{"hooks":[{"type":"command","command":"\"$CLAUDE_PROJECT_DIR/.claude/hooks/session-cleanup.sh\"","timeout":5}]}]}'
      jq --argjson hooks "$HOOKS_JSON" '. + {hooks: $hooks}' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
      echo -e "    Hooks added to settings.json"
    else
      echo -e "    ${YELLOW}⚠ jq not found — add hooks to .claude/settings.json manually${NC}"
    fi
  else
    echo -e "    Hooks already configured"
  fi
else
  echo -e "    ${YELLOW}⚠ settings.json not found — run install first${NC}"
fi

# 5. Migrate CLAUDE.md (v2.1: remove mandatory read, slim down)
echo -e "  ${YELLOW}[5/6]${NC} Migrating CLAUDE.md..."
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
MIGRATED=false
if [ -f "$CLAUDE_MD" ]; then
  # Replace old verbose section with lean version
  if grep -q "At the START of every session, read" "$CLAUDE_MD" 2>/dev/null; then
    TEMP_FILE=$(mktemp)
    awk '
      /## Session Continuity/ {
        print "## Session Continuity"
        print ""
        print "Use `/resume` to pick up from a previous session. Use `/handoff` before `/clear` to save."
        skip=1
        next
      }
      skip && /^## / && !/Session Continuity/ {
        skip=0
      }
      skip { next }
      { print }
    ' "$CLAUDE_MD" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$CLAUDE_MD"
    MIGRATED=true
    echo -e "    ${GREEN}Migrated: removed auto-read rule (saves ~3K tokens/message)${NC}"
  else
    echo -e "    Already up to date"
  fi
fi

# 6. Remove legacy files if present
echo -e "  ${YELLOW}[6/6]${NC} Cleaning up legacy files..."
CLEANED=0
for f in retomar.md salvar-handoff.md trocar-contexto.md auto-handoff-toggle.md; do
  if [ -f "$CLAUDE_DIR/commands/$f" ]; then
    rm -f "$CLAUDE_DIR/commands/$f"
    CLEANED=$((CLEANED + 1))
  fi
done

echo ""
echo -e "${GREEN}  Updated successfully!${NC}"
if [ "$CLEANED" -gt 0 ]; then
  echo -e "  Removed $CLEANED legacy command(s)"
fi
if [ "$MIGRATED" = true ]; then
  echo -e "  ${CYAN}CLAUDE.md migrated to lean format (context optimization)${NC}"
fi
echo ""
echo -e "  Handoff data in .claude/handoffs/ was ${CYAN}not touched${NC}."
echo -e "  Auto-handoff settings (threshold, plan, on/off) were ${CYAN}preserved${NC}."
echo -e "  ${CYAN}New:${NC} /context-doctor — diagnose context bloat"
echo ""
