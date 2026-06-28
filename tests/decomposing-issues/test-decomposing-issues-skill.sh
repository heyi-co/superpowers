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
assert_contains "$SKILL" "Gaps / Decisions Needed:" "output includes gaps and decisions"
assert_contains "$SKILL" "Mutation Preview:" "output includes mutation preview"

assert_contains "$SKILL" "## GitHub Mutation Gate" "skill has mutation gate"
assert_contains "$SKILL" "two-step approval" "skill requires two-step approval"
assert_contains "$SKILL" "exact child issue title/body" "skill previews exact child issue payload"
assert_contains "$SKILL" "Blanket approval" "skill rejects blanket approval"
assert_contains "$SKILL" "confirmed that version" "skill requires approval of exact draft"
assert_contains "$SKILL" "Mutation Preview" "skill makes mutation preview explicit"
assert_contains "$SKILL" "no GitHub mutation was performed" "skill reports no mutation under pressure"

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

assert_file_exists "$EVALUATION" "evaluation summary file exists"
assert_contains "$EVALUATION" "Baseline" "evaluation summary records baseline behavior"
assert_contains "$EVALUATION" "After change" "evaluation summary records after-change behavior"

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
