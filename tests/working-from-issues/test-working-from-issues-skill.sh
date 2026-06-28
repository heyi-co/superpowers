#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/working-from-issues/SKILL.md"
SCENARIOS="$REPO_ROOT/skills/working-from-issues/pressure-scenarios.md"
EVALUATION="$REPO_ROOT/skills/working-from-issues/evaluation.md"
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

echo "Working from issues skill structural tests"

assert_file_exists "$SKILL" "working-from-issues skill exists"
assert_contains "$SKILL" "name: working-from-issues" "skill frontmatter has correct name"
assert_contains "$SKILL" "description: Use when" "skill description is trigger-focused"
assert_contains "$SKILL" "GitHub issue" "description includes GitHub issue trigger"
assert_contains "$SKILL" "fix" "description includes fix trigger"
assert_contains "$SKILL" "implement" "description includes implementation trigger"
assert_contains "$SKILL" "resolve" "description includes resolution trigger"

assert_contains "$SKILL" "## Required Input" "skill requires triage result input"
assert_contains "$SKILL" "Triage Result" "skill consumes Triage Result"
assert_contains "$SKILL" "superpowers:triaging-issues" "skill invokes triaging when no triage result exists"
assert_contains "$SKILL" "Do not start from a raw issue" "skill blocks raw issue implementation"
assert_contains "$SKILL" "Actionability:" "skill keys routing on actionability"
assert_contains "$SKILL" "do not re-run triage" "skill avoids re-triaging valid triage results"
assert_contains "$SKILL" "Consume the existing" "skill consumes existing actionability directly"

assert_contains "$SKILL" "## GitHub Mutation Gate" "skill keeps GitHub mutation approval-gated"
assert_contains "$SKILL" "Do not post comments" "skill blocks issue comments without approval"
assert_contains "$SKILL" "Do not edit labels" "skill blocks label edits without approval"
assert_contains "$SKILL" "Do not create child issues" "skill blocks child issue creation without approval"

assert_contains "$SKILL" "ready-for-debugging" "skill handles ready-for-debugging"
assert_contains "$SKILL" "superpowers:systematic-debugging" "debug route uses systematic debugging"
assert_contains "$SKILL" "superpowers:test-driven-development" "debug route uses TDD for fixes"
assert_contains "$SKILL" "superpowers:requesting-code-review" "debug route requires review"
assert_contains "$SKILL" "ready-for-design" "skill handles ready-for-design"
assert_contains "$SKILL" "superpowers:brainstorming" "design route uses brainstorming"
assert_contains "$SKILL" "superpowers:writing-plans" "design route uses writing-plans"
assert_contains "$SKILL" "superpowers:subagent-driven-development" "design route uses SDD after planning"
assert_contains "$SKILL" "ready-for-docs-fix" "skill handles ready-for-docs-fix"
assert_contains "$SKILL" "doc tests" "docs route checks for doc tests"
assert_contains "$SKILL" "support-answerable" "skill handles support-answerable"
assert_contains "$SKILL" "needs-reporter-info" "skill handles needs-reporter-info"
assert_contains "$SKILL" "duplicate" "skill handles duplicate"
assert_contains "$SKILL" "not-repo-owned" "skill handles not-repo-owned"
assert_contains "$SKILL" "out-of-scope" "skill handles out-of-scope"
assert_contains "$SKILL" "security-private-process" "skill handles security-private-process"
assert_contains "$SKILL" "needs-maintainer-decision" "skill handles needs-maintainer-decision"
assert_contains "$SKILL" "needs-decomposition" "skill handles needs-decomposition"
assert_contains "$SKILL" "blocked-by-resolution-loop" "skill handles blocked-by-resolution-loop"

assert_contains "$SKILL" "## Stop States" "skill defines stop states"
assert_contains "$SKILL" "Do not write code" "stop states do not write code"
assert_contains "$SKILL" "## Resolution Loop Guard" "skill has resolution loop guard"
assert_contains "$SKILL" "two full blocking fix/re-review cycles" "skill stops after repeated blocking cycles"
assert_contains "$SKILL" "return to superpowers:triaging-issues" "skill returns to triage when scope changes"
assert_contains "$SKILL" "## Proposed Split" "skill defines split proposal"
assert_contains "$SKILL" "Child 1:" "split proposal includes child issue draft"

assert_file_exists "$SCENARIOS" "pressure scenarios file exists"
assert_contains "$SCENARIOS" "Raw issue without Triage Result" "scenarios include raw issue precondition"
assert_contains "$SCENARIOS" "Actionable bug route" "scenarios include debug route"
assert_contains "$SCENARIOS" "Feature request route" "scenarios include design route"
assert_contains "$SCENARIOS" "Support answer stop" "scenarios include support stop"
assert_contains "$SCENARIOS" "Duplicate stop" "scenarios include duplicate stop"
assert_contains "$SCENARIOS" "Security stop" "scenarios include security stop"
assert_contains "$SCENARIOS" "Needs decomposition stop" "scenarios include decomposition stop"
assert_contains "$SCENARIOS" "Resolution loop guard" "scenarios include resolution loop guard"
assert_contains "$SCENARIOS" "GitHub mutation pressure" "scenarios include mutation pressure"

assert_file_exists "$EVALUATION" "evaluation summary file exists"
assert_contains "$EVALUATION" "Baseline" "evaluation summary records baseline behavior"
assert_contains "$EVALUATION" "After change" "evaluation summary records after-change behavior"
assert_contains "$EVALUATION" "Full pressure matrix" "evaluation summary records full pressure matrix"
assert_contains "$EVALUATION" "Codex CLI 0.142.3" "evaluation summary records Codex version"
assert_contains "$EVALUATION" "Claude Code 2.1.185" "evaluation summary records Claude version"

assert_contains "$README" "**working-from-issues**" "README lists working-from-issues skill"

if [[ "$FAILURES" -eq 0 ]]; then
  echo "All working from issues skill tests passed"
else
  echo "$FAILURES working from issues skill test(s) failed"
  exit 1
fi
