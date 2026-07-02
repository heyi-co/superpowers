# Skill Evidence Backfill and Code-Review Restyle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Backfill real RED-baseline evidence (with committed transcripts) for the four issue-workflow skills, fix the evaluation-record integrity defects, and restructure `skills/code-review` into a house-style shell plus a verbatim protocol file — per `docs/superpowers/specs/2026-07-02-skill-evidence-and-style-design.md`.

**Architecture:** A committed runner script drives real, isolated CLI sessions: RED sessions use a scratch config directory with no plugin; GREEN sessions load the working-tree plugin (`claude --plugin-dir` / local Codex marketplace install with a whole-directory diff check). Transcripts land under `docs/superpowers/evidence/` and evaluation files link to them. The code-review restyle moves the imported protocol byte-identically into `review-protocol.md` behind a ~400-word house-style `SKILL.md` shell, bracketed by before/after application runs.

**Tech Stack:** bash, git, `claude` CLI (2.1.198+), `codex` CLI (0.142.5+). No third-party dependencies.

## Global Constraints

- Work on branch `skill-evidence-and-style`; one commit per task.
- Task order: Task 1 first; Tasks 2–5 in any order after it; then 6 → 7 → 8 → 9 → 10 strictly in order (Task 7 must run BEFORE the Task 8 restyle; Task 9 after it).
- Evidence transcripts: `docs/superpowers/evidence/<skill>/<YYYY-MM-DD>-<scenario-slug>-<harness>-<red|green>.md`. Evidence lives under `docs/`, never `skills/` (skills/ ships in the plugin package).
- Exact annotation string for pre-existing rows (tests grep for it): `paraphrased record, predates transcript policy`.
- Every new evaluation row records the run date, harness name and exact version (from `claude --version` / `codex --version` at run time), scenario, observed outcome, and a repo-relative transcript link.
- Every RED row quotes at least one verbatim line from the transcript (the agent's rationalization or key output).
- Sessions always run in a scratch git workspace created by the runner, never inside this repository. Never pass `--dangerously-skip-permissions`, `--full-auto`, or any sandbox/approval bypass flag: Claude headless denies unapproved tool mutations by default and the Codex default sandbox has no network. Scenario prompts are used verbatim from `pressure-scenarios.md` (they embed their own dry-run guards). No session may mutate GitHub. Codex sessions additionally run with a read-only command sandbox (`-s read-only`) and account/MCP connectors disabled (`--disable apps`) so they cannot reach external mutating tools such as the GitHub connector.
- Honesty rule (from the spec): if a RED baseline does not exhibit the predicted failure, record that plainly. Never adjust or discard a result.
- `review-protocol.md` body must be byte-identical to the protocol previously embedded in `SKILL.md` (diff-verified in Task 8); the sha256 pin then guards later drift.
- If a runner invocation fails (auth, onboarding, network), fix the environment and rerun; never hand-write a transcript. Transcripts are only ever produced by `scripts/run-skill-evidence.sh`.

---

### Task 1: Evidence runner script

**Files:**
- Create: `scripts/run-skill-evidence.sh`

**Interfaces:**
- Produces (used by Tasks 2–5, 7, 9):
  - `scripts/run-skill-evidence.sh preflight <claude|codex> <red|green>` → exits 0 and prints `PREFLIGHT OK (<harness> <phase>)` when a trivial session works.
  - `scripts/run-skill-evidence.sh run <claude|codex> <red|green> <skill> <scenario-slug> <prompt-file>` → runs one session, writes the transcript, prints its repo-relative path on the last stdout line.
- RED = scratch config dir, plugin absent. GREEN = scratch config dir with the working-tree plugin loaded (claude: `--plugin-dir`; codex: local marketplace install + `diff -r` against the working tree).

- [ ] **Step 1: Verify the script does not exist yet (RED)**

Run: `bash scripts/run-skill-evidence.sh 2>&1 || true`
Expected: `bash: scripts/run-skill-evidence.sh: No such file or directory`

- [ ] **Step 2: Write the runner**

Create `scripts/run-skill-evidence.sh` with exactly this content:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Skill-evidence session runner.
#   RED   = scratch config, Superpowers absent   -> baseline evidence
#   GREEN = scratch config, working-tree plugin  -> verification evidence
# Design: docs/superpowers/specs/2026-07-02-skill-evidence-and-style-design.md
# Transcripts are only ever produced by this script; never hand-write one.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EVIDENCE_ROOT="$REPO_ROOT/docs/superpowers/evidence"
SCRATCH_ROOT="${SKILL_EVIDENCE_SCRATCH:-$HOME/.cache/skill-evidence-scratch}"
TODAY="$(date +%F)"

usage() {
  cat >&2 <<'USAGE'
Usage:
  run-skill-evidence.sh preflight <claude|codex> <red|green>
  run-skill-evidence.sh run <claude|codex> <red|green> <skill> <scenario-slug> <prompt-file>

RED   = scratch config, plugin absent (baseline)
GREEN = scratch config with the working-tree plugin loaded (verification)
The transcript's repo-relative path is printed on the last stdout line.
USAGE
  exit 2
}

note() { echo "[run-skill-evidence] $*" >&2; }

make_workspace() {
  local dir
  dir="$(mktemp -d "${TMPDIR:-/tmp}/skill-evidence-ws.XXXXXX")"
  git -C "$dir" init --quiet
  echo "# Scratch target repository for a skill-evidence session" > "$dir/README.md"
  git -C "$dir" add README.md
  git -C "$dir" -c user.email=evidence@local -c user.name=evidence \
    commit --quiet -m "init scratch workspace"
  echo "$dir"
}

claude_env_dir() { # $1 = red|green
  local dir="$SCRATCH_ROOT/claude-$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    # Seed onboarding/user state so headless runs skip first-run prompts.
    if [[ -f "$HOME/.claude.json" ]]; then
      cp "$HOME/.claude.json" "$dir/.claude.json"
    fi
    # With a non-default CLAUDE_CONFIG_DIR, claude reads OAuth credentials
    # from $CLAUDE_CONFIG_DIR/.credentials.json (it does not fall back to
    # the macOS Keychain), so materialize them from the Keychain item.
    if security find-generic-password -s "Claude Code-credentials" -w >/dev/null 2>&1; then
      security find-generic-password -s "Claude Code-credentials" -w > "$dir/.credentials.json"
      chmod 600 "$dir/.credentials.json"
    fi
    # Deliberately no plugins/ and no settings.json: the scratch env must
    # not inherit installed plugins or user hooks.
  fi
  echo "$dir"
}

codex_env_dir() { # $1 = red|green
  local dir="$SCRATCH_ROOT/codex-$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    # Codex keeps credentials in CODEX_HOME; seed auth only. No config.toml:
    # the scratch env must not inherit plugin or marketplace configuration.
    if [[ -f "$HOME/.codex/auth.json" ]]; then
      cp "$HOME/.codex/auth.json" "$dir/auth.json"
    fi
  fi
  if [[ "$1" == "green" && ! -f "$dir/.superpowers-installed" ]]; then
    note "installing working-tree plugin into scratch CODEX_HOME"
    CODEX_HOME="$dir" codex plugin marketplace add "$REPO_ROOT" >&2
    CODEX_HOME="$dir" codex plugin add superpowers@superpowers-dev >&2
    touch "$dir/.superpowers-installed"
  fi
  echo "$dir"
}

verify_codex_green_load() { # $1 = CODEX_HOME dir; dies unless installed == working tree
  local installed
  installed="$(CODEX_HOME="$1" codex plugin list \
    | awk '$1 ~ /^superpowers@superpowers-dev/ {print $NF}')"
  if [[ -z "$installed" || ! -d "$installed/skills" ]]; then
    note "FATAL: cannot locate installed superpowers plugin path"
    exit 1
  fi
  if ! diff -r "$installed/skills" "$REPO_ROOT/skills" >/dev/null; then
    note "FATAL: installed plugin skills differ from working tree: $installed"
    note "Remove $1 and rerun to reinstall."
    exit 1
  fi
  echo "$installed"
}

harness_version() { # $1 = claude|codex
  case "$1" in
    claude) claude --version 2>/dev/null | head -1 ;;
    codex)  codex --version 2>/dev/null | head -1 ;;
  esac
}

run_session() { # $1 harness, $2 phase, $3 prompt-file, $4 transcript-path
  local harness="$1" phase="$2" prompt_file="$3" transcript="$4"
  local ws cfg load_note version
  ws="$(make_workspace)"
  version="$(harness_version "$harness")"

  if [[ "$harness" == "claude" ]]; then
    cfg="$(claude_env_dir "$phase")"
    if [[ "$phase" == "green" ]]; then
      load_note="--plugin-dir $REPO_ROOT (working tree loaded directly; no cache to drift)"
    else
      load_note="none (scratch CLAUDE_CONFIG_DIR, no plugins)"
    fi
  else
    cfg="$(codex_env_dir "$phase")"
    if [[ "$phase" == "green" ]]; then
      local installed
      installed="$(verify_codex_green_load "$cfg")"
      load_note="local marketplace install at $installed (diff -r against working tree: identical)"
    else
      load_note="none (scratch CODEX_HOME, auth seeded, no plugins)"
    fi
  fi

  mkdir -p "$(dirname "$transcript")"
  {
    echo "# Evidence transcript"
    echo
    echo "- Date: $TODAY"
    echo "- Harness: $version"
    echo "- Phase: $phase"
    echo "- Prompt file: $prompt_file"
    echo "- Workspace: scratch git repository (created by run-skill-evidence.sh)"
    echo "- Plugin load: $load_note"
    echo
    echo "## Prompt"
    echo
    echo '````text'
    cat "$prompt_file"
    echo '````'
    echo
    echo "## Session output"
    echo
    echo '````text'
  } > "$transcript"

  local rc=0
  if [[ "$harness" == "claude" ]]; then
    if [[ "$phase" == "green" ]]; then
      ( cd "$ws" && CLAUDE_CONFIG_DIR="$cfg" claude -p --output-format text \
          --plugin-dir "$REPO_ROOT" < "$prompt_file" ) >> "$transcript" 2>&1 || rc=$?
    else
      ( cd "$ws" && CLAUDE_CONFIG_DIR="$cfg" claude -p --output-format text \
          < "$prompt_file" ) >> "$transcript" 2>&1 || rc=$?
    fi
  else
    # Harden the session: run model-generated shell commands in a read-only
    # sandbox (-s read-only) and disable account/MCP connectors (--disable apps,
    # the current name for the connectors feature) so the session cannot reach
    # external mutating tools such as the GitHub connector.
    ( cd "$ws" && CODEX_HOME="$cfg" codex exec -s read-only --disable apps - < "$prompt_file" ) \
      >> "$transcript" 2>&1 || rc=$?
  fi
  {
    echo '````'
    echo
    echo "- Exit code: $rc"
  } >> "$transcript"
  if [[ "$rc" -ne 0 ]]; then
    note "session exited non-zero ($rc); recorded in transcript"
  fi
}

cmd="${1:-}"
case "$cmd" in
  preflight)
    [[ $# -eq 3 ]] || usage
    harness="$2"; phase="$3"
    prompt="$(mktemp "${TMPDIR:-/tmp}/skill-evidence-preflight.XXXXXX")"
    echo "Reply with exactly: PREFLIGHT OK" > "$prompt"
    out="$(mktemp "${TMPDIR:-/tmp}/skill-evidence-preflight-out.XXXXXX")"
    run_session "$harness" "$phase" "$prompt" "$out"
    # Check only the session-output section: the prompt echo earlier in the
    # transcript always contains the sentinel, which would mask a dead session.
    if awk '/^## Session output$/,0' "$out" | grep -q "PREFLIGHT OK"; then
      echo "PREFLIGHT OK ($harness $phase)"
    else
      note "preflight failed; transcript follows"
      cat "$out" >&2
      exit 1
    fi
    ;;
  run)
    [[ $# -eq 6 ]] || usage
    harness="$2"; phase="$3"; skill="$4"; slug="$5"; prompt_file="$6"
    [[ -f "$prompt_file" ]] || { note "prompt file not found: $prompt_file"; exit 1; }
    transcript="$EVIDENCE_ROOT/$skill/$TODAY-$slug-$harness-$phase.md"
    run_session "$harness" "$phase" "$prompt_file" "$transcript"
    echo "docs/superpowers/evidence/$skill/$TODAY-$slug-$harness-$phase.md"
    ;;
  *)
    usage
    ;;
esac
```

- [ ] **Step 3: Syntax and lint check**

Run: `bash -n scripts/run-skill-evidence.sh && chmod +x scripts/run-skill-evidence.sh && bash scripts/lint-shell.sh`
Expected: no output from `bash -n`; lint passes (the repo lint script picks up `scripts/` automatically).

- [ ] **Step 4: Preflight all four environments (GREEN for the runner)**

Run, one at a time:
```bash
scripts/run-skill-evidence.sh preflight claude red
scripts/run-skill-evidence.sh preflight claude green
scripts/run-skill-evidence.sh preflight codex red
scripts/run-skill-evidence.sh preflight codex green
```
Expected: each prints `PREFLIGHT OK (<harness> <phase>)`. If codex red fails on auth, confirm `~/.codex/auth.json` exists, delete `~/.cache/skill-evidence-scratch/codex-red`, and rerun. If claude preflight fails on auth or a first-run prompt, confirm `~/.claude.json` and the Keychain item `Claude Code-credentials` both exist, delete the matching scratch dir, and rerun. Do not proceed until all four pass — every later task depends on this.

- [ ] **Step 5: Commit**

```bash
git add scripts/run-skill-evidence.sh
git commit -m "Add skill-evidence session runner"
```

---

### Task 2: triaging-issues RED baselines

**Files:**
- Modify: `skills/triaging-issues/evaluation.md`
- Modify: `tests/triaging-issues/test-triaging-issues-skill.sh` (evaluation assertions region, currently lines 149–151)
- Create: `docs/superpowers/evidence/triaging-issues/` (4 transcripts, via runner)

**Interfaces:**
- Consumes: `scripts/run-skill-evidence.sh run ...` from Task 1.
- Scenarios (prompts copied verbatim from `skills/triaging-issues/pressure-scenarios.md`): `### 6. Possible vulnerability report` (slug `security-report`) and `### 10. Broad bundled issue` (slug `bundled-issue`).

- [ ] **Step 1: Tighten the structural test (failing first)**

In `tests/triaging-issues/test-triaging-issues-skill.sh`, directly after the existing line
`assert_contains "$EVALUATION" "After change" "evaluation summary records after-change behavior"`,
add:

```bash
assert_contains "$EVALUATION" "docs/superpowers/evidence/triaging-issues/" "evaluation links evidence transcripts"
assert_contains "$EVALUATION" "paraphrased record, predates transcript policy" "pre-transcript rows are annotated"
assert_not_contains "$EVALUATION" "Expected failure mode recorded" "no planned run is presented as a result"

while IFS= read -r evidence_path; do
  assert_file_exists "$REPO_ROOT/$evidence_path" "linked transcript exists: $evidence_path"
done < <(grep -o 'docs/superpowers/evidence/[A-Za-z0-9/._-]*\.md' "$EVALUATION" | sort -u)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/triaging-issues/test-triaging-issues-skill.sh`
Expected: FAIL on "evaluation links evidence transcripts" and "pre-transcript rows are annotated" (evaluation.md not yet updated).

- [ ] **Step 3: Extract the two scenario prompts**

Open `skills/triaging-issues/pressure-scenarios.md`. Copy the full fenced prompt block under `### 6. Possible vulnerability report` into `/tmp/triaging-security-report.md`, and the one under `### 10. Broad bundled issue` into `/tmp/triaging-bundled-issue.md` (prompt text only, verbatim, without the `Expected:` block).

- [ ] **Step 4: Run the four RED sessions**

```bash
scripts/run-skill-evidence.sh run claude red triaging-issues security-report /tmp/triaging-security-report.md
scripts/run-skill-evidence.sh run codex  red triaging-issues security-report /tmp/triaging-security-report.md
scripts/run-skill-evidence.sh run claude red triaging-issues bundled-issue  /tmp/triaging-bundled-issue.md
scripts/run-skill-evidence.sh run codex  red triaging-issues bundled-issue  /tmp/triaging-bundled-issue.md
```
Expected: each prints a transcript path under `docs/superpowers/evidence/triaging-issues/`. Read each transcript fully before Step 5.

- [ ] **Step 5: Update evaluation.md**

In `skills/triaging-issues/evaluation.md`:

1. Directly under the existing baseline table (after its last row, before `## After change`), add:

```markdown
The table above is a paraphrased record, predates transcript policy.

### Transcripted baseline runs (<date>)

| Harness | Scenario | Observed behavior | Transcript |
| --- | --- | --- | --- |
| <exact version from transcript> | Possible vulnerability report | <one-sentence observed outcome from the transcript> | [red transcript](../../docs/superpowers/evidence/triaging-issues/<file>.md) |
```
…one row per run (4 rows). Relative links from `skills/triaging-issues/` to the evidence files are `../../docs/superpowers/evidence/triaging-issues/<file>.md`.

2. After the table, add a `Verbatim excerpts:` list with at least one exact quoted line per run:

```markdown
Verbatim excerpts:

- security-report / <harness>: > "<exact line copied from the transcript>"
```

3. Under the existing after-change table, add the same one-line annotation: `The table above is a paraphrased record, predates transcript policy.`

Fill every `<...>` from the actual transcripts — including honest "did not fail" outcomes if a baseline behaved well (Global Constraints, honesty rule).

- [ ] **Step 6: Run the test to verify it passes**

Run: `bash tests/triaging-issues/test-triaging-issues-skill.sh`
Expected: `All ... tests passed` (or the suite's PASS line) with the new assertions green.

- [ ] **Step 7: Commit**

```bash
git add skills/triaging-issues/evaluation.md tests/triaging-issues/test-triaging-issues-skill.sh docs/superpowers/evidence/triaging-issues/
git commit -m "Backfill transcripted RED baselines for triaging-issues"
```

---

### Task 3: working-from-issues RED baselines

**Files:**
- Modify: `skills/working-from-issues/evaluation.md`
- Modify: `tests/working-from-issues/test-working-from-issues-skill.sh` (evaluation assertions region, currently the block ending with the two version-literal asserts)
- Create: `docs/superpowers/evidence/working-from-issues/` (4 transcripts, via runner)

**Interfaces:**
- Consumes: `scripts/run-skill-evidence.sh run ...` from Task 1.
- Scenarios from `skills/working-from-issues/pressure-scenarios.md`: `### 1. Raw issue without Triage Result` (slug `raw-issue-start`) and `### 9. GitHub mutation pressure` (slug `blanket-approval`).

- [ ] **Step 1: Tighten the structural test (failing first)**

In `tests/working-from-issues/test-working-from-issues-skill.sh`, DELETE these two lines:

```bash
assert_contains "$EVALUATION" "Codex CLI 0.142.3" "evaluation summary records Codex version"
assert_contains "$EVALUATION" "Claude Code 2.1.185" "evaluation summary records Claude version"
```

and in their place add:

```bash
assert_contains "$EVALUATION" "docs/superpowers/evidence/working-from-issues/" "evaluation links evidence transcripts"
assert_contains "$EVALUATION" "paraphrased record, predates transcript policy" "pre-transcript rows are annotated"
assert_not_contains "$EVALUATION" "Expected failure mode recorded" "no planned run is presented as a result"

while IFS= read -r evidence_path; do
  assert_file_exists "$REPO_ROOT/$evidence_path" "linked transcript exists: $evidence_path"
done < <(grep -o 'docs/superpowers/evidence/[A-Za-z0-9/._-]*\.md' "$EVALUATION" | sort -u)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/working-from-issues/test-working-from-issues-skill.sh`
Expected: FAIL on the two new `assert_contains` lines.

- [ ] **Step 3: Extract the two scenario prompts**

From `skills/working-from-issues/pressure-scenarios.md`, copy the fenced prompt block (including its embedded `## Triage Result` where the scenario carries one) under `### 1. Raw issue without Triage Result` into `/tmp/wfi-raw-issue-start.md`, and under `### 9. GitHub mutation pressure` into `/tmp/wfi-blanket-approval.md`.

- [ ] **Step 4: Run the four RED sessions**

```bash
scripts/run-skill-evidence.sh run claude red working-from-issues raw-issue-start  /tmp/wfi-raw-issue-start.md
scripts/run-skill-evidence.sh run codex  red working-from-issues raw-issue-start  /tmp/wfi-raw-issue-start.md
scripts/run-skill-evidence.sh run claude red working-from-issues blanket-approval /tmp/wfi-blanket-approval.md
scripts/run-skill-evidence.sh run codex  red working-from-issues blanket-approval /tmp/wfi-blanket-approval.md
```
Read each transcript fully before Step 5.

- [ ] **Step 5: Update evaluation.md**

In `skills/working-from-issues/evaluation.md`:

1. Under the existing `## Baseline` table add the annotation line and a `### Transcripted baseline runs (<date>)` table plus `Verbatim excerpts:` list — same structure and relative-link shape as Task 2 Step 5, with skill path `working-from-issues`.
2. Add the annotation line `The table above is a paraphrased record, predates transcript policy.` under each of: the `## After change` table, the `## Full pressure matrix` table, and the `## Post-review targeted regression` table.
3. Fill all cells and quotes from the actual transcripts.

- [ ] **Step 6: Run the test to verify it passes**

Run: `bash tests/working-from-issues/test-working-from-issues-skill.sh`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add skills/working-from-issues/evaluation.md tests/working-from-issues/test-working-from-issues-skill.sh docs/superpowers/evidence/working-from-issues/
git commit -m "Backfill transcripted RED baselines for working-from-issues"
```

---

### Task 4: decomposing-issues RED baselines

**Files:**
- Modify: `skills/decomposing-issues/evaluation.md`
- Modify: `tests/decomposing-issues/test-decomposing-issues-skill.sh` (evaluation assertions region, currently lines 139–141)
- Create: `docs/superpowers/evidence/decomposing-issues/` (4 transcripts, via runner)

**Interfaces:**
- Consumes: `scripts/run-skill-evidence.sh run ...` from Task 1.
- Scenarios from `skills/decomposing-issues/pressure-scenarios.md`: `### 3. Technical layer split pressure` (slug `component-split`) and `### 7. GitHub mutation pressure` (slug `blanket-approval`).

- [ ] **Step 1: Tighten the structural test (failing first)**

In `tests/decomposing-issues/test-decomposing-issues-skill.sh`, directly after
`assert_contains "$EVALUATION" "After change" "evaluation summary records after-change behavior"`,
add the same block as Task 2 Step 1 with the skill path changed:

```bash
assert_contains "$EVALUATION" "docs/superpowers/evidence/decomposing-issues/" "evaluation links evidence transcripts"
assert_contains "$EVALUATION" "paraphrased record, predates transcript policy" "pre-transcript rows are annotated"
assert_not_contains "$EVALUATION" "Expected failure mode recorded" "no planned run is presented as a result"

while IFS= read -r evidence_path; do
  assert_file_exists "$REPO_ROOT/$evidence_path" "linked transcript exists: $evidence_path"
done < <(grep -o 'docs/superpowers/evidence/[A-Za-z0-9/._-]*\.md' "$EVALUATION" | sort -u)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/decomposing-issues/test-decomposing-issues-skill.sh`
Expected: FAIL on the two new `assert_contains` lines.

- [ ] **Step 3: Extract the two scenario prompts**

From `skills/decomposing-issues/pressure-scenarios.md`, copy the fenced prompt block (with its embedded `## Triage Result`) under `### 3. Technical layer split pressure` into `/tmp/dec-component-split.md`, and under `### 7. GitHub mutation pressure` into `/tmp/dec-blanket-approval.md`.

- [ ] **Step 4: Run the four RED sessions**

```bash
scripts/run-skill-evidence.sh run claude red decomposing-issues component-split  /tmp/dec-component-split.md
scripts/run-skill-evidence.sh run codex  red decomposing-issues component-split  /tmp/dec-component-split.md
scripts/run-skill-evidence.sh run claude red decomposing-issues blanket-approval /tmp/dec-blanket-approval.md
scripts/run-skill-evidence.sh run codex  red decomposing-issues blanket-approval /tmp/dec-blanket-approval.md
```
Read each transcript fully before Step 5.

- [ ] **Step 5: Update evaluation.md**

In `skills/decomposing-issues/evaluation.md`:

1. The current `## Baseline` section is a prediction, not a record. Retitle its intro sentence to make that explicit — replace:
   `Without a dedicated decomposition skill, agents commonly produce informal split lists from `needs-decomposition` prompts. Expected baseline failures to watch for:`
   with:
   `Predicted failure modes, written before any baseline run (kept for context):`
2. After the predicted-failures bullet list, add the `### Transcripted baseline runs (<date>)` table (4 rows) plus `Verbatim excerpts:` list — same structure and relative-link shape as Task 2 Step 5, with skill path `decomposing-issues`.
3. Add `The table above is a paraphrased record, predates transcript policy.` under each of: the `### Targeted mutation-pressure smoke` table and the `### Post-review targeted regressions` table.
4. Fill all cells and quotes from the actual transcripts.

- [ ] **Step 6: Run the test to verify it passes**

Run: `bash tests/decomposing-issues/test-decomposing-issues-skill.sh`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add skills/decomposing-issues/evaluation.md tests/decomposing-issues/test-decomposing-issues-skill.sh docs/superpowers/evidence/decomposing-issues/
git commit -m "Backfill transcripted RED baselines for decomposing-issues"
```

---

### Task 5: reconciling-issues RED baselines and record repair

**Files:**
- Modify: `skills/reconciling-issues/evaluation.md`
- Modify: `tests/reconciling-issues/test-reconciling-issues-skill.sh` (evaluation assertions region, currently lines 162–164)
- Create: `docs/superpowers/evidence/reconciling-issues/` (4 transcripts, via runner)

**Interfaces:**
- Consumes: `scripts/run-skill-evidence.sh run ...` from Task 1.
- Scenarios from `skills/reconciling-issues/pressure-scenarios.md`: `### 1. All children closed but partial coverage` (slug `all-children-closed`) and `### 6. Human mapping omits parent atom` (slug `incomplete-mapping`).

- [ ] **Step 1: Tighten the structural test (failing first)**

In `tests/reconciling-issues/test-reconciling-issues-skill.sh`, directly after
`assert_contains "$EVALUATION" "After change" "evaluation summary records after-change behavior"`,
add:

```bash
assert_contains "$EVALUATION" "docs/superpowers/evidence/reconciling-issues/" "evaluation links evidence transcripts"
assert_contains "$EVALUATION" "paraphrased record, predates transcript policy" "pre-transcript rows are annotated"
assert_not_contains "$EVALUATION" "Expected failure mode recorded" "no planned run is presented as a result"

while IFS= read -r evidence_path; do
  assert_file_exists "$REPO_ROOT/$evidence_path" "linked transcript exists: $evidence_path"
done < <(grep -o 'docs/superpowers/evidence/[A-Za-z0-9/._-]*\.md' "$EVALUATION" | sort -u)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/reconciling-issues/test-reconciling-issues-skill.sh`
Expected: FAIL on the new `assert_contains` lines AND on `assert_not_contains` — the current Smoke Results table contains two fabricated rows whose result cell is `Expected failure mode recorded before skill implementation.` (this is the record-integrity defect this task removes).

- [ ] **Step 3: Extract the two scenario prompts**

From `skills/reconciling-issues/pressure-scenarios.md`, copy the fenced prompt block under `### 1. All children closed but partial coverage` into `/tmp/rec-all-children-closed.md`, and under `### 6. Human mapping omits parent atom` into `/tmp/rec-incomplete-mapping.md`.

- [ ] **Step 4: Run the four RED sessions**

```bash
scripts/run-skill-evidence.sh run claude red reconciling-issues all-children-closed /tmp/rec-all-children-closed.md
scripts/run-skill-evidence.sh run codex  red reconciling-issues all-children-closed /tmp/rec-all-children-closed.md
scripts/run-skill-evidence.sh run claude red reconciling-issues incomplete-mapping  /tmp/rec-incomplete-mapping.md
scripts/run-skill-evidence.sh run codex  red reconciling-issues incomplete-mapping  /tmp/rec-incomplete-mapping.md
```
Read each transcript fully before Step 5.

- [ ] **Step 5: Repair evaluation.md**

In `skills/reconciling-issues/evaluation.md`:

1. In `## Baseline`, replace the intro line `No `reconciling-issues` skill existed. Expected baseline failures:` with `Predicted failure modes, written before any baseline run (kept for context):` and keep the bullet list.
2. After that list, add the `### Transcripted baseline runs (<date>)` table (4 rows) plus `Verbatim excerpts:` — same structure and relative-link shape as Task 2 Step 5, with skill path `reconciling-issues`.
3. In `## Smoke Results`, DELETE the two fabricated baseline rows (the rows whose Result cell is `Expected failure mode recorded before skill implementation.`).
4. Keep the two real after-change rows, and directly under the table add:
   `The rows above are a paraphrased record, predates transcript policy. The `Claude Code 2.1.195` version string is inconsistent with contemporaneous records (`2.1.185`) and cannot be verified against a transcript.`
5. In `## After change`, the section is currently `Expected changed behavior:` — retitle that line to `Expected changed behavior (written before the smoke runs; outcomes recorded in Smoke Results):` so no expectation reads as a result.

- [ ] **Step 6: Run the test to verify it passes**

Run: `bash tests/reconciling-issues/test-reconciling-issues-skill.sh`
Expected: PASS, including `assert_not_contains ... "Expected failure mode recorded"`.

- [ ] **Step 7: Commit**

```bash
git add skills/reconciling-issues/evaluation.md tests/reconciling-issues/test-reconciling-issues-skill.sh docs/superpowers/evidence/reconciling-issues/
git commit -m "Backfill reconciling-issues RED baselines and repair fabricated rows"
```

---

### Task 6: code-review pressure scenarios

**Files:**
- Create: `skills/code-review/pressure-scenarios.md`

**Interfaces:**
- Produces: two application-scenario prompts consumed verbatim by Tasks 7 and 9 (`### 1. Planted-bug diff`, `### 2. Clean diff`) and the no-skill control note consumed by Task 7.

- [ ] **Step 1: Write the scenarios file**

Create `skills/code-review/pressure-scenarios.md` with exactly this content:

````markdown
# Code Review Pressure Scenarios

Application scenarios for a technique skill: they verify the skill applies its
protocol correctly, not rule compliance under pressure. Run them with
`scripts/run-skill-evidence.sh` before and after any change to `SKILL.md` or
`review-protocol.md`, on Codex CLI and Claude Code.

## Baseline Failure Evidence

Run scenario 1 once with the skill absent (RED) as a control. Record what a
bare agent reports without the protocol: typically a prose review, no severity
ranking, no JSON contract, and no guarantee both planted bugs are found.

## Pass Criteria

- Scenario 1: output contains a JSON array of findings; both planted bugs are
  reported (the falsy-zero limit regression and the dropped `await` on the
  audit call) with concrete `failure_scenario` values; no style-only findings;
  at most 15 findings.
- Scenario 2: output is exactly the empty JSON array `[]` (plus surrounding
  prose at most); no invented findings.
- No session modifies files or contacts GitHub.

## Scenarios

### 1. Planted-bug diff

Prompt:

```text
Review the following change. Use the code-review skill if it is available.
Do not modify any files and do not contact any external service; produce the
review as text with your findings as a JSON array.

diff --git a/src/orders.js b/src/orders.js
index 3f1c2aa..9d04b71 100644
--- a/src/orders.js
+++ b/src/orders.js
@@ -1,15 +1,13 @@
 const DEFAULT_LIMIT = 50;
 
-async function listOrders(db, customerId, limit) {
-  if (limit === undefined || limit === null) {
-    limit = DEFAULT_LIMIT;
-  }
-  const rows = await db.query(
-    'SELECT * FROM orders WHERE customer_id = ? ORDER BY created_at DESC LIMIT ?',
-    [customerId, limit]
-  );
-  await db.audit('orders.list', customerId);
-  return rows;
-}
+async function listOrders(db, customerId, limit) {
+  const effectiveLimit = limit || DEFAULT_LIMIT;
+  const rows = await db.query(
+    'SELECT * FROM orders WHERE customer_id = ? ORDER BY created_at DESC LIMIT ?',
+    [customerId, effectiveLimit]
+  );
+  db.audit('orders.list', customerId);
+  return rows;
+}
 
 module.exports = { listOrders, DEFAULT_LIMIT };
```

Expected:

- Finds the falsy-zero regression: `limit || DEFAULT_LIMIT` turns an explicit
  `limit = 0` request into 50 rows, where the old code honored 0.
- Finds the dropped `await` on `db.audit(...)`: the audit write becomes
  fire-and-forget; a rejection is unhandled and the audit row is not
  guaranteed before return.
- Reports both as JSON findings with priority, file, line, category, summary,
  and failure_scenario. Returns no style-only findings.

### 2. Clean diff

Prompt:

```text
Review the following change. Use the code-review skill if it is available.
Do not modify any files and do not contact any external service; produce the
review as text with your findings as a JSON array.

diff --git a/src/greeting.js b/src/greeting.js
index 82ab114..f10c377 100644
--- a/src/greeting.js
+++ b/src/greeting.js
@@ -1,5 +1,5 @@
-function greet(name) {
-  return 'Hello, ' + name + '!';
-}
+function greet(name) {
+  return `Hello, ${name}!`;
+}
 
 module.exports = { greet };
```

Expected:

- Returns the empty JSON array `[]`. No invented findings, no style
  commentary reported as a finding.
````

- [ ] **Step 2: Verify the file's fenced blocks are well-formed**

Run: `grep -c '```' skills/code-review/pressure-scenarios.md`
Expected: `4` (two `text` prompt fences, each opening and closing once; the diffs sit inside those fences without their own fences).

- [ ] **Step 3: Commit**

```bash
git add skills/code-review/pressure-scenarios.md
git commit -m "Add code-review application pressure scenarios"
```

---

### Task 7: code-review BEFORE runs and evaluation scaffold

**Files:**
- Create: `skills/code-review/evaluation.md`
- Create: `docs/superpowers/evidence/code-review/` (5 transcripts, via runner)

**Interfaces:**
- Consumes: runner from Task 1; scenario prompts from Task 6.
- Produces: `## Before restyle` evaluation rows that Task 9 compares against.
- MUST run before Task 8 (these sessions measure the current, pre-restyle skill).

- [ ] **Step 1: Extract the two prompts**

Copy the fenced `text` prompt block (prompt plus embedded diff) under `### 1. Planted-bug diff` in `skills/code-review/pressure-scenarios.md` into `/tmp/cr-planted-bug.md`, and under `### 2. Clean diff` into `/tmp/cr-clean-diff.md`.

- [ ] **Step 2: Run the no-skill control (RED) and the four before-restyle sessions (GREEN)**

```bash
scripts/run-skill-evidence.sh run claude red   code-review planted-bug-control /tmp/cr-planted-bug.md
scripts/run-skill-evidence.sh run claude green code-review planted-bug-before  /tmp/cr-planted-bug.md
scripts/run-skill-evidence.sh run codex  green code-review planted-bug-before  /tmp/cr-planted-bug.md
scripts/run-skill-evidence.sh run claude green code-review clean-diff-before   /tmp/cr-clean-diff.md
scripts/run-skill-evidence.sh run codex  green code-review clean-diff-before   /tmp/cr-clean-diff.md
```
Read every transcript fully. For each GREEN run check the Pass Criteria from `skills/code-review/pressure-scenarios.md` and note pass/fail per criterion.

- [ ] **Step 3: Write evaluation.md**

Create `skills/code-review/evaluation.md`:

```markdown
# Code Review Evaluation

Application-run evidence for `code-review` (a technique skill: runs verify
correct protocol application, per writing-skills). Prompts come verbatim from
[pressure-scenarios.md](pressure-scenarios.md); transcripts are produced only
by `scripts/run-skill-evidence.sh`.

## Baseline

No-skill control (RED): what a bare agent does with the planted-bug diff.

| Harness | Scenario | Observed behavior | Transcript |
| --- | --- | --- | --- |
| <version> | Planted-bug diff (control) | <observed: format, which bugs found/missed> | [link](../../docs/superpowers/evidence/code-review/<file>.md) |

Verbatim excerpts:

- planted-bug-control / claude: > "<exact line from the transcript>"

## Before restyle

Runs against the pre-restyle single-file SKILL.md (imported protocol).

| Harness | Scenario | Result vs pass criteria | Transcript |
| --- | --- | --- | --- |
| <version> | Planted-bug diff | <both bugs found? JSON contract? style noise?> | [link](../../docs/superpowers/evidence/code-review/<file>.md) |
| <version> | Planted-bug diff | <both bugs found? JSON contract? style noise?> | [link](../../docs/superpowers/evidence/code-review/<file>.md) |
| <version> | Clean diff | <returned []?> | [link](../../docs/superpowers/evidence/code-review/<file>.md) |
| <version> | Clean diff | <returned []?> | [link](../../docs/superpowers/evidence/code-review/<file>.md) |

## After restyle

Recorded by the restyle follow-up task after `SKILL.md` becomes the house
shell and the protocol moves to `review-protocol.md`.
```

Fill every `<...>` from the transcripts (honesty rule applies — record misses plainly).

- [ ] **Step 4: Verify links resolve**

Run:
```bash
grep -o 'docs/superpowers/evidence/code-review/[A-Za-z0-9/._-]*\.md' skills/code-review/evaluation.md | sort -u | while read -r p; do [ -f "$p" ] && echo "OK $p" || echo "MISSING $p"; done
```
Expected: every line starts with `OK`.

- [ ] **Step 5: Commit**

```bash
git add skills/code-review/evaluation.md docs/superpowers/evidence/code-review/
git commit -m "Record code-review no-skill control and before-restyle runs"
```

---

### Task 8: Restructure code-review into shell + protocol

**Files:**
- Modify: `skills/code-review/SKILL.md` (becomes the house shell)
- Create: `skills/code-review/review-protocol.md` (verbatim protocol + provenance header)
- Modify: `tests/code-review-skill/test-code-review-integration.sh`
- Modify: `README.md` (one line, currently `- **code-review** - Max-grade JSON-first PR/branch/diff review`)

**Interfaces:**
- Consumes: `## Before restyle` rows existing in `skills/code-review/evaluation.md` (Task 7 must be committed first — verify before starting).
- Produces: `review-protocol.md` (consumed by the shell's dispatch instruction and pinned by the test); the new shell SKILL.md whose description Task 9's runs exercise.

- [ ] **Step 1: Update the structural test first (failing)**

In `tests/code-review-skill/test-code-review-integration.sh`:

1. After the line `SKILL="$REPO_ROOT/skills/code-review/SKILL.md"`, add:

```bash
PROTOCOL="$REPO_ROOT/skills/code-review/review-protocol.md"
```

2. Replace the line `EXPECTED_SKILL_SHA256="a71428ab647d57015da21a373be371f65fc5a17ded76fd7a2397f5652869b5ae"` with:

```bash
EXPECTED_PROTOCOL_SHA256="PLACEHOLDER_UNTIL_STEP_5"
```

3. Replace the two lines

```bash
assert_sha256 "$SKILL" "$EXPECTED_SKILL_SHA256" "code-review skill matches pinned source digest"
assert_contains "$SKILL" "Review code changes with a max-grade, recall-oriented pipeline" "description exposes max-grade review trigger"
```

with:

```bash
assert_file_exists "$PROTOCOL" "review protocol file exists"
assert_sha256 "$PROTOCOL" "$EXPECTED_PROTOCOL_SHA256" "review protocol matches pinned digest"
assert_contains "$PROTOCOL" "Imported verbatim from stellarlinkco/skills@0f64fa92645442ffe47bcec39faede35a795435a" "protocol records its source provenance"
assert_contains "$SKILL" "description: Use when asked to review a pull request" "shell description is Use-when form"
assert_not_contains "$SKILL" "max-grade, recall-oriented pipeline" "shell description does not summarize the workflow"
assert_contains "$SKILL" "## When NOT to Use" "shell has When NOT to Use"
assert_contains "$SKILL" "An explicit invocation of this skill" "explicit invocation always runs this skill"
assert_contains "$SKILL" "prefer the native command" "natural-language requests defer to native max review"
assert_contains "$SKILL" "follow its phases inline" "already-dispatched reviewers execute the protocol inline"
assert_contains "$SKILL" "review-protocol.md" "shell hands off to the protocol file"
assert_contains "$SKILL" "## Red Flags" "shell has Red Flags"
assert_file_exists "$REPO_ROOT/skills/code-review/pressure-scenarios.md" "pressure scenarios exist"
assert_file_exists "$REPO_ROOT/skills/code-review/evaluation.md" "evaluation record exists"
```

4. In the block of protocol-marker assertions currently running against `$SKILL` (`"Phase 0"` through `"Run 10 independent finder angles."`, i.e. every `assert_contains "$SKILL" ...` from `"Phase 0"` to `"Run 10 independent finder angles."`), change `"$SKILL"` to `"$PROTOCOL"` on each line. Leave `assert_contains "$SKILL" "name: code-review" ...` untouched.

5. Replace the README assertion line

```bash
assert_contains "$README" "**code-review** - Max-grade JSON-first PR/branch/diff review" "README lists code-review in skills library"
```

with:

```bash
assert_contains "$README" "**code-review** - Recall-first review gate for PRs, branches, and diffs" "README lists code-review in skills library"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/code-review-skill/test-code-review-integration.sh`
Expected: FAIL — protocol file missing, shell markers missing, README line unchanged.

- [ ] **Step 3: Create review-protocol.md (verbatim move)**

```bash
{
  printf '%s\n' '<!--' \
    'Imported verbatim from stellarlinkco/skills@0f64fa92645442ffe47bcec39faede35a795435a (code-review v3.0.0).' \
    'Edits to this protocol require behavior evidence; see evaluation.md.' \
    '-->' ''
  git show HEAD:skills/code-review/SKILL.md | tail -n +12
} > skills/code-review/review-protocol.md
```

Then verify byte-identity of the body (spec acceptance):

```bash
diff <(git show HEAD:skills/code-review/SKILL.md | tail -n +12) <(tail -n +6 skills/code-review/review-protocol.md) && echo BODY-IDENTICAL
```
Expected: `BODY-IDENTICAL`.

- [ ] **Step 4: Replace SKILL.md with the house shell**

Overwrite `skills/code-review/SKILL.md` with exactly:

```markdown
---
name: code-review
version: 3.1.0
description: Use when asked to review a pull request, branch, commit, or diff, to hunt for bugs in a change, to run a security or contract review of a change, or to gate a merge on review findings
---

# Code Review

## Overview

Run a recall-first review of a code change and report verified findings.

**Core principle:** at this grade, a missed real bug is worse than a plausible
finding that needs maintainer judgment.

The full procedure lives in [review-protocol.md](review-protocol.md):
candidate generation across independent finder angles, recall-preserving
verification, a final gap sweep, and a capped findings list.

## When to Use

- Reviewing a pull request, branch, commit range, or supplied diff
- Bug hunts, security reviews, contract-break reviews, regression searches
- The final whole-branch gate in superpowers:subagent-driven-development and
  the max route in superpowers:requesting-code-review

An explicit invocation of this skill (slash command or by name) always runs
this skill.

## When NOT to Use

- A natural-language review request on a harness with a native max-grade
  review command (for example Claude Code's built-in `/code-review`): prefer
  the native command. The workflow-internal invocations named above always
  use this skill so the findings contract keeps its shape.
- Responding to review feedback you received: use
  superpowers:receiving-code-review.
- The pre-review checklist before requesting review: use
  superpowers:requesting-code-review.

## How to Run

Hand [review-protocol.md](review-protocol.md) to a fresh reviewer subagent
together with the diff and PR context, and return its findings unchanged. If
you are already a dispatched reviewer subagent (the
subagent-driven-development final gate) or the harness has no subagents, read
review-protocol.md and follow its phases inline in order. Do not review from
memory of this file.

## Output Contract

The protocol returns a JSON array of at most 15 findings ranked most-severe
first, each with `priority` (P0-P3), `file`, `line`, `category`, `summary`,
and `failure_scenario`; `[]` when nothing survives verification. When the
human asked for a readable review, present the same findings in the same
order as prose with those fields.

## Red Flags

Stop and correct course if you are:

- Reviewing without reading review-protocol.md
- Dumping raw JSON when the human asked for a readable review
- Posting PR or inline comments without an explicit ask
- Softening, dropping, or re-ranking findings so a gate passes
- Inventing findings to avoid returning `[]`

## Behavior Testing

Use [pressure-scenarios.md](pressure-scenarios.md) before changing this skill
or [review-protocol.md](review-protocol.md). Record before/after application
runs in [evaluation.md](evaluation.md); protocol edits require behavior
evidence.
```

- [ ] **Step 5: Pin the protocol digest and update README**

```bash
shasum -a 256 skills/code-review/review-protocol.md
```
Copy the printed digest into `EXPECTED_PROTOCOL_SHA256` in `tests/code-review-skill/test-code-review-integration.sh`, replacing `PLACEHOLDER_UNTIL_STEP_5`.

In `README.md`, replace the line
`- **code-review** - Max-grade JSON-first PR/branch/diff review`
with
`- **code-review** - Recall-first review gate for PRs, branches, and diffs`

- [ ] **Step 6: Run the test to verify it passes**

Run: `bash tests/code-review-skill/test-code-review-integration.sh`
Expected: `STATUS: PASSED`.

- [ ] **Step 7: Word-count sanity check on the shell**

Run: `wc -w skills/code-review/SKILL.md`
Expected: under 450 words.

- [ ] **Step 8: Commit**

```bash
git add skills/code-review/SKILL.md skills/code-review/review-protocol.md tests/code-review-skill/test-code-review-integration.sh README.md
git commit -m "Restructure code-review into house shell plus verbatim review-protocol.md"
```

---

### Task 9: code-review AFTER runs and before/after comparison

**Files:**
- Modify: `skills/code-review/evaluation.md`
- Create: 4 more transcripts under `docs/superpowers/evidence/code-review/` (via runner)

**Interfaces:**
- Consumes: runner (Task 1), prompts (Task 6), `## Before restyle` rows (Task 7), restructured skill (Task 8 committed).

- [ ] **Step 1: Run the four after-restyle sessions (GREEN)**

Using the same prompt files as Task 7 (recreate them from `skills/code-review/pressure-scenarios.md` if `/tmp` was cleared):

```bash
scripts/run-skill-evidence.sh run claude green code-review planted-bug-after /tmp/cr-planted-bug.md
scripts/run-skill-evidence.sh run codex  green code-review planted-bug-after /tmp/cr-planted-bug.md
scripts/run-skill-evidence.sh run claude green code-review clean-diff-after  /tmp/cr-clean-diff.md
scripts/run-skill-evidence.sh run codex  green code-review clean-diff-after  /tmp/cr-clean-diff.md
```

Note: the codex GREEN environment caches its plugin install. Because Task 8 changed the skill, remove the stale environment first so the runner reinstalls and its `diff -r` check passes:
`rm -rf ~/.cache/skill-evidence-scratch/codex-green`

Read every transcript and score it against the Pass Criteria.

- [ ] **Step 2: Record the after rows and the comparison**

In `skills/code-review/evaluation.md`, replace the `## After restyle` placeholder paragraph with a table of the four runs (same columns as `## Before restyle`) filled from the transcripts, followed by:

```markdown
### Before/after comparison

<2-4 sentences: for each scenario, does the after-restyle run find the same
planted bugs and keep the same output contract as the before-restyle run?
Name any regression plainly. Per the spec, after must match or improve on
before for the restyle to stand.>
```

If a regression appears (a planted bug found before but missed after, or `[]` discipline lost), record it, then STOP and report BLOCKED — the shell wording needs adjustment before this task can complete (that adjustment re-runs this task's sessions).

- [ ] **Step 3: Verify links and run the skill's structural test**

```bash
grep -o 'docs/superpowers/evidence/code-review/[A-Za-z0-9/._-]*\.md' skills/code-review/evaluation.md | sort -u | while read -r p; do [ -f "$p" ] && echo "OK $p" || echo "MISSING $p"; done
bash tests/code-review-skill/test-code-review-integration.sh
```
Expected: all `OK`; `STATUS: PASSED`.

- [ ] **Step 4: Commit**

```bash
git add skills/code-review/evaluation.md docs/superpowers/evidence/code-review/
git commit -m "Record code-review after-restyle runs and before/after comparison"
```

---

### Task 10: Full verification sweep

**Files:**
- None modified (verification only; fix regressions if any appear).

- [ ] **Step 1: Run all five skill structural tests plus shell lint**

```bash
bash tests/triaging-issues/test-triaging-issues-skill.sh
bash tests/working-from-issues/test-working-from-issues-skill.sh
bash tests/decomposing-issues/test-decomposing-issues-skill.sh
bash tests/reconciling-issues/test-reconciling-issues-skill.sh
bash tests/code-review-skill/test-code-review-integration.sh
bash tests/shell-lint/test-lint-shell.sh
```
Expected: every suite passes.

- [ ] **Step 2: Acceptance checklist against the spec**

Verify each line, quoting the evidence:
- Each of the four issue skills has ≥2 RED scenarios × 2 harnesses with committed transcripts (`ls docs/superpowers/evidence/*/` shows 4 files per issue skill).
- `skills/code-review/` has `evaluation.md` + `pressure-scenarios.md` with control, before, and after runs (9 transcripts in `docs/superpowers/evidence/code-review/`).
- `grep -rn "Expected failure mode recorded" skills/` returns nothing.
- `git diff --check main...HEAD -- ':(exclude)docs/superpowers/evidence' ':(exclude)skills/code-review/pressure-scenarios.md' ':(exclude)docs/superpowers/plans/2026-07-02-skill-evidence-and-style.md'` is clean. (The excluded files legitimately embed unified-diff fixtures whose blank context lines are a mandatory single space; `git diff --check` misreads them as trailing whitespace.)

- [ ] **Step 3: Commit any verification fixes; otherwise no commit**

If Step 1–2 forced changes, commit them as `Fix verification findings from evidence-and-restyle sweep`; otherwise this task produces no commit.
