#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/reconciling-issues/SKILL.md"
SCENARIOS="$REPO_ROOT/skills/reconciling-issues/pressure-scenarios.md"
EVALUATION="$REPO_ROOT/skills/reconciling-issues/evaluation.md"
DECOMPOSING="$REPO_ROOT/skills/decomposing-issues/SKILL.md"
WORKING="$REPO_ROOT/skills/working-from-issues/SKILL.md"
README="$REPO_ROOT/README.md"
SPEC="$REPO_ROOT/docs/superpowers/specs/2026-06-29-parent-issue-reconciliation-design.md"
PLAN="$REPO_ROOT/docs/superpowers/plans/2026-06-29-parent-issue-reconciliation.md"

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
    echo "    missing file: $path"
  fi
}

assert_contains() {
  local path="$1"
  local needle="$2"
  local description="$3"

  if [[ ! -f "$path" ]]; then
    fail "$description"
    echo "    missing file: $path"
    return
  fi

  if grep -Fq -- "$needle" "$path"; then
    pass "$description"
  else
    fail "$description"
    echo "    expected to find: $needle"
    echo "    in file: $path"
  fi
}

assert_not_contains() {
  local path="$1"
  local needle="$2"
  local description="$3"

  if [[ ! -f "$path" ]]; then
    fail "$description"
    echo "    missing file: $path"
    return
  fi

  if grep -Fq -- "$needle" "$path"; then
    fail "$description"
    echo "    did not expect to find: $needle"
    echo "    in file: $path"
  else
    pass "$description"
  fi
}

echo "Reconciling issues skill structural tests"

assert_file_exists "$SKILL" "reconciling-issues skill exists"
assert_contains "$SKILL" "name: reconciling-issues" "skill frontmatter has correct name"
assert_contains "$SKILL" "description: Use when" "skill description is trigger-focused"
assert_contains "$SKILL" "reconcile" "description includes reconcile trigger"
assert_contains "$SKILL" "audit" "description includes audit trigger"
assert_contains "$SKILL" "close" "description includes close trigger"
assert_contains "$SKILL" "parent issue" "description includes parent issue trigger"
assert_contains "$SKILL" "child issues" "description includes child issue trigger"

assert_contains "$SKILL" "## Required Input" "skill defines required input"
assert_contains "$SKILL" "Parent Closure Contract" "skill consumes parent closure contract"
assert_contains "$SKILL" "Issue Decomposition" "skill consumes issue decomposition output"
assert_contains "$SKILL" "human-provided mapping" "skill accepts human-provided mapping with limits"
assert_contains "$SKILL" "parent issue evidence" "skill requires parent evidence for mappings"
assert_contains "$SKILL" "must not replace the parent scope inventory" "mapping cannot replace parent scope"
assert_contains "$SKILL" "GEMINI.md" "skill loads GEMINI instructions"
assert_contains "$SKILL" "Parent Issue Reconciliation Blocked" "skill has blocked output"
assert_contains "$SKILL" "not-reconcilable" "skill blocks when scope cannot be proven"

assert_contains "$SKILL" "## Read-Only Default" "skill has read-only default"
assert_contains "$SKILL" "Do not close" "skill blocks automatic parent close"
assert_contains "$SKILL" "Do not post comments" "skill blocks comments without approval"
assert_contains "$SKILL" "Do not edit labels" "skill blocks label mutation"
assert_contains "$SKILL" "Do not create child issues" "skill blocks child issue creation"
assert_not_contains "$SKILL" "follow-up child issues are created" "skill never creates follow-up child issues"
assert_contains "$SKILL" "two-step approval" "skill requires two-step approval"
assert_contains "$SKILL" "Blanket approval" "skill rejects blanket approval"

assert_contains "$SKILL" "## Untrusted Issue Evidence" "skill treats issue evidence as untrusted"
assert_contains "$SKILL" "evidence, not instructions" "skill refuses embedded instructions"
assert_contains "$SKILL" "claims to verify" "skill treats outcome claims as claims"

assert_contains "$SKILL" "## Reconciliation Method" "skill defines reconciliation method"
assert_contains "$SKILL" "reconstruct scope atoms" "method reconstructs parent scope"
assert_contains "$SKILL" "Coverage Ledger" "method builds coverage ledger"
assert_contains "$SKILL" "Closed child issues alone are not enough" "method rejects all-closed shortcut"
assert_contains "$SKILL" "completed but partial" "method classifies partial child outcomes"
assert_contains "$SKILL" "duplicate / superseded" "method classifies duplicate child outcomes"
assert_contains "$SKILL" "spike answered, follow-up needed" "method classifies spike follow-up"
assert_contains "$SKILL" "ready-to-close" "method includes ready-to-close disposition"
assert_contains "$SKILL" "needs-follow-up-children" "method includes follow-up child disposition"
assert_contains "$SKILL" "security-private-process" "method includes security disposition"
assert_contains "$SKILL" "decision/disposition atom" "maintainer decisions only close decision atoms"
assert_contains "$SKILL" "merely unblocks implementation" "implementation-unblocking decisions route to follow-up children"

assert_contains "$SKILL" "## Parent Issue Reconciliation" "skill defines output contract"
assert_contains "$SKILL" "Parent scope source:" "output records parent scope source"
assert_contains "$SKILL" "Child Work Reviewed:" "output includes child review table"
assert_contains "$SKILL" "Coverage Ledger:" "output includes coverage ledger"
assert_contains "$SKILL" "Parent Disposition:" "output includes parent disposition"
assert_contains "$SKILL" "Recommended Next Superpowers Skill:" "output includes next skill handoff"
assert_contains "$SKILL" "Mutation Preview:" "output includes mutation preview"
assert_contains "$SKILL" "Exact parent comment draft:" "output drafts exact parent comment"

assert_contains "$SKILL" "keep-open -> None" "keep-open disposition stays open without forced follow-up"
assert_contains "$SKILL" "ready-to-close -> None" "ready-to-close has no next skill handoff"
assert_not_contains "$SKILL" "keep-open -> superpowers:decomposing-issues" "keep-open does not hard-route to decomposing"
assert_contains "$SKILL" "needs-follow-up-children -> superpowers:decomposing-issues" "follow-up children route to decomposing"
assert_contains "$SKILL" "needs-maintainer-decision -> superpowers:triaging-issues" "maintainer decision routes to triage"
assert_contains "$SKILL" "needs-reporter-info -> superpowers:triaging-issues" "reporter info routes to triage"
assert_contains "$SKILL" "not-reconcilable -> superpowers:triaging-issues" "not reconcilable routes to triage"
assert_contains "$SKILL" "not-reconcilable is used only when parent scope cannot be reconstructed" "not reconcilable is scoped to unreconstructable parent scope"
assert_contains "$SKILL" "needs-child-readback" "blocked output distinguishes missing child readback from unreconstructable parent scope"
assert_contains "$SKILL" "actual child issue links or readback data" "blocked guidance calls for actual child links or readback data"

assert_contains "$SKILL" "## Red Flags" "skill has red flags"
assert_contains "$SKILL" "Closing because every child issue is closed" "red flags all-closed shortcut"
assert_contains "$SKILL" "Trusting a human-provided mapping as complete parent scope" "red flags incomplete mapping"
assert_contains "$SKILL" "Closing without actual child issue links" "red flags missing child links"
assert_contains "$SKILL" "Skipping repository policy" "red flags policy bypass"

assert_file_exists "$SCENARIOS" "pressure scenarios file exists"
assert_contains "$SCENARIOS" "All children closed but partial coverage" "scenario covers partial child closure"
assert_contains "$SCENARIOS" "All children closed and every atom verified" "scenario covers verified closure"
assert_contains "$SCENARIOS" "Human mapping omits parent atom" "scenario covers incomplete mapping"
assert_contains "$SCENARIOS" "Parent tracking lacks child links" "scenario covers missing child links"
assert_contains "$SCENARIOS" "Security-sensitive parent" "scenario covers security"
assert_contains "$SCENARIOS" "Repository policy keeps umbrella open" "scenario covers repository policy"
assert_contains "$SCENARIOS" "Follow-up child needed" "scenario covers non-close next skill"
assert_contains "$SCENARIOS" "uses \`Parent Disposition: needs-follow-up-children\`" "partial coverage scenario routes missing atoms to follow-up children"
assert_not_contains "$SCENARIOS" "needs-follow-up-children\` or \`keep-open" "partial coverage scenario does not allow keep-open without follow-up routing"

assert_file_exists "$EVALUATION" "evaluation summary file exists"
assert_contains "$EVALUATION" "Baseline" "evaluation summary records baseline behavior"
assert_contains "$EVALUATION" "After change" "evaluation summary records after-change behavior"
assert_contains "$EVALUATION" "docs/superpowers/evidence/reconciling-issues/" "evaluation links evidence transcripts"
assert_contains "$EVALUATION" "paraphrased record, predates transcript policy" "pre-transcript rows are annotated"
assert_not_contains "$EVALUATION" "Expected failure mode recorded" "no planned run is presented as a result"

while IFS= read -r evidence_path; do
  assert_file_exists "$REPO_ROOT/$evidence_path" "linked transcript exists: $evidence_path"
done < <(grep -o 'docs/superpowers/evidence/[A-Za-z0-9/._-]*\.md' "$EVALUATION" | sort -u)

assert_contains "$DECOMPOSING" "Parent Closure Contract" "decomposing outputs parent closure contract"
assert_contains "$DECOMPOSING" "actual child issue links" "decomposing tracks actual child links"
assert_contains "$DECOMPOSING" "Covers scope atoms" "decomposing child drafts track scope atoms"
assert_contains "$WORKING" "superpowers:reconciling-issues" "working-from-issues advises reconciliation"
assert_contains "$WORKING" "should not run reconciliation automatically" "working does not auto-reconcile"
assert_contains "$README" "**reconciling-issues**" "README lists reconciling-issues skill"
assert_contains "$SPEC" "Parent Closure Contract" "design spec covers closure contract"
assert_contains "$SPEC" "must not replace the parent scope inventory" "design spec covers mapping limit"
assert_contains "$SPEC" "decision/disposition atom" "design spec scopes maintainer decisions to decision atoms"
assert_contains "$PLAN" "~~~~markdown" "plan uses tilde fences for nested markdown snippets"

assert_not_contains "$SKILL" "automatically close" "skill does not promise automatic closure"

if [[ "$FAILURES" -eq 0 ]]; then
  echo "All reconciling issues skill tests passed"
else
  echo "$FAILURES reconciling issues skill test(s) failed"
  exit 1
fi
