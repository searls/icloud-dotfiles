#!/opt/homebrew/opt/node/bin/node
/**
 * prove-it: Verifiability gate
 *
 * Handles:
 * - PreToolUse (Bash): wraps selected "completion boundary" commands with the suite gate
 * - Stop: blocks Claude from stopping until suite gate passes if the session changed the repo
 *
 * This is intentionally deterministic: it runs the suite gate itself on Stop when required.
 *
 * stop_hook_active field:
 *   When the Stop hook blocks and Claude retries, the input includes stop_hook_active=true.
 *   This prevents infinite Stop loops when tests fail repeatedly - we detect the same
 *   failure state and show a cached message instead of rerunning.
 */
const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");
const crypto = require("crypto");

function emitJson(obj) {
  process.stdout.write(JSON.stringify(obj));
}

function ensureDir(p) {
  fs.mkdirSync(p, { recursive: true });
}

function tryRun(cmd, opts) {
  const r = spawnSync(cmd, {
    ...opts,
    shell: true,
    encoding: "utf8",
    maxBuffer: 50 * 1024 * 1024,
  });
  return { code: r.status ?? 0, stdout: r.stdout ?? "", stderr: r.stderr ?? "" };
}

function shellEscape(str) {
  if (typeof str !== "string") return String(str);
  // Single-quote the string and escape any embedded single quotes
  return "'" + str.replace(/'/g, "'\\''") + "'";
}

function gitHead(dir) {
  const r = tryRun(`git -C ${shellEscape(dir)} rev-parse HEAD`, {});
  if (r.code !== 0) return null;
  return r.stdout.trim();
}

function gitRoot(dir) {
  const r = tryRun(`git -C ${shellEscape(dir)} rev-parse --show-toplevel`, {});
  if (r.code !== 0) return null;
  return r.stdout.trim();
}

function gitStatus(dir) {
  const r = tryRun(`git -C ${shellEscape(dir)} status --porcelain=v1`, {});
  if (r.code !== 0) return null;
  return r.stdout;
}

function isGitRepo(dir) {
  const r = tryRun(`git -C ${shellEscape(dir)} rev-parse --is-inside-work-tree`, {});
  return r.code === 0 && r.stdout.trim() === "true";
}

function loadJson(p) {
  try {
    return JSON.parse(fs.readFileSync(p, "utf8"));
  } catch {
    return null;
  }
}

function mergeDeep(a, b) {
  if (b === undefined || b === null) return a;
  if (Array.isArray(a) && Array.isArray(b)) return b; // override arrays
  if (typeof a === "object" && a && typeof b === "object" && b) {
    const out = { ...a };
    for (const k of Object.keys(b)) out[k] = mergeDeep(a[k], b[k]);
    return out;
  }
  return b;
}

function nowIso() {
  return new Date().toISOString();
}

function readStdin() {
  return fs.readFileSync(0, "utf8");
}

function sha256(s) {
  return crypto.createHash("sha256").update(s).digest("hex");
}

function tailLines(s, n) {
  const lines = s.split(/\r?\n/);
  const tail = lines.slice(Math.max(0, lines.length - n));
  return tail.join("\n").trimEnd();
}

function truncateChars(s, maxChars) {
  if (s.length <= maxChars) return s;
  return s.slice(-maxChars);
}

function writeJson(p, obj) {
  ensureDir(path.dirname(p));
  fs.writeFileSync(p, JSON.stringify(obj, null, 2), "utf8");
}


function defaultConfig() {
  return {
    suiteGate: {
      command: "./script/test",
      require: true,
    },
    preToolUse: {
      enabled: true,
      // The suite gate provides safety; no need to also require user confirmation.
      permissionDecision: "allow",
      gatedCommandRegexes: [
        "(^|\\s)git\\s+commit\\b",
        "(^|\\s)git\\s+push\\b",
        "(^|\\s)(beads|bd)\\s+(done|finish|close)\\b",
      ],
    },
    stop: {
      enabled: true,
      cacheSeconds: 900,
      maxOutputLines: 200,
      maxOutputChars: 12000,
    },
  };
}

function loadEffectiveConfig(projectDir) {
  const home = os.homedir();
  const baseDir = path.join(home, ".claude", "prove-it");
  const globalCfgPath = path.join(baseDir, "config.json");

  let cfg = defaultConfig();
  const globalCfg = loadJson(globalCfgPath);
  cfg = mergeDeep(cfg, globalCfg);

  // Auto-migrate old config
  if (globalCfg && (globalCfg._version || 1) < 3) {
    // v2->v3: permissionDecision "ask" -> "allow"
    if (cfg.preToolUse && cfg.preToolUse.permissionDecision === "ask") {
      cfg.preToolUse.permissionDecision = "allow";
    }
    // Write migrated config back
    try {
      const migrated = { ...globalCfg, _version: 3 };
      if (migrated.preToolUse) migrated.preToolUse.permissionDecision = "allow";
      writeJson(globalCfgPath, migrated);
    } catch {
      // Ignore write errors
    }
  }

  // Per-project override (optional)
  const localCfgPath = path.join(projectDir, ".claude", "prove_it.local.json");
  cfg = mergeDeep(cfg, loadJson(localCfgPath));

  return { cfg, baseDir };
}

function cacheKeyForRoot(rootDir) {
  return sha256(rootDir).slice(0, 12);
}

function loadCache(baseDir, rootDir) {
  const key = cacheKeyForRoot(rootDir);
  const cachePath = path.join(baseDir, "cache", key, "state.json");
  return { key, cachePath, state: loadJson(cachePath) };
}

function saveCache(cachePath, state) {
  writeJson(cachePath, state);
}

function shouldGateCommand(command, regexes) {
  const cmd = command || "";
  return regexes.some((re) => {
    try {
      return new RegExp(re, "i").test(cmd);
    } catch {
      return false;
    }
  });
}

function resolveRoot(projectDir) {
  if (isGitRepo(projectDir)) return gitRoot(projectDir) || projectDir;
  return projectDir;
}

function suiteExists(rootDir, suiteCmd) {
  // Conservative check for default ./script/test. If overridden, we can't reliably stat, so just return true.
  if (suiteCmd === "./script/test") {
    return fs.existsSync(path.join(rootDir, "script", "test"));
  }
  // Legacy support for ./scripts/test
  if (suiteCmd === "./scripts/test") {
    return fs.existsSync(path.join(rootDir, "scripts", "test"));
  }
  return true;
}

function runSuite(rootDir, suiteCmd) {
  const start = Date.now();
  const r = tryRun(suiteCmd, { cwd: rootDir });
  const durationMs = Date.now() - start;
  const combined = `${r.stdout}\n${r.stderr}`.trim();
  return { ...r, combined, durationMs };
}

function stopChangedSinceSessionStart(baseDir, sessionId, rootDir, head, statusHash) {
  if (!sessionId) return true; // if unknown, err on gating
  const sessionPath = path.join(baseDir, "sessions", `${sessionId}.json`);
  const sess = loadJson(sessionPath);
  if (!sess || !sess.git || !sess.git.is_repo) {
    // If we can't compare baseline, only gate when working tree is dirty.
    return null;
  }
  // Only compare if it is the same root dir; otherwise, treat as changed.
  if (sess.git.root && path.resolve(sess.git.root) !== path.resolve(rootDir)) return true;
  const startHead = sess.git.head || null;
  const startStatusHash = sess.git.status_hash || null;

  if (startHead !== head) return true;
  if (startStatusHash !== statusHash) return true;
  return false;
}

function softStopReminder() {
  return `prove-it: Suite gate passed. Before finishing, verify:
- Did you run every verification command yourself, or did you leave "Try X" for the user?
- If you couldn't run something, did you clearly mark it UNVERIFIED?
- Is the user receiving completed, verified work - or a verification TODO list?`;
}

function suiteGateMissingMessage(suiteCmd, rootDir) {
  const esc = shellEscape(rootDir);
  return `prove-it: Suite gate not found.

The suite gate command '${suiteCmd}' does not exist at:
  ${rootDir}

This is a safety block. You have three options:

1. CREATE THE SUITE GATE (recommended):
   prove_it init

2. USE A DIFFERENT COMMAND (e.g., npm test):
   mkdir -p ${esc}/.claude && echo '{"suiteGate":{"command":"npm test"}}' > ${esc}/.claude/prove_it.local.json

3. DISABLE FOR THIS REPO (use with caution):
   mkdir -p ${esc}/.claude && echo '{"suiteGate":{"require":false}}' > ${esc}/.claude/prove_it.local.json

For more info: https://github.com/searlsco/prove-it#configuration`;
}

function main() {
  let input;
  try {
    input = JSON.parse(readStdin());
  } catch (e) {
    // Fail closed: if we can't parse input, block with error
    emitJson({
      decision: "block",
      reason: `prove-it: Failed to parse hook input.\n\nError: ${e.message}\n\nThis is a safety block. Please report this issue.`,
    });
    process.exit(0);
  }

  const hookEvent = input.hook_event_name;
  const projectDir = process.env.CLAUDE_PROJECT_DIR || input.cwd || process.cwd();
  const { cfg, baseDir } = loadEffectiveConfig(projectDir);

  if (hookEvent === "PreToolUse") {
    if (!cfg.preToolUse.enabled) process.exit(0);
    if (input.tool_name !== "Bash") process.exit(0);
    const toolCmd = input.tool_input && input.tool_input.command ? String(input.tool_input.command) : "";
    if (!toolCmd.trim()) process.exit(0);

    // Only gate selected boundary commands
    if (!shouldGateCommand(toolCmd, cfg.preToolUse.gatedCommandRegexes)) process.exit(0);

    // Avoid double-wrapping
    if (toolCmd.includes(cfg.suiteGate.command)) process.exit(0);

    const rootDir = resolveRoot(projectDir);
    const suiteCmd = cfg.suiteGate.command;

    // If suite gate is required but missing, replace the tool call with a failing message.
    if (cfg.suiteGate.require && !suiteExists(rootDir, suiteCmd)) {
      const msg = suiteGateMissingMessage(suiteCmd, rootDir);
      emitJson({
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: cfg.preToolUse.permissionDecision,
          permissionDecisionReason: "prove-it: suite gate missing; blocking completion boundary",
          updatedInput: {
            ...input.tool_input,
            command: `echo ${shellEscape(msg)} 1>&2; exit 1`,
          },
        },
      });
      process.exit(0);
    }

    // Wrap: run suite gate in repo root, then return to original cwd for the original command.
    const cwd = input.cwd || projectDir;
    const wrapped = [
      `cd ${shellEscape(rootDir)}`,
      `&& ${suiteCmd}`,
      `&& cd ${shellEscape(cwd)}`,
      `&& ${toolCmd}`,
    ].join(" ");

    emitJson({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: cfg.preToolUse.permissionDecision,
        permissionDecisionReason: `prove-it: running suite gate (${suiteCmd}) before this command`,
        updatedInput: {
          ...input.tool_input,
          command: wrapped,
          description:
            input.tool_input && input.tool_input.description
              ? `${input.tool_input.description} (prove-it: gated by ${suiteCmd})`
              : `prove-it: gated by ${suiteCmd}`,
        },
      },
    });
    process.exit(0);
  }

  if (hookEvent === "Stop") {
    if (!cfg.stop.enabled) process.exit(0);

    const rootDir = resolveRoot(projectDir);
    const suiteCmd = cfg.suiteGate.command;

    // If not a git repo, we can't reliably know what changed; only gate if suite is required AND exists AND the user opted into that behavior.
    if (!isGitRepo(projectDir)) {
      if (cfg.suiteGate.require && !suiteExists(rootDir, suiteCmd)) {
        emitJson({
          decision: "block",
          reason: suiteGateMissingMessage(suiteCmd, rootDir),
        });
      } else {
        // Soft reminder for non-git repos
        emitJson({
          decision: "approve",
          reason: softStopReminder(),
        });
      }
      process.exit(0);
    }

    const head = gitHead(rootDir);
    const status = gitStatus(rootDir) ?? "";
    const statusHash = sha256(status);

    // Compare to session baseline if available:
    const sessionId = input.session_id || null;
    const changed = stopChangedSinceSessionStart(baseDir, sessionId, rootDir, head, statusHash);

    // If we can prove nothing changed since session start, allow stop without running the suite.
    if (changed === false) process.exit(0);

    // If suite gate required but missing, block.
    if (cfg.suiteGate.require && !suiteExists(rootDir, suiteCmd)) {
      emitJson({
        decision: "block",
        reason: suiteGateMissingMessage(suiteCmd, rootDir),
      });
      process.exit(0);
    }

    const { cachePath, state } = loadCache(baseDir, rootDir);
    const now = Date.now();
    const cacheSeconds = cfg.stop.cacheSeconds ?? 0;

    const last = state && state.last_suite_run ? state.last_suite_run : null;
    const cacheFresh = last && (now - Date.parse(last.ran_at)) / 1000 <= cacheSeconds;
    const sameInputs = last && last.head === head && last.status_hash === statusHash;

    // If last run for this exact state passed recently, allow stop with reminder.
    if (cacheFresh && sameInputs && last.ok === true) {
      emitJson({
        decision: "approve",
        reason: softStopReminder(),
      });
      process.exit(0);
    }

    // Avoid rerunning repeatedly in Stop-hook loop when nothing changed.
    // When stop_hook_active is true, we're in a retry after a previous block.
    // If the workspace hasn't changed, show cached failure instead of rerunning.
    if (input.stop_hook_active && cacheFresh && sameInputs && last && last.ok === false) {
      emitJson({
        decision: "block",
        reason:
          `prove-it: suite gate still failing for current workspace state.\n\n` +
          `Repo: ${rootDir}\n` +
          `Suite gate: ${suiteCmd}\n` +
          `Last run: ${last.ran_at}\n\n` +
          `Tail:\n${last.output_tail || "(no output captured)"}\n\n` +
          `Fix the failure, then try stopping again (the gate will rerun when the workspace changes).`,
      });
      process.exit(0);
    }

    // Run suite gate now (deterministic enforcement).
    const run = runSuite(rootDir, suiteCmd);

    const outputTail = truncateChars(tailLines(run.combined, cfg.stop.maxOutputLines), cfg.stop.maxOutputChars);

    const newState = {
      ...state,
      last_suite_run: {
        ran_at: nowIso(),
        head,
        status_hash: statusHash,
        ok: run.code === 0,
        exit_code: run.code,
        duration_ms: run.durationMs,
        output_tail: outputTail,
      },
    };
    saveCache(cachePath, newState);

    if (run.code === 0) {
      // Soft reminder even on success - prompt reconsideration
      emitJson({
        decision: "approve",
        reason: softStopReminder(),
      });
      process.exit(0);
    } else {
      emitJson({
        decision: "block",
        reason:
          `prove-it: suite gate failed; cannot stop or claim completion.\n\n` +
          `Repo: ${rootDir}\n` +
          `Command: ${suiteCmd}\n` +
          `Exit: ${run.code}\n` +
          `Duration: ${(run.durationMs / 1000).toFixed(1)}s\n\n` +
          `Tail:\n${outputTail || "(no output captured)"}\n\n` +
          `Next step: fix the failure, then rerun ${suiteCmd} (or attempt to stop; the gate will rerun).`,
      });
      process.exit(0);
    }
  }

  // Ignore other events
  process.exit(0);
}

main();
