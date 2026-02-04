# Verifiability-First Software Development

## Non‑negotiables

1. **"Done" means "verified".**
   - Never say *done*, *fixed*, *working*, *resolved*, *complete*, or equivalent unless the **suite gate** passed:
     - Run: `./script/test` (from the project root)
     - Exit code: **0**
   - Report verification in a **Verification** section with the exact command(s) run.

2. **Verify to the last mile.**
   - If you can run a verification command, run it. Don't say "Try X" or "Run Y to verify" - that's asking the user to do your job.
   - Bad: "CI passed. Try: `brew reinstall foo`"
   - Good: "CI passed. Ran `brew reinstall foo` and verified it works."
   - If you genuinely cannot run the command (permissions, environment, network), that's UNVERIFIED - say so clearly.

3. **No ad‑hoc verification substitutes.**
   - A one-off script is not verification unless it is part of the suite gate (directly or via `./script/test`).

4. **If you cannot verify, say so explicitly.**
   - Use the label **UNVERIFIED**.
   - Provide the exact command(s) the user should run and the expected success criteria.
   - Do not imply the work is complete. The user is picking up where you left off, not confirming your success.

5. **Prefer evidence over narrative.**
   - Concrete command lines and outputs beat explanations.

---

## Default workflow for every programming request

### 0) Frame the request
- Restate the goal in one sentence.
- List acceptance criteria (observable behaviors).
- Identify constraints (performance, compatibility, security, style, deadlines).

### 1) Choose an oracle (what will prove it works)
Pick the smallest set of oracles that, together, make the change *high confidence*:

- Suite gate: `./script/test` (required for “done”)
- Targeted tests: focused unit/integration tests relevant to the change
- Static checks: typecheck, lint, format, schema validation
- Runtime checks: a reproduction script that becomes a real test, benchmarks, load tests

If a behavior is difficult to test directly, propose an alternative oracle (see “Creative oracles”).

### 2) Establish a baseline
Before editing:
- If feasible: run `./script/test` to ensure the baseline is green.
- For bugs: create a failing test or a minimal reproduction that can be promoted into the suite.

### 3) Implement in small steps
- Make the smallest change that moves an oracle from failing → passing.
- Keep changes localized.
- Prefer incremental commits when appropriate.

### 4) Verify incrementally
After meaningful edits:
- Run the smallest targeted check that can fail for the intended reason.
- If it fails, fix immediately before continuing.

### 5) Gate with the full suite
- Run `./script/test` from the project root.
- Only after it passes can you claim completion.

### 6) Report back with verifiable artifacts
Every completion report must include:

- **Changes**: what files/components were changed and why.
- **Verification**: the exact commands run and what passed.
- **Notes/Risks**: only if relevant; keep it factual.
- **Follow-ups** (optional): concrete next steps.

---

## Creative oracles (use when conventional tests are insufficient)

### 1) Snapshot / golden testing
- Snapshot DOM trees, JSON outputs, rendered HTML, or serialized state.
- Use golden files for CLI output, API responses, or compiler output.
- Add a clear “update snapshot” workflow so changes are intentional.

### 2) Accessibility and user-behavior proxies
Use tools that approximate real user constraints:
- a11y linters and runtime scanners (e.g., axe-based tooling in browser tests)
- keyboard navigation and focus order checks
- screen-reader-relevant tree assertions (where supported)
- E2E automation (e.g., Playwright/Cypress) as a proxy for user workflows

### 3) Differential testing
- Compare two implementations on the same inputs (old vs new, or candidate A vs B).
- For parsers/formatters: round-trip properties.
- For APIs: contract tests against a schema/spec.

### 4) Property-based and fuzz testing
- State machines for workflows
- Randomized inputs for parsers, validators, encoders
- Regression corpus from production issues

### 5) Observability as an oracle
If tests cannot cover a runtime behavior:
- Add structured logs/metrics/traces and assert on them in integration tests.
- Add feature flags and canary rollouts with measured success criteria (when applicable).

---

## UI work: multiple candidates + win-log

When the work is UI/UX-sensitive:

1. Produce **2–4 candidates** that differ meaningfully (layout, hierarchy, density, motion, copy).
2. Ask the user to choose the best, or rank them against criteria.
3. Record outcomes:
   - Keep a repo-local log: `.claude/ui-evals/ui-evals.md`
   - Track what won, why, and the context (user goal, constraints).

Goal: build a local “playbook” of what works in this product.

---

## Reasoning rules (inductive + deductive)

When confidence is low:

- **Inductive**: ask for or search for successful patterns elsewhere:
  - Similar features in this repo
  - Similar OSS projects
  - Existing design system components
- **Deductive**: start from the ideal:
  - “What would a really good X look like?”
  - Then decompose into verifiable subclaims and tests.

If unsure, explicitly ask for the missing information that would reduce uncertainty *and* propose a default path with clear tradeoffs.

---

## Before claiming completion

Ask yourself:

1. Did the suite gate pass? (`./script/test` exit 0)
2. Did I run every command I'm about to mention, or am I asking the user to run it?
3. Am I saying "Try X" or "Verify with Y"? If so, why didn't I run it myself?
4. If I couldn't run something, did I clearly mark it UNVERIFIED?
5. Is the user receiving working code, or a TODO list?

If you catch yourself writing "Try:", "Test with:", "Verify by:", or "Run X to confirm" - stop. Either run it yourself or mark the work UNVERIFIED.

---

## Anti-patterns (don't do these)

- **"Works on my end"** - Claiming success without running the suite gate
- **"Try X to verify"** - Offloading verification to the user while implying completion
- **"Should work"** - Hedging instead of proving
- **"I tested it manually"** - Ad-hoc verification instead of the suite gate
- **"CI will catch it"** - Deferring verification to a later stage
- **"Just needs X"** - Incomplete work presented as nearly-done
- **Verbose confidence** - Long explanations instead of short evidence

---

## Output contract

When you finish a task, end with:

### Verification
- `./script/test` (and any other commands actually run)
- Actual output or exit codes, not just "it passed"

If verification did not happen:

### UNVERIFIED
- Why: what prevented verification (permissions, environment, missing deps)
- Commands: exact commands the user must run
- Success criteria: what "working" looks like
- **This is not done.** The user is finishing the work, not rubber-stamping it.
