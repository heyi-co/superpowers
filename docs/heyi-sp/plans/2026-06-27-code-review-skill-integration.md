# Code Review Skill Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use heyi-sp:subagent-driven-development (recommended) or heyi-sp:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a strong JSON-first `code-review` skill and wire it into the existing review workflow without making every review heavy.

**Architecture:** Add `skills/code-review/SKILL.md` from the authorized pinned source as an independent max-review skill. Keep `requesting-code-review` as the compatibility entry point that routes ordinary review to the existing human-readable reviewer and strong review to `code-review`. Keep SDD per-task review unchanged while changing the final whole-branch review to use `code-review`.

**Tech Stack:** Markdown skills, Bash structural tests, git diffs.

## Global Constraints

- Preserve the authorized source skill's protocol shape as closely as practical.
- Use JSON-first findings with `P0`, `P1`, `P2`, and `P3` priorities.
- Support subagent-driven finder passes when subagents are available and sequential fallback when they are unavailable.
- Do not create a generic `requesting-review` router in this slice.
- Do not replace per-task SDD review with max review.
- Do not change Codex or Claude Code session-start hooks.
- Do not add GitHub PR comment automation.
- Do not automatically fix findings unless the user explicitly asks for fix mode.
- Do not add a full Drill/evals scenario in this first slice.
- Use the pinned authorized source at commit `0f64fa92645442ffe47bcec39faede35a795435a`.

---

## File Structure

- Create: `tests/code-review-skill/test-code-review-integration.sh`
  - Structural regression test for the new skill and routing docs.
- Create: `skills/code-review/SKILL.md`
  - Strong JSON-first max review skill imported from the authorized pinned source.
- Modify: `skills/requesting-code-review/SKILL.md`
  - Add review mode routing from ordinary review to `code-review` for strong review scenarios.
- Modify: `skills/subagent-driven-development/SKILL.md`
  - Point final whole-branch review at `code-review` while preserving per-task review.

---

### Task 1: Add the Standalone Code Review Skill

**Files:**
- Create: `tests/code-review-skill/test-code-review-integration.sh`
- Create: `skills/code-review/SKILL.md`

**Interfaces:**
- Consumes: Authorized source skill from `https://raw.githubusercontent.com/stellarlinkco/skills/0f64fa92645442ffe47bcec39faede35a795435a/skills/code-review/SKILL.md`
- Produces: `skills/code-review/SKILL.md` with `name: code-review` and the max-review protocol required by the spec.

- [ ] **Step 1: Create the failing structural test**

Create `tests/code-review-skill/test-code-review-integration.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/code-review/SKILL.md"

FAILURES=0

pass() {
  echo "  [PASS] $1"
}

fail() {
  echo "  [FAIL] $1"
  FAILURES=$((FAILURES + 1))
}

assert_file_exists() {
  local path="$1"
  local description="$2"

  if [[ -f "$path" ]]; then
    pass "$description"
  else
    fail "$description"
    echo "    missing path: $path"
  fi
}

assert_contains() {
  local path="$1"
  local needle="$2"
  local description="$3"

  if [[ ! -f "$path" ]]; then
    fail "$description"
    echo "    missing path: $path"
    return
  fi

  if grep -Fq -- "$needle" "$path"; then
    pass "$description"
  else
    fail "$description"
    echo "    expected to find: $needle"
  fi
}

echo "Code review skill integration tests"

assert_file_exists "$SKILL" "code-review skill exists"
assert_contains "$SKILL" "name: code-review" "skill frontmatter names code-review"
assert_contains "$SKILL" "Review code changes with a max-grade, recall-oriented pipeline" "description exposes max-grade review trigger"
assert_contains "$SKILL" "Phase 0" "skill defines Phase 0"
assert_contains "$SKILL" "Phase 1" "skill defines Phase 1"
assert_contains "$SKILL" "Phase 2" "skill defines Phase 2"
assert_contains "$SKILL" "Phase 3" "skill defines Phase 3"
assert_contains "$SKILL" "subagents are available" "skill supports subagent finder execution"
assert_contains "$SKILL" "run the same angles sequentially" "skill supports sequential fallback"
assert_contains "$SKILL" "CONFIRMED" "skill verifies confirmed candidates"
assert_contains "$SKILL" "PLAUSIBLE" "skill verifies plausible candidates"
assert_contains "$SKILL" "REFUTED" "skill drops refuted candidates"
assert_contains "$SKILL" "P0" "skill defines P0 priority"
assert_contains "$SKILL" "P1" "skill defines P1 priority"
assert_contains "$SKILL" "P2" "skill defines P2 priority"
assert_contains "$SKILL" "P3" "skill defines P3 priority"
assert_contains "$SKILL" "Return findings as a JSON array of at most 15 objects" "skill requires capped JSON output"
assert_contains "$SKILL" "return \`[]\`" "skill returns empty JSON array when no findings survive"

if [[ "$FAILURES" -gt 0 ]]; then
  echo "STATUS: FAILED ($FAILURES failure(s))"
  exit 1
fi

echo "STATUS: PASSED"
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
bash tests/code-review-skill/test-code-review-integration.sh
```

Expected:

```text
[FAIL] code-review skill exists
STATUS: FAILED
```

Additional assertions will also fail because `skills/code-review/SKILL.md` does not exist yet.

- [ ] **Step 3: Create the skill directory and import the pinned authorized source**

Run:

```bash
mkdir -p skills/code-review
curl -fsSL https://raw.githubusercontent.com/stellarlinkco/skills/0f64fa92645442ffe47bcec39faede35a795435a/skills/code-review/SKILL.md > skills/code-review/SKILL.md
```

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
bash tests/code-review-skill/test-code-review-integration.sh
```

Expected:

```text
STATUS: PASSED
```

- [ ] **Step 5: Commit the standalone skill**

Run:

```bash
git add tests/code-review-skill/test-code-review-integration.sh skills/code-review/SKILL.md
git commit -m "Add max code-review skill"
```

---

### Task 2: Route Strong Review Requests to Code Review

**Files:**
- Modify: `tests/code-review-skill/test-code-review-integration.sh`
- Modify: `skills/requesting-code-review/SKILL.md`
- Modify: `skills/subagent-driven-development/SKILL.md`

**Interfaces:**
- Consumes: `skills/code-review/SKILL.md` from Task 1.
- Produces: Routing text that tells agents when to use standard review and when to invoke `code-review`.

- [ ] **Step 1: Extend the structural test with routing assertions**

Patch `tests/code-review-skill/test-code-review-integration.sh`:

```diff
@@
 SKILL="$REPO_ROOT/skills/code-review/SKILL.md"
+REQUESTING="$REPO_ROOT/skills/requesting-code-review/SKILL.md"
+SDD="$REPO_ROOT/skills/subagent-driven-development/SKILL.md"
@@
 assert_contains "$SKILL" "Return findings as a JSON array of at most 15 objects" "skill requires capped JSON output"
 assert_contains "$SKILL" "return \`[]\`" "skill returns empty JSON array when no findings survive"
+assert_contains "$REQUESTING" "Use \`code-review\` for max review" "requesting-code-review routes max review to code-review"
+assert_contains "$REQUESTING" "ordinary review" "requesting-code-review keeps ordinary review path"
+assert_contains "$REQUESTING" "strong review" "requesting-code-review documents strong review trigger"
+assert_contains "$SDD" "Final whole-branch review: use \`code-review\`" "SDD final review uses code-review"
+assert_contains "$SDD" "Per-task reviews remain task-scoped" "SDD preserves lightweight per-task review"
```

- [ ] **Step 2: Run the test to verify routing assertions fail**

Run:

```bash
bash tests/code-review-skill/test-code-review-integration.sh
```

Expected:

```text
[FAIL] requesting-code-review routes max review to code-review
[FAIL] SDD final review uses code-review
STATUS: FAILED
```

- [ ] **Step 3: Add review mode routing to requesting-code-review**

Modify `skills/requesting-code-review/SKILL.md` by inserting this section after the "When to Request Review" section and before "How to Request":

```markdown
## Review Modes

Use ordinary review for small diffs, development checkpoints, and routine feature reviews. Ordinary review dispatches a `general-purpose` subagent with [code-reviewer.md](code-reviewer.md) and returns human-readable strengths, issues, recommendations, and a merge assessment.

Use `code-review` for max review when the user asks for a "max review", "deep review", "strong review", "comprehensive review", PR review, branch review, bug hunt, security review, contract-break review, regression search, or merge-gate review. The `code-review` skill runs the JSON-first max-review protocol and is the preferred final review for high-risk or pre-merge changes.

If max review applies, invoke `code-review` instead of filling [code-reviewer.md](code-reviewer.md).
```

Then replace the current "How to Request" intro with:

```markdown
## How to Request Ordinary Review

Use this path only when max review does not apply.
```

Leave the existing SHA and `code-reviewer.md` instructions under that renamed heading.

- [ ] **Step 4: Update requesting-code-review workflow integration text**

In `skills/requesting-code-review/SKILL.md`, replace the "Integration with Workflows" section with:

```markdown
## Integration with Workflows

**Subagent-Driven Development:**
- Per-task review uses the task-scoped SDD reviewer.
- Final whole-branch review should use `code-review` for max review.
- Fix blocking findings before finishing the branch.

**Executing Plans:**
- Use ordinary review after each task or at natural checkpoints.
- Use `code-review` before merge or when the user asks for strong review.

**Ad-Hoc Development:**
- Use ordinary review for small local checkpoints.
- Use `code-review` before merge, for PR review, or when stuck on subtle bugs.
```

In the "Red Flags" section, add:

```markdown
- Use ordinary review when the user explicitly asked for max, deep, strong, comprehensive, PR, or bug-finding review
```

- [ ] **Step 5: Update SDD final review references**

In `skills/subagent-driven-development/SKILL.md`, change the opening sentence from:

```markdown
Execute plan by dispatching a fresh implementer subagent per task, a task review (spec compliance + code quality) after each, and a broad whole-branch review at the end.
```

to:

```markdown
Execute plan by dispatching a fresh implementer subagent per task, a task review (spec compliance + code quality) after each, and a broad max-grade `code-review` whole-branch review at the end.
```

Change the core principle from:

```markdown
**Core principle:** Fresh subagent per task + task review (spec + quality) + broad final review = high quality, fast iteration
```

to:

```markdown
**Core principle:** Fresh subagent per task + task-scoped review (spec + quality) + final max `code-review` = high quality, fast iteration
```

After the paragraph that starts `Per-task reviews are task-scoped gates`, insert:

```markdown
Per-task reviews remain task-scoped. Do not run max review after every task.
The final whole-branch review is the max review gate.
```

In the flowchart, replace each occurrence of:

```text
Dispatch final code reviewer subagent (../requesting-code-review/code-reviewer.md)
```

with:

```text
Final whole-branch review: use `code-review`
```

In "Prompt Templates", replace:

```markdown
- Final whole-branch review: use superpowers:requesting-code-review's [code-reviewer.md](../requesting-code-review/code-reviewer.md)
```

with:

```markdown
- Final whole-branch review: use `code-review`
```

In "Integration", replace:

```markdown
- **superpowers:requesting-code-review** - Code review template for the final whole-branch review
```

with:

```markdown
- **superpowers:code-review** - Max-grade JSON-first review for the final whole-branch review
```

- [ ] **Step 6: Run the routing test to verify it passes**

Run:

```bash
bash tests/code-review-skill/test-code-review-integration.sh
```

Expected:

```text
STATUS: PASSED
```

- [ ] **Step 7: Run shell syntax verification for the new test**

Run:

```bash
bash -n tests/code-review-skill/test-code-review-integration.sh
```

Expected: no output and exit code 0.

- [ ] **Step 8: Commit routing integration**

Run:

```bash
git add tests/code-review-skill/test-code-review-integration.sh skills/requesting-code-review/SKILL.md skills/subagent-driven-development/SKILL.md
git commit -m "Route strong reviews to code-review"
```

---

## Final Verification

Run:

```bash
bash tests/code-review-skill/test-code-review-integration.sh
bash -n tests/code-review-skill/test-code-review-integration.sh
git status --short
```

Expected:

```text
STATUS: PASSED
```

`git status --short` should show no uncommitted changes after both task commits.

Manual smoke check:

1. Ask the agent to use `code-review` on a small real or synthetic diff.
2. Confirm the result begins with a JSON array.
3. Confirm findings include concrete `failure_scenario` values rather than broad summaries.
4. Confirm `[]` is returned if no findings survive verification.

## Spec Coverage Self-Check

- Add `skills/code-review/SKILL.md`: Task 1.
- Keep source protocol close to the authorized version: Task 1 imports from pinned commit.
- JSON-first `P0` / `P1` / `P2` / `P3` findings: Task 1 structural assertions.
- Subagent finder and sequential fallback: Task 1 structural assertions.
- Route strong review requests: Task 2.
- Update SDD final whole-branch review: Task 2.
- Keep per-task SDD lightweight: Task 2.
- Defer generic review router, hooks, PR comments, fix automation, and full evals: preserved by not adding those files or workflows.
