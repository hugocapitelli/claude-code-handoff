# Auto-Handoff

Toggle the automatic handoff context monitor on/off, configure threshold, and select your Claude plan.

## Instructions

### Step 1: Check current state

Check if `.claude/hooks/.auto-handoff-disabled` exists:
- If exists → currently DISABLED
- If not exists → currently ENABLED

Also read from `.claude/hooks/context-monitor.sh`:
- `THRESHOLD_PERCENT` value (the default in `THRESHOLD_PERCENT=${CLAUDE_CONTEXT_THRESHOLD:-XX}`)
- `MAX_CONTEXT_TOKENS` value (the default in `MAX_CONTEXT_TOKENS=${CLAUDE_MAX_CONTEXT:-XXXXXX}`)

Derive the plan name from MAX_CONTEXT_TOKENS:
- 200000 → "Pro/Max/Team"
- 500000 → "Enterprise"
- other → "Custom (XXXk)"

### Step 2: Present wizard

Use AskUserQuestion:
- Question: "Auto-handoff está [ATIVADO/DESATIVADO] (plano: [PLAN], threshold: [XX]%). O que deseja fazer?"
- Options based on current state:
  - If enabled: "Desativar" / "Ajustar threshold" / "Alterar plano"
  - If disabled: "Ativar" / "Ativar com configuração customizada"

### Step 3: Execute

#### Toggle (Ativar/Desativar):
- Create or delete `.claude/hooks/.auto-handoff-disabled`

#### Ajustar threshold:
Ask with AskUserQuestion:
- Question: "Qual threshold deseja usar?"
- Options:
  - "90% (Recomendado)" — Padrão, maximiza o uso do contexto
  - "80%" — Equilíbrio entre espaço e segurança
  - "75%" — Para sessões curtas, salva handoff mais cedo
- The user can also type a custom value via "Other"
- Update the `THRESHOLD_PERCENT` default value in `context-monitor.sh` by changing `THRESHOLD_PERCENT=${CLAUDE_CONTEXT_THRESHOLD:-XX}` to the chosen value

#### Alterar plano:
Ask with AskUserQuestion:
- Question: "Qual seu plano do Claude?"
- Options:
  - "Pro / Max / Team" — 200K tokens de contexto
  - "Enterprise" — 500K tokens de contexto (Sonnet 4.5)
- The user can also type a custom value via "Other" (e.g., "1000000" for 1M API context)
- Update the `MAX_CONTEXT_TOKENS` default value in `context-monitor.sh` by changing `MAX_CONTEXT_TOKENS=${CLAUDE_MAX_CONTEXT:-XXXXXX}` to the chosen value

#### Ativar com configuração customizada:
Run both "Alterar plano" and "Ajustar threshold" flows above, then delete `.claude/hooks/.auto-handoff-disabled`

### Step 4: Confirm

Show current state after change:
```
Auto-handoff: [ATIVADO/DESATIVADO]
Plano: [plan name] ([MAX_CONTEXT_TOKENS] tokens)
Threshold: [XX]% (triggers at [calculated tokens] tokens)
```
