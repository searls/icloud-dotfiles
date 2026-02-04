#!/opt/homebrew/opt/node/bin/node
/**
 * prove-it: SessionStart hook
 * - Records baseline git state for this session_id
 * - Optionally injects a small reminder into Claude's context
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

function sha256(s) {
  return crypto.createHash("sha256").update(s).digest("hex");
}

function gitStatusHash(dir) {
  const r = tryRun(`git -C ${shellEscape(dir)} status --porcelain=v1`, {});
  if (r.code !== 0) return null;
  return sha256(r.stdout);
}

function isGitRepo(dir) {
  const r = tryRun(`git -C ${shellEscape(dir)} rev-parse --is-inside-work-tree`, {});
  return r.code === 0 && r.stdout.trim() === "true";
}

function readStdin() {
  return fs.readFileSync(0, "utf8");
}


function main() {
  let input;
  try {
    input = JSON.parse(readStdin());
  } catch (e) {
    // For SessionStart, failing to parse is less critical
    // Just log warning and continue without recording baseline
    console.error(`prove-it: Failed to parse SessionStart input: ${e.message}`);
    process.exit(0);
  }

  const sessionId = input.session_id || "unknown";
  const projectDir = process.env.CLAUDE_PROJECT_DIR || input.cwd || process.cwd();

  const home = os.homedir();
  const baseDir = path.join(home, ".claude", "prove-it");
  const sessionsDir = path.join(baseDir, "sessions");
  ensureDir(sessionsDir);

  let root = projectDir;
  let head = null;
  let statusHash = null;
  if (isGitRepo(projectDir)) {
    root = gitRoot(projectDir) || projectDir;
    head = gitHead(root);
    statusHash = gitStatusHash(root);
  }

  const sessionFile = path.join(sessionsDir, `${sessionId}.json`);
  const payload = {
    session_id: sessionId,
    project_dir: projectDir,
    root_dir: root,
    started_at: new Date().toISOString(),
    git: {
      is_repo: isGitRepo(projectDir),
      root,
      head,
      status_hash: statusHash,
    },
  };

  try {
    fs.writeFileSync(sessionFile, JSON.stringify(payload, null, 2), "utf8");
  } catch {
    // ignore
  }

  // Add context that shapes verification mindset (stdout becomes context for SessionStart)
  const reminder = [
    "prove-it active: verifiability-first workflow.",
    "",
    "Before claiming done:",
    "- Run ./script/test (or the configured suite gate)",
    "- Verify to the last mile - if you can run it, run it",
    "- Never say 'Try X to verify' - that's handing off your job",
    "- If you can't verify something, mark it UNVERIFIED explicitly",
    "",
    "The user should receive verified, working code - not a verification checklist.",
  ].join("\n");

  // For SessionStart, stdout is appended to Claude context.
  process.stdout.write(reminder);
}

main();
