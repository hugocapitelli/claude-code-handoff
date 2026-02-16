#!/bin/bash
# ═══════════════════════════════════════════════════════
#  claude-code-handoff — Installer
#  Usage: curl -fsSL https://raw.githubusercontent.com/eximIA-Ventures/claude-code-handoff/main/install.sh | bash
# ═══════════════════════════════════════════════════════

set -e

# Colors (RGB)
AMBER='\033[38;2;245;158;11m'
GREEN='\033[38;2;16;185;129m'
RED='\033[38;2;239;68;68m'
CYAN='\033[38;2;34;211;238m'
WHITE='\033[37m'
GRAY='\033[90m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

REPO="eximIA-Ventures/claude-code-handoff"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$BRANCH"
PROJECT_DIR="$(pwd)"
CLAUDE_DIR="$PROJECT_DIR/.claude"

ok()   { echo -e "  ${GREEN}✓${RESET} $1"; }
fail() { echo -e "  ${RED}✗${RESET} $1"; }
info() { echo -e "  ${GRAY}$1${RESET}"; }
head() { echo -e "\n  ${AMBER}${BOLD}$1${RESET}"; }

# ─── Banner ───────────────────────────────────────────
echo ""
echo -e "  ${AMBER}${BOLD}┌──────────────────────────────────────┐${RESET}"
echo -e "  ${AMBER}${BOLD}│${RESET}   ${WHITE}${BOLD}claude-code-handoff${RESET}  ${DIM}v2.1${RESET}        ${AMBER}${BOLD}│${RESET}"
echo -e "  ${AMBER}${BOLD}│${RESET}   ${GRAY}Session Continuity for Claude Code${RESET}  ${AMBER}${BOLD}│${RESET}"
echo -e "  ${AMBER}${BOLD}└──────────────────────────────────────┘${RESET}"
echo ""
info "Project: ${WHITE}$PROJECT_DIR${RESET}"

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

# ─── Pre-flight ───────────────────────────────────────
head "Pre-flight"

# Detect reinstall
IS_REINSTALL=false
SAVED_THRESHOLD=""
SAVED_MAX_CONTEXT=""
if [ -f "$CLAUDE_DIR/hooks/context-monitor.sh" ]; then
  IS_REINSTALL=true
  SAVED_THRESHOLD=$(grep -oP 'CLAUDE_CONTEXT_THRESHOLD:-\K[0-9]+' "$CLAUDE_DIR/hooks/context-monitor.sh" 2>/dev/null || echo "")
  SAVED_MAX_CONTEXT=$(grep -oP 'CLAUDE_MAX_CONTEXT:-\K[0-9]+' "$CLAUDE_DIR/hooks/context-monitor.sh" 2>/dev/null || echo "")
fi

if [ "$IS_REINSTALL" = true ]; then
  info "Existing installation found. Upgrading..."
else
  ok "Fresh install"
fi

# ─── Directories ──────────────────────────────────────
head "Creating directories"

mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/rules"
mkdir -p "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/handoffs/archive"
ok "Directory structure created"

# ─── Commands ─────────────────────────────────────────
head "Installing commands"

download_file "commands/resume.md" "$CLAUDE_DIR/commands/resume.md"
download_file "commands/save-handoff.md" "$CLAUDE_DIR/commands/save-handoff.md"
download_file "commands/switch-context.md" "$CLAUDE_DIR/commands/switch-context.md"
download_file "commands/handoff.md" "$CLAUDE_DIR/commands/handoff.md"
download_file "commands/delete-handoff.md" "$CLAUDE_DIR/commands/delete-handoff.md"
download_file "commands/auto-handoff.md" "$CLAUDE_DIR/commands/auto-handoff.md"
download_file "commands/context-doctor.md" "$CLAUDE_DIR/commands/context-doctor.md"
ok "7 slash commands installed"

# ─── Rules ────────────────────────────────────────────
head "Installing rules"

download_file "rules/session-continuity.md" "$CLAUDE_DIR/rules/session-continuity.md"
download_file "rules/auto-handoff.md" "$CLAUDE_DIR/rules/auto-handoff.md"
ok "Behavioral rules installed"

# ─── Hooks ────────────────────────────────────────────
head "Installing hooks"

download_file "hooks/context-monitor.sh" "$CLAUDE_DIR/hooks/context-monitor.sh"
download_file "hooks/session-cleanup.sh" "$CLAUDE_DIR/hooks/session-cleanup.sh"
chmod +x "$CLAUDE_DIR/hooks/context-monitor.sh"
chmod +x "$CLAUDE_DIR/hooks/session-cleanup.sh"

if [ "$IS_REINSTALL" = true ]; then
  if [ -n "$SAVED_THRESHOLD" ] && [ "$SAVED_THRESHOLD" != "80" ]; then
    sed -i.bak "s/CLAUDE_CONTEXT_THRESHOLD:-80/CLAUDE_CONTEXT_THRESHOLD:-${SAVED_THRESHOLD}/" "$CLAUDE_DIR/hooks/context-monitor.sh"
    rm -f "$CLAUDE_DIR/hooks/context-monitor.sh.bak"
    ok "Preserved threshold: ${CYAN}${SAVED_THRESHOLD}%${RESET}"
  fi
  if [ -n "$SAVED_MAX_CONTEXT" ] && [ "$SAVED_MAX_CONTEXT" != "200000" ]; then
    sed -i.bak "s/CLAUDE_MAX_CONTEXT:-200000/CLAUDE_MAX_CONTEXT:-${SAVED_MAX_CONTEXT}/" "$CLAUDE_DIR/hooks/context-monitor.sh"
    rm -f "$CLAUDE_DIR/hooks/context-monitor.sh.bak"
    ok "Preserved max context: ${CYAN}${SAVED_MAX_CONTEXT} tokens${RESET}"
  fi
fi

# Clean up legacy disabled flag
rm -f "$CLAUDE_DIR/hooks/.auto-handoff-disabled"
ok "Context monitor + session cleanup hooks"

# ─── Settings ─────────────────────────────────────────
head "Configuring settings.json"

SETTINGS_FILE="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
  if ! grep -q "context-monitor" "$SETTINGS_FILE" 2>/dev/null; then
    if command -v jq &>/dev/null; then
      HOOKS_JSON='{
        "hooks": {
          "Stop": [{"hooks": [{"type": "command", "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/context-monitor.sh\"", "timeout": 10}]}],
          "SessionStart": [{"hooks": [{"type": "command", "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/session-cleanup.sh\"", "timeout": 5}]}]
        }
      }'
      jq --argjson hooks "$(echo "$HOOKS_JSON" | jq '.hooks')" '. + {hooks: $hooks}' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
      ok "Hooks added to existing settings.json"
    else
      EXISTING=$(cat "$SETTINGS_FILE")
      EXISTING=$(echo "$EXISTING" | sed '$ s/}$//')
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
        ok "Hooks added (preserved language setting)"
      else
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
        ok "Hooks config written"
      fi
    fi
  else
    ok "Hooks already configured"
  fi
else
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
  ok "settings.json created with hooks"
fi

# ─── Handoff ──────────────────────────────────────────
head "Setting up handoff storage"

if [ ! -f "$CLAUDE_DIR/handoffs/_active.md" ]; then
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
  ok "Initial handoff template created"
else
  ok "Existing handoff preserved"
fi

# ─── Gitignore ────────────────────────────────────────
head "Updating .gitignore"

GITIGNORE="$PROJECT_DIR/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! grep -q ".claude/handoffs/" "$GITIGNORE" 2>/dev/null; then
    echo "" >> "$GITIGNORE"
    echo "# claude-code-handoff (personal session state)" >> "$GITIGNORE"
    echo ".claude/handoffs/" >> "$GITIGNORE"
    ok "Added .claude/handoffs/ to .gitignore"
  else
    ok "Already in .gitignore"
  fi
else
  echo "# claude-code-handoff (personal session state)" > "$GITIGNORE"
  echo ".claude/handoffs/" >> "$GITIGNORE"
  ok ".gitignore created"
fi

# ─── CLAUDE.md ────────────────────────────────────────
head "Updating CLAUDE.md"

CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
if [ -f "$CLAUDE_MD" ]; then
  if ! grep -q "Session Continuity" "$CLAUDE_MD" 2>/dev/null; then
    TEMP_FILE=$(mktemp)
    awk '
      /^# / && !done {
        print
        print ""
        print "## Session Continuity"
        print ""
        print "Use `/resume` to pick up from a previous session. Use `/handoff` before `/clear` to save."
        print ""
        done=1
        next
      }
      { print }
    ' "$CLAUDE_MD" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$CLAUDE_MD"
    ok "Session Continuity section added"
  else
    ok "Session Continuity already present"
  fi
else
  cat > "$CLAUDE_MD" << 'CLAUDEMD'
# Project Rules

## Session Continuity

Use `/resume` to pick up from a previous session. Use `/handoff` before `/clear` to save.
CLAUDEMD
  ok "CLAUDE.md created"
fi

# ─── Legacy cleanup ──────────────────────────────────
CLEANED=0
for f in retomar.md salvar-handoff.md trocar-contexto.md auto-handoff-toggle.md; do
  if [ -f "$CLAUDE_DIR/commands/$f" ]; then
    rm -f "$CLAUDE_DIR/commands/$f"
    CLEANED=$((CLEANED + 1))
  fi
done
if [ "$CLEANED" -gt 0 ]; then
  info "Removed $CLEANED legacy command(s)"
fi

# ─── Verify ───────────────────────────────────────────
head "Verifying"

INSTALLED=0
for f in resume.md save-handoff.md switch-context.md handoff.md delete-handoff.md auto-handoff.md context-doctor.md; do
  [ -f "$CLAUDE_DIR/commands/$f" ] && INSTALLED=$((INSTALLED + 1))
done
HOOKS_OK=0
[ -f "$CLAUDE_DIR/hooks/context-monitor.sh" ] && HOOKS_OK=$((HOOKS_OK + 1))
[ -f "$CLAUDE_DIR/hooks/session-cleanup.sh" ] && HOOKS_OK=$((HOOKS_OK + 1))

if [ "$INSTALLED" -eq 7 ] && [ "$HOOKS_OK" -eq 2 ]; then
  ok "${INSTALLED}/7 commands, ${HOOKS_OK}/2 hooks"
else
  fail "Partial: ${INSTALLED}/7 commands, ${HOOKS_OK}/2 hooks"
fi

# ─── Done ─────────────────────────────────────────────
echo ""
echo -e "  ${AMBER}${BOLD}════════════════════════════════════════${RESET}"
echo -e "  ${GREEN}${BOLD}  Installed successfully!${RESET}"
echo -e "  ${AMBER}${BOLD}════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${WHITE}${BOLD}Commands:${RESET}"
echo -e "    ${CYAN}/handoff${RESET}            ${GRAY}Auto-save session${RESET}"
echo -e "    ${CYAN}/resume${RESET}             ${GRAY}Resume with wizard${RESET}"
echo -e "    ${CYAN}/save-handoff${RESET}       ${GRAY}Save with options${RESET}"
echo -e "    ${CYAN}/switch-context${RESET}     ${GRAY}Switch workstream${RESET}"
echo -e "    ${CYAN}/delete-handoff${RESET}     ${GRAY}Delete handoff(s)${RESET}"
echo -e "    ${CYAN}/auto-handoff${RESET}       ${GRAY}Toggle auto-handoff${RESET}"
echo -e "    ${CYAN}/context-doctor${RESET}     ${GRAY}Diagnose context bloat${RESET}"
echo ""
echo -e "  ${WHITE}${BOLD}Auto-handoff:${RESET} ${DIM}beta — disabled by default${RESET}"
echo -e "  ${GRAY}Run ${CYAN}/auto-handoff${GRAY} inside Claude Code to enable${RESET}"
echo ""
echo -e "  ${DIM}Start Claude Code and use ${WHITE}/resume${DIM} to begin.${RESET}"
echo ""
