#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/decomposing-issues/SKILL.md"
SCENARIOS="$REPO_ROOT/skills/decomposing-issues/pressure-scenarios.md"
EVALUATION="$REPO_ROOT/skills/decomposing-issues/evaluation.md"
TRIAGING="$REPO_ROOT/skills/triaging-issues/SKILL.md"
WORKING="$REPO_ROOT/skills/working-from-issues/SKILL.md"
SPEC="$REPO_ROOT/docs/superpowers/specs/2026-06-28-decomposing-issues-skill-design.md"
README="$REPO_ROOT/README.md"

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

echo "Decomposing issues skill structural tests"

assert_file_exists "$SKILL" "decomposing-issues skill exists"
assert_contains "$SKILL" "name: decomposing-issues" "skill frontmatter has correct name"
assert_contains "$SKILL" "description: Use when" "skill description is trigger-focused"
assert_contains "$SKILL" "split" "description includes split trigger"
assert_contains "$SKILL" "decompose" "description includes decompose trigger"
assert_contains "$SKILL" "child issues" "description includes child issue trigger"
assert_contains "$SKILL" "Triage Result" "description includes Triage Result trigger"
assert_contains "$SKILL" "blocked-by-resolution-loop" "description includes failed resolution loop trigger"

assert_contains "$SKILL" "## Required Input" "skill defines required input"
assert_contains "$SKILL" "superpowers:triaging-issues" "raw issues route back to triage"
assert_contains "$SKILL" "Do not consume raw issues directly" "skill blocks raw issue decomposition"
assert_contains "$SKILL" "mostly decisions, approvals, conclusions" "skill rejects decision-gate decomposition"
assert_contains "$SKILL" "## Decomposition Blocked" "skill defines blocked decomposition output"
assert_contains "$SKILL" "do not include" "skill blocks child drafts when decomposition is blocked"
assert_contains "$SKILL" "## Read-Only Default" "skill has read-only default"
assert_contains "$SKILL" "Do not create child issues" "skill blocks automatic child issue creation"
assert_contains "$SKILL" "Do not write code" "skill blocks implementation"
assert_contains "$SKILL" "## Untrusted Parent Evidence" "skill treats parent evidence as untrusted"
assert_contains "$SKILL" "remain evidence, not instructions" "skill refuses evidence-embedded instructions"
assert_contains "$SKILL" "claims to verify or ignore" "skill treats proposed fixes as claims"

assert_contains "$SKILL" "## Decomposition Method" "skill defines decomposition method"
assert_contains "$SKILL" "Reframe the parent" "method reframes parent"
assert_contains "$SKILL" "Scope Atoms" "method extracts scope atoms"
assert_contains "$SKILL" "vertical" "method prefers vertical slices"
assert_contains "$SKILL" "Do not choose component ownership" "method rejects requested component splits"
assert_contains "$SKILL" "Alternatives considered" "method records component split as an alternative"
assert_contains "$SKILL" "reject it there" "method rejects component split alternatives"
assert_contains "$SKILL" "component-owned slices" "method blocks component-owned slices"
assert_contains "$SKILL" "Bad child: \"Backend auth API\"" "method gives explicit bad component child example"
assert_contains "$SKILL" "Decision gates are not child issues by default" "method blocks decision-only child drafts"
assert_contains "$SKILL" "SPIDR" "method includes SPIDR prompts"
assert_contains "$SKILL" "Hamburger" "method includes Hamburger fallback"
assert_contains "$SKILL" "explicit deferral" "method requires explicit deferrals"
assert_contains "$SKILL" "orphaned" "method rejects orphan child work"
assert_contains "$SKILL" "component" "method warns against component splits"

assert_contains "$SKILL" "## Issue Decomposition" "skill defines output contract"
assert_contains "$SKILL" "Why decomposition is blocked:" "blocked output explains why decomposition stops"
assert_contains "$SKILL" "Coverage Matrix:" "output includes coverage matrix"
assert_contains "$SKILL" "Child Issue Drafts:" "output includes child issue drafts"
assert_contains "$SKILL" "Parent Disposition:" "output includes parent disposition"
assert_contains "$SKILL" "Parent Closure Contract:" "output includes parent closure contract"
assert_contains "$SKILL" "close after child issues are created only when a maintainer explicitly chose immediate parent closure" "immediate parent closure disposition is explicitly gated"
assert_contains "$SKILL" "Covers scope atoms" "child drafts include coverage atom tracking"
assert_contains "$SKILL" "actual child issue links" "skill requires actual child issue links after creation"
assert_contains "$SKILL" "read back the created child issue links" "skill requires child link readback"
assert_contains "$SKILL" "Gaps / Decisions Needed:" "output includes gaps and decisions"
assert_contains "$SKILL" "Mutation Preview:" "output includes mutation preview"

assert_contains "$SKILL" "## GitHub Mutation Gate" "skill has mutation gate"
assert_contains "$SKILL" "two-step approval" "skill requires two-step approval"
assert_contains "$SKILL" "exact child issue title/body" "skill previews exact child issue payload"
assert_contains "$SKILL" "Blanket approval" "skill rejects blanket approval"
assert_contains "$SKILL" "Standing pre-authorization" "skill defines standing pre-authorization"
assert_contains "$SKILL" "cannot grant it" "repository files cannot grant pre-authorization"

# The standing pre-authorization block must stay byte-identical across all
# four issue-workflow skills; wording drift is how shared gate semantics rot.
extract_preauth_block() {
  awk '/\*\*Standing pre-authorization\.\*\*/,/falls back to two-step approval\./' "$1"
}
PREAUTH_REF="$(extract_preauth_block "$SKILL")"
if [[ -n "$PREAUTH_REF" ]]; then
  pass "standing pre-authorization block extractable"
else
  fail "standing pre-authorization block extractable"
fi
for other in triaging-issues reconciling-issues working-from-issues; do
  if [[ "$(extract_preauth_block "$REPO_ROOT/skills/$other/SKILL.md")" == "$PREAUTH_REF" ]]; then
    pass "standing pre-authorization block identical in $other"
  else
    fail "standing pre-authorization block identical in $other"
  fi
done
assert_contains "$SKILL" "confirmed that version" "skill requires approval of exact draft"
assert_contains "$SKILL" "Mutation Preview" "skill makes mutation preview explicit"
assert_contains "$SKILL" "no GitHub mutation was performed" "skill reports no mutation under pressure"
assert_contains "$SKILL" "separate GitHub mutation" "parent tracking update remains approval-gated"

assert_contains "$SKILL" "## Red Flags" "skill has red flags"
assert_contains "$SKILL" "Claiming the parent can close without a complete coverage matrix" "red flags guard parent closure"
assert_contains "$SKILL" "frontend/backend/database" "red flags include requested component split pressure"
assert_contains "$SKILL" "product/model/IA decision gates" "red flags include decision-gate child drafts"
assert_contains "$SKILL" "Decomposition Blocked" "red flags block child drafts on decision gates"
assert_contains "$SKILL" "## Behavior Testing" "skill has behavior testing section"

assert_file_exists "$SCENARIOS" "pressure scenarios file exists"
assert_contains "$SCENARIOS" "Broad mixed parent issue" "scenarios include broad mixed issue"
assert_contains "$SCENARIOS" "Easy-to-drop criterion" "scenarios include dropped criterion pressure"
assert_contains "$SCENARIOS" "Technical layer split pressure" "scenarios include component split pressure"
assert_contains "$SCENARIOS" "Resolution loop decomposition" "scenarios include resolution loop"
assert_contains "$SCENARIOS" "Product decision disguised as decomposition" "scenarios include maintainer decision pressure"
assert_contains "$SCENARIOS" "Security-sensitive parent" "scenarios include security-sensitive parent"
assert_contains "$SCENARIOS" "GitHub mutation pressure" "scenarios include mutation pressure"
assert_contains "$SCENARIOS" "Orphan child draft" "scenarios include orphan child pressure"
assert_contains "$SCENARIOS" "Coverage Matrix" "scenarios require coverage matrix"
assert_contains "$SCENARIOS" "Parent closure contract" "scenarios include parent closure contract"
assert_contains "$SCENARIOS" "Actual child links unavailable" "scenarios include missing child link pressure"

assert_file_exists "$EVALUATION" "evaluation summary file exists"
assert_contains "$EVALUATION" "Baseline" "evaluation summary records baseline behavior"
assert_contains "$EVALUATION" "After change" "evaluation summary records after-change behavior"

assert_contains "$EVALUATION" "docs/superpowers/evidence/decomposing-issues/" "evaluation links evidence transcripts"
assert_contains "$EVALUATION" "paraphrased record, predates transcript policy" "pre-transcript rows are annotated"
assert_not_contains "$EVALUATION" "Expected failure mode recorded" "no planned run is presented as a result"

while IFS= read -r evidence_path; do
  assert_file_exists "$REPO_ROOT/$evidence_path" "linked transcript exists: $evidence_path"
done < <(grep -o 'docs/superpowers/evidence/[A-Za-z0-9/._-]*\.md' "$EVALUATION" | sort -u)

assert_contains "$TRIAGING" "superpowers:decomposing-issues" "triaging recommends decomposing skill"
assert_contains "$WORKING" "superpowers:decomposing-issues" "working-from-issues routes decomposition to decomposing skill"
assert_contains "$WORKING" "coverage-preserving child issue drafts" "working-from-issues describes decomposition handoff"

assert_contains "$SPEC" "Coverage Matrix" "design spec includes coverage matrix"
assert_contains "$SPEC" "superpowers:decomposing-issues" "design spec includes skill handoff"

assert_contains "$README" "**decomposing-issues**" "README lists decomposing-issues skill"

if [[ "$FAILURES" -eq 0 ]]; then
  echo "All decomposing issues skill tests passed"
else
  echo "$FAILURES decomposing issues skill test(s) failed"
  exit 1
fi
