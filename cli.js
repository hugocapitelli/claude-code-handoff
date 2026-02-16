#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const CYAN = '\x1b[36m';
const NC = '\x1b[0m';

const PROJECT_DIR = process.cwd();
const CLAUDE_DIR = path.join(PROJECT_DIR, '.claude');
const SCRIPT_DIR = __dirname;

console.log('');
console.log(`${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}`);
console.log(`${CYAN}  claude-code-handoff — Session Continuity${NC}`);
console.log(`${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}`);
console.log('');
console.log(`  Project: ${GREEN}${PROJECT_DIR}${NC}`);
console.log('');

// Helper
function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

function copyFile(src, dst) {
  const srcPath = path.join(SCRIPT_DIR, src);
  if (fs.existsSync(srcPath)) {
    fs.copyFileSync(srcPath, dst);
  } else {
    console.error(`  Error: ${src} not found in package`);
    process.exit(1);
  }
}

// 1. Create directories
console.log(`  ${YELLOW}[1/10]${NC} Creating directories...`);
ensureDir(path.join(CLAUDE_DIR, 'commands'));
ensureDir(path.join(CLAUDE_DIR, 'rules'));
ensureDir(path.join(CLAUDE_DIR, 'hooks'));
ensureDir(path.join(CLAUDE_DIR, 'handoffs', 'archive'));

// 2. Copy commands
console.log(`  ${YELLOW}[2/10]${NC} Installing commands...`);
copyFile('commands/resume.md', path.join(CLAUDE_DIR, 'commands', 'resume.md'));
copyFile('commands/save-handoff.md', path.join(CLAUDE_DIR, 'commands', 'save-handoff.md'));
copyFile('commands/switch-context.md', path.join(CLAUDE_DIR, 'commands', 'switch-context.md'));
copyFile('commands/handoff.md', path.join(CLAUDE_DIR, 'commands', 'handoff.md'));
copyFile('commands/delete-handoff.md', path.join(CLAUDE_DIR, 'commands', 'delete-handoff.md'));
copyFile('commands/auto-handoff.md', path.join(CLAUDE_DIR, 'commands', 'auto-handoff.md'));

// 3. Copy rules
console.log(`  ${YELLOW}[3/10]${NC} Installing rules...`);
copyFile('rules/session-continuity.md', path.join(CLAUDE_DIR, 'rules', 'session-continuity.md'));
copyFile('rules/auto-handoff.md', path.join(CLAUDE_DIR, 'rules', 'auto-handoff.md'));

// 4. Install hooks
console.log(`  ${YELLOW}[4/10]${NC} Installing hooks...`);
copyFile('hooks/context-monitor.sh', path.join(CLAUDE_DIR, 'hooks', 'context-monitor.sh'));
copyFile('hooks/session-cleanup.sh', path.join(CLAUDE_DIR, 'hooks', 'session-cleanup.sh'));
fs.chmodSync(path.join(CLAUDE_DIR, 'hooks', 'context-monitor.sh'), 0o755);
fs.chmodSync(path.join(CLAUDE_DIR, 'hooks', 'session-cleanup.sh'), 0o755);
// Auto-handoff disabled by default (beta feature)
fs.writeFileSync(path.join(CLAUDE_DIR, 'hooks', '.auto-handoff-disabled'), '');

// 5. Configure hooks in settings.json
console.log(`  ${YELLOW}[5/10]${NC} Configuring hooks in settings.json...`);
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
  }
} else {
  fs.writeFileSync(settingsPath, JSON.stringify({ hooks: hooksConfig }, null, 2) + '\n');
}

// 4. Create initial _active.md
const activePath = path.join(CLAUDE_DIR, 'handoffs', '_active.md');
if (!fs.existsSync(activePath)) {
  console.log(`  ${YELLOW}[6/10]${NC} Creating initial handoff...`);
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
} else {
  console.log(`  ${YELLOW}[6/10]${NC} Handoff already exists, keeping it`);
}

// 7. Update .gitignore
console.log(`  ${YELLOW}[7/10]${NC} Updating .gitignore...`);
const gitignorePath = path.join(PROJECT_DIR, '.gitignore');
if (fs.existsSync(gitignorePath)) {
  const content = fs.readFileSync(gitignorePath, 'utf-8');
  if (!content.includes('.claude/handoffs/')) {
    fs.appendFileSync(gitignorePath, '\n# claude-code-handoff (personal session state)\n.claude/handoffs/\n');
  }
} else {
  fs.writeFileSync(gitignorePath, '# claude-code-handoff (personal session state)\n.claude/handoffs/\n');
}

// 8. Update CLAUDE.md
console.log(`  ${YELLOW}[8/10]${NC} Updating CLAUDE.md...`);
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
  }
} else {
  fs.writeFileSync(claudeMdPath, `# Project Rules\n\n${continuityBlock}\n`);
}

// 9. Verify
console.log(`  ${YELLOW}[9/10]${NC} Verifying installation...`);
let installed = 0;
for (const f of ['resume.md', 'save-handoff.md', 'switch-context.md', 'handoff.md', 'delete-handoff.md', 'auto-handoff.md']) {
  if (fs.existsSync(path.join(CLAUDE_DIR, 'commands', f))) installed++;
}
let hooksOk = 0;
if (fs.existsSync(path.join(CLAUDE_DIR, 'hooks', 'context-monitor.sh'))) hooksOk++;
if (fs.existsSync(path.join(CLAUDE_DIR, 'hooks', 'session-cleanup.sh'))) hooksOk++;

console.log('');
console.log(`  ${YELLOW}[10/10]${NC} Done!`);
console.log('');
if (installed === 6 && hooksOk === 2) {
  console.log(`${GREEN}  Installed successfully! (${installed}/6 commands, ${hooksOk}/2 hooks)${NC}`);
} else {
  console.log(`${YELLOW}  Partial install: ${installed}/6 commands, ${hooksOk}/2 hooks${NC}`);
}
console.log('');
console.log('  Commands available:');
console.log(`    ${CYAN}/handoff${NC}              Auto-save session (no wizard)`);
console.log(`    ${CYAN}/resume${NC}               Resume with wizard`);
console.log(`    ${CYAN}/save-handoff${NC}         Save session state (wizard)`);
console.log(`    ${CYAN}/switch-context${NC}       Switch workstream`);
console.log(`    ${CYAN}/delete-handoff${NC}       Delete handoff(s)`);
console.log(`    ${CYAN}/auto-handoff${NC}         Toggle auto-handoff on/off`);
console.log('');
console.log(`  Auto-handoff: ${YELLOW}(beta — disabled by default)${NC}`);
console.log(`    Use ${CYAN}/auto-handoff${NC} to enable and configure threshold`);
console.log('');
console.log('  Files:');
console.log('    .claude/commands/     6 command files');
console.log('    .claude/rules/        session-continuity.md, auto-handoff.md');
console.log('    .claude/hooks/        context-monitor.sh, session-cleanup.sh');
console.log('    .claude/handoffs/     session state (gitignored)');
console.log('');
console.log(`  ${YELLOW}Start Claude Code and use /resume to begin.${NC}`);
console.log('');
