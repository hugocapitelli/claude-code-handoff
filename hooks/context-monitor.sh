#!/bin/bash
# Auto-Handoff Context Monitor
# Detecta quando o contexto está próximo do limite e força o salvamento do handoff.
# Usado como hook "Stop" do Claude Code.

# Check if auto-handoff is disabled
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/.auto-handoff-disabled" ]; then
  exit 0
fi

# Contexto máximo do Claude Code (tokens). Varia por plano:
# Pro/Max/Team: 200000 | Enterprise: 500000 | Custom: qualquer valor
MAX_CONTEXT_TOKENS=${CLAUDE_MAX_CONTEXT:-200000}
# Threshold configurável (% do contexto). 90% padrão — maximiza uso do contexto
THRESHOLD_PERCENT=${CLAUDE_CONTEXT_THRESHOLD:-90}
THRESHOLD_TOKENS=$((MAX_CONTEXT_TOKENS * THRESHOLD_PERCENT / 100))

INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

# Validações
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  exit 0
fi

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

# Extrai o input_tokens da última mensagem do assistente no JSONL.
# Isso reflete o tamanho REAL do contexto que o Claude está usando.
# Campos: input_tokens + cache_read_input_tokens + cache_creation_input_tokens = total input
CURRENT_TOKENS=0
if command -v python3 &>/dev/null; then
  CURRENT_TOKENS=$(python3 -c "
import json, sys
last = 0
with open('$TRANSCRIPT_PATH') as f:
    for line in f:
        try:
            e = json.loads(line)
            if e.get('type') == 'assistant':
                u = e.get('message', {}).get('usage', {})
                t = u.get('input_tokens', 0) + u.get('cache_read_input_tokens', 0) + u.get('cache_creation_input_tokens', 0)
                if t > 0:
                    last = t
        except:
            pass
print(last)
" 2>/dev/null)
elif command -v node &>/dev/null; then
  CURRENT_TOKENS=$(node -e "
const fs = require('fs');
const lines = fs.readFileSync('$TRANSCRIPT_PATH', 'utf-8').trim().split('\n');
let last = 0;
for (const line of lines) {
  try {
    const e = JSON.parse(line);
    if (e.type === 'assistant' && e.message?.usage) {
      const u = e.message.usage;
      const t = (u.input_tokens || 0) + (u.cache_read_input_tokens || 0) + (u.cache_creation_input_tokens || 0);
      if (t > 0) last = t;
    }
  } catch {}
}
console.log(last);
" 2>/dev/null)
fi

CURRENT_TOKENS=$(echo "$CURRENT_TOKENS" | tr -d ' \n')
if [ -z "$CURRENT_TOKENS" ] || [ "$CURRENT_TOKENS" -eq 0 ] 2>/dev/null; then
  exit 0
fi

if [ "$CURRENT_TOKENS" -lt "$THRESHOLD_TOKENS" ]; then
  exit 0
fi

# Flag para não re-triggerar (prevenção de loop infinito)
FLAG="/tmp/claude_handoff_triggered_${SESSION_ID}"
if [ -f "$FLAG" ]; then
  exit 0
fi
touch "$FLAG"

# Calcula % atual
CURRENT_PERCENT=$((CURRENT_TOKENS * 100 / MAX_CONTEXT_TOKENS))

# Bloqueia e força handoff
cat <<HOOKEOF
{
  "decision": "block",
  "reason": "⚠️ AUTO-HANDOFF: O contexto atingiu ${CURRENT_PERCENT}% do limite (${CURRENT_TOKENS}/${MAX_CONTEXT_TOKENS} tokens). Você DEVE salvar o handoff AGORA.\n\nSiga estes passos IMEDIATAMENTE:\n1. Analise a conversa inteira e extraia: o que foi feito, próximos passos, arquivos-chave, decisões\n2. Escreva o handoff em .claude/handoffs/_active.md seguindo o template padrão\n3. Diga ao usuário: 'Handoff salvo automaticamente. Use /clear e depois /resume para continuar.'\n\nNÃO continue com outro trabalho até o handoff estar salvo."
}
HOOKEOF
