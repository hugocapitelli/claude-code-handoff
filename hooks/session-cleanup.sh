#!/bin/bash
# Session Cleanup
# Limpa flag files de sessões anteriores (> 24h) para não acumular lixo no /tmp.
# Usado como hook "SessionStart" do Claude Code.

find /private/tmp -maxdepth 1 -name "claude_handoff_triggered_*" -mmin +1440 -delete 2>/dev/null
exit 0
