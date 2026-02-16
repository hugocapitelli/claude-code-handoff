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
echo -e "  ${YELLOW}[1/10]${NC} Creating directories..."
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/rules"
mkdir -p "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/handoffs/archive"

# 2. Download/copy commands
echo -e "  ${YELLOW}[2/10]${NC} Installing commands..."
download_file "commands/resume.md" "$CLAUDE_DIR/commands/resume.md"
download_file "commands/save-handoff.md" "$CLAUDE_DIR/commands/save-handoff.md"
download_file "commands/switch-context.md" "$CLAUDE_DIR/commands/switch-context.md"
download_file "commands/handoff.md" "$CLAUDE_DIR/commands/handoff.md"
download_file "commands/delete-handoff.md" "$CLAUDE_DIR/commands/delete-handoff.md"
download_file "commands/auto-handoff.md" "$CLAUDE_DIR/commands/auto-handoff.md"

# 3. Download/copy rules
echo -e "  ${YELLOW}[3/10]${NC} Installing rules..."
download_file "rules/session-continuity.md" "$CLAUDE_DIR/rules/session-continuity.md"
download_file "rules/auto-handoff.md" "$CLAUDE_DIR/rules/auto-handoff.md"

# 4. Install hooks (auto-handoff context monitor)
echo -e "  ${YELLOW}[4/10]${NC} Installing hooks..."
download_file "hooks/context-monitor.sh" "$CLAUDE_DIR/hooks/context-monitor.sh"
download_file "hooks/session-cleanup.sh" "$CLAUDE_DIR/hooks/session-cleanup.sh"
chmod +x "$CLAUDE_DIR/hooks/context-monitor.sh"
chmod +x "$CLAUDE_DIR/hooks/session-cleanup.sh"
# Auto-handoff disabled by default (beta feature)
touch "$CLAUDE_DIR/hooks/.auto-handoff-disabled"

# 5. Configure hooks in settings.json
echo -e "  ${YELLOW}[5/10]${NC} Configuring hooks in settings.json..."
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
  # Check if hooks already configured
  if ! grep -q "context-monitor" "$SETTINGS_FILE" 2>/dev/null; then
    # Merge hooks into existing settings.json using jq if available
    if command -v jq &>/dev/null; then
      HOOKS_JSON='{
        "hooks": {
          "Stop": [{"hooks": [{"type": "command", "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/context-monitor.sh\"", "timeout": 10}]}],
          "SessionStart": [{"hooks": [{"type": "command", "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/session-cleanup.sh\"", "timeout": 5}]}]
        }
      }'
      jq --argjson hooks "$(echo "$HOOKS_JSON" | jq '.hooks')" '. + {hooks: $hooks}' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
    else
      # Fallback: rewrite settings.json preserving existing keys
      echo -e "  ${YELLOW}  ⚠ jq not found. Adding hooks config manually...${NC}"
      # Read existing content, strip trailing brace, append hooks
      EXISTING=$(cat "$SETTINGS_FILE")
      # Remove trailing } and whitespace
      EXISTING=$(echo "$EXISTING" | sed '$ s/}$//')
      cat > "$SETTINGS_FILE" << 'SETTINGSEOF'
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/context-monitor.sh\"",
            "timeout": 10
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/session-cleanup.sh\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
SETTINGSEOF
      # Merge with original using jq-less approach: just add hooks key
      # Since we can't reliably merge JSON without jq, write a complete file
      # preserving the language setting if it exists
      LANG_SETTING=$(echo "$EXISTING" | grep '"language"' | head -1 | sed 's/,$//')
      if [ -n "$LANG_SETTING" ]; then
        cat > "$SETTINGS_FILE" << SETTINGSEOF
{
  ${LANG_SETTING},
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"\$CLAUDE_PROJECT_DIR/.claude/hooks/context-monitor.sh\"",
            "timeout": 10
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"\$CLAUDE_PROJECT_DIR/.claude/hooks/session-cleanup.sh\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
SETTINGSEOF
      fi
    fi
  fi
else
  # Create new settings.json with hooks
  cat > "$SETTINGS_FILE" << 'SETTINGSEOF'
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/context-monitor.sh\"",
            "timeout": 10
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/session-cleanup.sh\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
SETTINGSEOF
fi

# 6. Create initial _active.md if not exists
if [ ! -f "$CLAUDE_DIR/handoffs/_active.md" ]; then
  echo -e "  ${YELLOW}[6/10]${NC} Creating initial handoff..."
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
  echo -e "  ${YELLOW}[6/10]${NC} Handoff already exists, keeping it"
fi

# 7. Add to .gitignore
echo -e "  ${YELLOW}[7/10]${NC} Updating .gitignore..."
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

# 8. Add to CLAUDE.md
echo -e "  ${YELLOW}[8/10]${NC} Updating CLAUDE.md..."
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

# 9. Summary
echo -e "  ${YELLOW}[9/10]${NC} Verifying installation..."
INSTALLED=0
for f in resume.md save-handoff.md switch-context.md handoff.md delete-handoff.md auto-handoff.md; do
  [ -f "$CLAUDE_DIR/commands/$f" ] && INSTALLED=$((INSTALLED + 1))
done
HOOKS_OK=0
[ -f "$CLAUDE_DIR/hooks/context-monitor.sh" ] && HOOKS_OK=$((HOOKS_OK + 1))
[ -f "$CLAUDE_DIR/hooks/session-cleanup.sh" ] && HOOKS_OK=$((HOOKS_OK + 1))

echo ""
echo -e "  ${YELLOW}[10/10]${NC} Done!"
echo ""
if [ "$INSTALLED" -eq 6 ] && [ "$HOOKS_OK" -eq 2 ]; then
  echo -e "${GREEN}  Installed successfully! ($INSTALLED/6 commands, $HOOKS_OK/2 hooks)${NC}"
else
  echo -e "${YELLOW}  Partial install: $INSTALLED/6 commands, $HOOKS_OK/2 hooks${NC}"
fi
echo ""
echo -e "  Commands available:"
echo -e "    ${CYAN}/handoff${NC}              Auto-save session (no wizard)"
echo -e "    ${CYAN}/resume${NC}               Resume with wizard"
echo -e "    ${CYAN}/save-handoff${NC}         Save session state (wizard)"
echo -e "    ${CYAN}/switch-context${NC}       Switch workstream"
echo -e "    ${CYAN}/delete-handoff${NC}       Delete handoff(s)"
echo -e "    ${CYAN}/auto-handoff${NC}         Toggle auto-handoff on/off"
echo ""
echo -e "  Auto-handoff: ${YELLOW}(beta — disabled by default)${NC}"
echo -e "    Use ${CYAN}/auto-handoff${NC} to enable and configure threshold"
echo ""
echo -e "  Files:"
echo -e "    .claude/commands/     6 command files"
echo -e "    .claude/rules/        session-continuity.md, auto-handoff.md"
echo -e "    .claude/hooks/        context-monitor.sh, session-cleanup.sh"
echo -e "    .claude/handoffs/     session state (gitignored)"
echo ""
echo -e "  ${YELLOW}Start Claude Code and use /resume to begin.${NC}"
echo ""
