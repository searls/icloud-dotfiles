#!/opt/homebrew/opt/node/bin/node
/**
 * prove-it: Beads enforcement gate
 *
 * Ensures work is tracked by a bead before allowing code changes.
 *
 * Handles:
 * - PreToolUse (Edit/Write): blocks if no in_progress bead exists
 *
 * The goal: no more "adding beads after the fact"
 */
const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");

function emitJson(obj) {
  process.stdout.write(JSON.stringify(obj));
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

function gitRoot(dir) {
  const r = tryRun(`git -C ${shellEscape(dir)} rev-parse --show-toplevel`, {});
  if (r.code !== 0) return null;
  return r.stdout.trim();
}

function loadJson(p) {
  try {
    return JSON.parse(fs.readFileSync(p, "utf8"));
  } catch {
    return null;
  }
}

function mergeDeep(a, b) {
  if (!b) return a;
  if (Array.isArray(a) && Array.isArray(b)) return b; // override arrays
  if (typeof a === "object" && a && typeof b === "object" && b) {
    const out = { ...a };
    for (const k of Object.keys(b)) out[k] = mergeDeep(a[k], b[k]);
    return out;
  }
  return b;
}

function readStdin() {
  return fs.readFileSync(0, "utf8");
}


function defaultConfig() {
  return {
    beads: {
      enabled: true,
      // Tools that require a bead to be in progress
      gatedTools: ["Edit", "Write", "NotebookEdit"],
      // If true, also gate Bash commands that look like they're writing code
      gateBashWrites: true,
      // Bash patterns that look like code-writing operations
      bashWritePatterns: [
        "\\bcat\\s+.*>",
        "\\becho\\s+.*>",
        "\\btee\\s",
        "\\bsed\\s+-i",
        "\\bawk\\s+.*-i\\s*inplace",
      ],
    },
  };
}

function loadEffectiveConfig(projectDir) {
  const home = os.homedir();
  const globalCfgPath = path.join(home, ".claude", "prove-it", "config.json");

  let cfg = defaultConfig();
  cfg = mergeDeep(cfg, loadJson(globalCfgPath));

  const localCfgPath = path.join(projectDir, ".claude", "prove_it.local.json");
  cfg = mergeDeep(cfg, loadJson(localCfgPath));

  return cfg;
}

function isBeadsRepo(dir) {
  // Check if .beads directory exists AND is a project (not just global config)
  // A beads project has config.yaml or beads.db; the global ~/.beads/ only has registry.json
  const beadsDir = path.join(dir, ".beads");
  if (!fs.existsSync(beadsDir)) return false;
  return (
    fs.existsSync(path.join(beadsDir, "config.yaml")) ||
    fs.existsSync(path.join(beadsDir, "beads.db")) ||
    fs.existsSync(path.join(beadsDir, "metadata.json"))
  );
}

function getInProgressBeads(dir) {
  // Try to get in_progress beads using bd command
  // Wrap in try/catch for resilience if bd is broken or missing
  let r;
  try {
    r = tryRun(`bd list --status in_progress 2>/dev/null`, { cwd: dir });
  } catch (e) {
    console.error(`prove-it: bd command failed: ${e.message}. Beads may need updating.`);
    return null; // Fail open with warning
  }

  if (r.code !== 0) {
    // bd command failed - could be bd not installed, or other error
    // Fail open but log a warning
    if (r.stderr && r.stderr.includes("command not found")) {
      console.error("prove-it: bd command not found. Install beads or disable beads enforcement.");
    }
    return null;
  }

  // Parse the output - bd list returns a table format
  // Look for any non-empty, non-header lines
  const lines = r.stdout
    .trim()
    .split("\n")
    .filter((line) => {
      // Skip empty lines and header separators
      if (!line.trim()) return false;
      if (line.includes("───") || line.includes("---")) return false;
      if (line.toLowerCase().includes("no issues found")) return false;
      // Skip the header line
      if (line.toLowerCase().includes("id") && line.toLowerCase().includes("subject")) return false;
      return true;
    });

  return lines;
}

function shouldGateBash(command, patterns) {
  return patterns.some((pat) => {
    try {
      return new RegExp(pat, "i").test(command);
    } catch {
      return false;
    }
  });
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
  if (hookEvent !== "PreToolUse") process.exit(0);

  const projectDir = process.env.CLAUDE_PROJECT_DIR || input.cwd || process.cwd();
  const cfg = loadEffectiveConfig(projectDir);

  if (!cfg.beads || !cfg.beads.enabled) process.exit(0);

  const toolName = input.tool_name;
  const gatedTools = cfg.beads.gatedTools || [];

  // Check if this tool should be gated
  let shouldGate = gatedTools.includes(toolName);

  // For Bash, check if it looks like a write operation
  if (!shouldGate && toolName === "Bash" && cfg.beads.gateBashWrites) {
    const command = input.tool_input?.command || "";
    shouldGate = shouldGateBash(command, cfg.beads.bashWritePatterns || []);
  }

  if (!shouldGate) process.exit(0);

  // Find the repo root
  const rootDir = gitRoot(projectDir) || projectDir;

  // Check if this is a beads-enabled repo
  if (!isBeadsRepo(rootDir)) {
    // Not a beads repo, don't enforce
    process.exit(0);
  }

  // Check for in_progress beads
  const inProgress = getInProgressBeads(rootDir);

  if (inProgress === null) {
    // bd command failed or not available, don't block (fail open with warning already logged)
    process.exit(0);
  }

  if (inProgress.length > 0) {
    // There are in_progress beads, allow the operation
    process.exit(0);
  }

  // No in_progress beads - block and explain
  const reason = `prove-it: No bead is tracking this work.

Before making code changes, select or create a bead to track this work:

  bd ready              # Show tasks ready to work on
  bd list               # Show all tasks
  bd show <id>          # View task details
  bd update <id> --status in_progress   # Start working on a task
  bd create "Title"     # Create a new task

Once you have an in_progress bead, this operation will be allowed.

Tip: If this is exploratory work, you can disable beads enforcement in
.claude/prove_it.local.json by setting beads.enabled: false`;

  emitJson({
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "block",
      permissionDecisionReason: reason,
    },
  });
}

main();
