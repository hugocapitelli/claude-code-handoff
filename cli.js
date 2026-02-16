#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Colors (RGB)
const AMBER = '\x1b[38;2;245;158;11m';
const GREEN = '\x1b[38;2;16;185;129m';
const RED = '\x1b[38;2;239;68;68m';
const CYAN = '\x1b[38;2;34;211;238m';
const WHITE = '\x1b[37m';
const GRAY = '\x1b[90m';
const BOLD = '\x1b[1m';
const DIM = '\x1b[2m';
const NC = '\x1b[0m';

const ok   = (msg) => console.log(`  ${GREEN}✓${NC} ${msg}`);
const fail = (msg) => console.log(`  ${RED}✗${NC} ${msg}`);
const info = (msg) => console.log(`  ${GRAY}${msg}${NC}`);
const head = (msg) => console.log(`\n  ${AMBER}${BOLD}${msg}${NC}`);

const PROJECT_DIR = process.cwd();
const CLAUDE_DIR = path.join(PROJECT_DIR, '.claude');
const SCRIPT_DIR = __dirname;

// ─── Banner ───────────────────────────────────────────
console.log('');
console.log(`  ${AMBER}${BOLD}┌──────────────────────────────────────┐${NC}`);
console.log(`  ${AMBER}${BOLD}│${NC}   ${WHITE}${BOLD}claude-code-handoff${NC}  ${DIM}v1.9${NC}        ${AMBER}${BOLD}│${NC}`);
console.log(`  ${AMBER}${BOLD}│${NC}   ${GRAY}Session Continuity for Claude Code${NC}  ${AMBER}${BOLD}│${NC}`);
console.log(`  ${AMBER}${BOLD}└──────────────────────────────────────┘${NC}`);
console.log('');
info(`Project: ${WHITE}${PROJECT_DIR}${NC}`);

function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

function copyFile(src, dst) {
  const srcPath = path.join(SCRIPT_DIR, src);
  if (fs.existsSync(srcPath)) {
    fs.copyFileSync(srcPath, dst);
  } else {
    fail(`${src} not found in package`);
    process.exit(1);
  }
}

// ─── Pre-flight ───────────────────────────────────────
head('Pre-flight');

const monitorPath = path.join(CLAUDE_DIR, 'hooks', 'context-monitor.sh');
let isReinstall = false;
let savedThreshold = '';
let savedMaxContext = '';
if (fs.existsSync(monitorPath)) {
  isReinstall = true;
  const oldContent = fs.readFileSync(monitorPath, 'utf-8');
  const thresholdMatch = oldContent.match(/CLAUDE_CONTEXT_THRESHOLD:-(\d+)/);
  const maxContextMatch = oldContent.match(/CLAUDE_MAX_CONTEXT:-(\d+)/);
  if (thresholdMatch) savedThreshold = thresholdMatch[1];
  if (maxContextMatch) savedMaxContext = maxContextMatch[1];
}

if (isReinstall) {
  info('Existing installation found. Upgrading...');
} else {
  ok('Fresh install');
}

// ─── Directories ──────────────────────────────────────
head('Creating directories');

ensureDir(path.join(CLAUDE_DIR, 'commands'));
ensureDir(path.join(CLAUDE_DIR, 'rules'));
ensureDir(path.join(CLAUDE_DIR, 'hooks'));
ensureDir(path.join(CLAUDE_DIR, 'handoffs', 'archive'));
ok('Directory structure created');

// ─── Commands ─────────────────────────────────────────
head('Installing commands');

copyFile('commands/resume.md', path.join(CLAUDE_DIR, 'commands', 'resume.md'));
copyFile('commands/save-handoff.md', path.join(CLAUDE_DIR, 'commands', 'save-handoff.md'));
copyFile('commands/switch-context.md', path.join(CLAUDE_DIR, 'commands', 'switch-context.md'));
copyFile('commands/handoff.md', path.join(CLAUDE_DIR, 'commands', 'handoff.md'));
copyFile('commands/delete-handoff.md', path.join(CLAUDE_DIR, 'commands', 'delete-handoff.md'));
copyFile('commands/auto-handoff.md', path.join(CLAUDE_DIR, 'commands', 'auto-handoff.md'));
ok('6 slash commands installed');

// ─── Rules ────────────────────────────────────────────
head('Installing rules');

copyFile('rules/session-continuity.md', path.join(CLAUDE_DIR, 'rules', 'session-continuity.md'));
copyFile('rules/auto-handoff.md', path.join(CLAUDE_DIR, 'rules', 'auto-handoff.md'));
ok('Behavioral rules installed');

// ─── Hooks ────────────────────────────────────────────
head('Installing hooks');

copyFile('hooks/context-monitor.sh', monitorPath);
copyFile('hooks/session-cleanup.sh', path.join(CLAUDE_DIR, 'hooks', 'session-cleanup.sh'));
fs.chmodSync(monitorPath, 0o755);
fs.chmodSync(path.join(CLAUDE_DIR, 'hooks', 'session-cleanup.sh'), 0o755);

if (isReinstall) {
  let content = fs.readFileSync(monitorPath, 'utf-8');
  if (savedThreshold && savedThreshold !== '80') {
    content = content.replace('CLAUDE_CONTEXT_THRESHOLD:-80', `CLAUDE_CONTEXT_THRESHOLD:-${savedThreshold}`);
    ok(`Preserved threshold: ${CYAN}${savedThreshold}%${NC}`);
  }
  if (savedMaxContext && savedMaxContext !== '200000') {
    content = content.replace('CLAUDE_MAX_CONTEXT:-200000', `CLAUDE_MAX_CONTEXT:-${savedMaxContext}`);
    ok(`Preserved max context: ${CYAN}${savedMaxContext} tokens${NC}`);
  }
  fs.writeFileSync(monitorPath, content);
}

// Clean up legacy disabled flag
const legacyDisabled = path.join(CLAUDE_DIR, 'hooks', '.auto-handoff-disabled');
if (fs.existsSync(legacyDisabled)) fs.unlinkSync(legacyDisabled);
ok('Context monitor + session cleanup hooks');

// ─── Settings ─────────────────────────────────────────
head('Configuring settings.json');

const settingsPath = path.join(CLAUDE_DIR, 'settings.json');
const hooksConfig = {
  Stop: [{ hooks: [{ type: 'command', command: '"$CLAUDE_PROJECT_DIR/.claude/hooks/context-monitor.sh"', timeout: 10 }] }],
  SessionStart: [{ hooks: [{ type: 'command', command: '"$CLAUDE_PROJECT_DIR/.claude/hooks/session-cleanup.sh"', timeout: 5 }] }]
};
if (fs.existsSync(settingsPath)) {
  const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf-8'));
  if (!JSON.stringify(settings).includes('context-monitor')) {
    settings.hooks = hooksConfig;
    fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
    ok('Hooks added to existing settings.json');
  } else {
    ok('Hooks already configured');
  }
} else {
  fs.writeFileSync(settingsPath, JSON.stringify({ hooks: hooksConfig }, null, 2) + '\n');
  ok('settings.json created with hooks');
}

// ─── Handoff ──────────────────────────────────────────
head('Setting up handoff storage');

const activePath = path.join(CLAUDE_DIR, 'handoffs', '_active.md');
if (!fs.existsSync(activePath)) {
  fs.writeFileSync(activePath, `# Session Handoff

> No active session yet. Use \`/handoff\` or \`/save-handoff\` to save your first session state.

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
`);
  ok('Initial handoff template created');
} else {
  ok('Existing handoff preserved');
}

// ─── Gitignore ────────────────────────────────────────
head('Updating .gitignore');

const gitignorePath = path.join(PROJECT_DIR, '.gitignore');
if (fs.existsSync(gitignorePath)) {
  const content = fs.readFileSync(gitignorePath, 'utf-8');
  if (!content.includes('.claude/handoffs/')) {
    fs.appendFileSync(gitignorePath, '\n# claude-code-handoff (personal session state)\n.claude/handoffs/\n');
    ok('Added .claude/handoffs/ to .gitignore');
  } else {
    ok('Already in .gitignore');
  }
} else {
  fs.writeFileSync(gitignorePath, '# claude-code-handoff (personal session state)\n.claude/handoffs/\n');
  ok('.gitignore created');
}

// ─── CLAUDE.md ────────────────────────────────────────
head('Updating CLAUDE.md');

const claudeMdPath = path.join(CLAUDE_DIR, 'CLAUDE.md');
const continuityBlock = `## Session Continuity (MANDATORY)

At the START of every session, read \`.claude/handoffs/_active.md\` to recover context from prior sessions.
During work, update the handoff proactively after significant milestones.
Use \`/handoff\` before \`/clear\`. Use \`/resume\` to pick up. Use \`/switch-context <topic>\` to switch workstreams.`;

if (fs.existsSync(claudeMdPath)) {
  const content = fs.readFileSync(claudeMdPath, 'utf-8');
  if (!content.includes('Session Continuity')) {
    const lines = content.split('\n');
    const firstHeadingIdx = lines.findIndex(l => l.startsWith('# '));
    if (firstHeadingIdx >= 0) {
      lines.splice(firstHeadingIdx + 1, 0, '', continuityBlock, '');
      fs.writeFileSync(claudeMdPath, lines.join('\n'));
    } else {
      fs.appendFileSync(claudeMdPath, '\n' + continuityBlock + '\n');
    }
    ok('Session Continuity section added');
  } else {
    ok('Session Continuity already present');
  }
} else {
  fs.writeFileSync(claudeMdPath, `# Project Rules\n\n${continuityBlock}\n`);
  ok('CLAUDE.md created');
}

// ─── Legacy cleanup ──────────────────────────────────
let cleaned = 0;
for (const f of ['retomar.md', 'salvar-handoff.md', 'trocar-contexto.md', 'auto-handoff-toggle.md']) {
  const fp = path.join(CLAUDE_DIR, 'commands', f);
  if (fs.existsSync(fp)) { fs.unlinkSync(fp); cleaned++; }
}
if (cleaned > 0) info(`Removed ${cleaned} legacy command(s)`);

// ─── Verify ───────────────────────────────────────────
head('Verifying');

let installed = 0;
for (const f of ['resume.md', 'save-handoff.md', 'switch-context.md', 'handoff.md', 'delete-handoff.md', 'auto-handoff.md']) {
  if (fs.existsSync(path.join(CLAUDE_DIR, 'commands', f))) installed++;
}
let hooksOk = 0;
if (fs.existsSync(path.join(CLAUDE_DIR, 'hooks', 'context-monitor.sh'))) hooksOk++;
if (fs.existsSync(path.join(CLAUDE_DIR, 'hooks', 'session-cleanup.sh'))) hooksOk++;

if (installed === 6 && hooksOk === 2) {
  ok(`${installed}/6 commands, ${hooksOk}/2 hooks`);
} else {
  fail(`Partial: ${installed}/6 commands, ${hooksOk}/2 hooks`);
}

// ─── Done ─────────────────────────────────────────────
console.log('');
console.log(`  ${AMBER}${BOLD}════════════════════════════════════════${NC}`);
console.log(`  ${GREEN}${BOLD}  Installed successfully!${NC}`);
console.log(`  ${AMBER}${BOLD}════════════════════════════════════════${NC}`);
console.log('');
console.log(`  ${WHITE}${BOLD}Commands:${NC}`);
console.log(`    ${CYAN}/handoff${NC}            ${GRAY}Auto-save session${NC}`);
console.log(`    ${CYAN}/resume${NC}             ${GRAY}Resume with wizard${NC}`);
console.log(`    ${CYAN}/save-handoff${NC}       ${GRAY}Save with options${NC}`);
console.log(`    ${CYAN}/switch-context${NC}     ${GRAY}Switch workstream${NC}`);
console.log(`    ${CYAN}/delete-handoff${NC}     ${GRAY}Delete handoff(s)${NC}`);
console.log(`    ${CYAN}/auto-handoff${NC}       ${GRAY}Toggle auto-handoff${NC}`);
console.log('');
console.log(`  ${WHITE}${BOLD}Auto-handoff:${NC} ${DIM}beta — disabled by default${NC}`);
console.log(`  ${GRAY}Run ${CYAN}/auto-handoff${GRAY} inside Claude Code to enable${NC}`);
console.log('');
console.log(`  ${DIM}Start Claude Code and use ${WHITE}/resume${DIM} to begin.${NC}`);
console.log('');
