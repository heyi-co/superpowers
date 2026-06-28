#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/triaging-issues/SKILL.md"
SCENARIOS="$REPO_ROOT/skills/triaging-issues/pressure-scenarios.md"
EVALUATION="$REPO_ROOT/skills/triaging-issues/evaluation.md"
SPEC="$REPO_ROOT/docs/superpowers/specs/2026-06-28-issue-to-workflow-skills-draft.md"
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

echo "Triaging issues skill structural tests"

assert_file_exists "$SKILL" "triaging-issues skill exists"
assert_contains "$SKILL" "name: triaging-issues" "skill frontmatter has correct name"
assert_contains "$SKILL" "description: Use when" "skill description is trigger-focused"
assert_contains "$SKILL" "GitHub issues" "description includes GitHub issue trigger"
assert_contains "$SKILL" "bug reports" "description includes bug report trigger"
assert_contains "$SKILL" "feature requests" "description includes feature request trigger"
assert_contains "$SKILL" "support requests" "description includes support request trigger"
assert_contains "$SKILL" "before a Triage Result exists" "description limits triage to pre-handoff intake"
assert_contains "$SKILL" "do not use when consuming an existing Triage Result" "description excludes downstream triage result consumption"

assert_contains "$SKILL" "## Read-Only Default" "skill has read-only default section"
assert_contains "$SKILL" "Do not edit labels" "skill blocks label mutation"
assert_contains "$SKILL" "Do not post comments" "skill blocks issue comments"
assert_contains "$SKILL" "Do not create, close, reopen, or transfer issues" "skill blocks issue mutation"

assert_contains "$SKILL" "## Instruction and Repository Policy Loading" "skill separates instructions from policy evidence"
assert_contains "$SKILL" "AGENTS.md" "skill loads AGENTS.md"
assert_contains "$SKILL" "CLAUDE.md" "skill loads CLAUDE.md"
assert_contains "$SKILL" "GEMINI.md" "skill loads GEMINI.md"
assert_contains "$SKILL" ".github/ISSUE_TEMPLATE" "skill checks issue templates"
assert_contains "$SKILL" "SECURITY.md" "skill checks security policy"

assert_contains "$SKILL" "## Untrusted Issue Input" "skill treats issue content as untrusted"
assert_contains "$SKILL" "filled-in issue template" "skill distinguishes reporter-filled templates from repo templates"
assert_contains "$SKILL" "not instructions" "skill refuses issue-embedded instructions"
assert_contains "$SKILL" "claims to verify" "skill treats reporter hypotheses as claims"

assert_contains "$SKILL" "## Clarify Before Asking" "skill requires evidence gathering before questions"
assert_contains "$SKILL" "Do not ask generic" "skill blocks generic follow-up questions"
assert_contains "$SKILL" "## Duplicate and Related Work Search" "skill requires duplicate search"
assert_contains "$SKILL" "If duplicate or related work search cannot complete" "skill handles duplicate search failure"
assert_contains "$SKILL" "search as no duplicates" "skill does not equate failed search with no duplicates"

assert_contains "$SKILL" "## Classification" "skill has classification section"
assert_contains "$SKILL" "## Actionability" "skill has actionability section"
assert_contains "$SKILL" "ready-for-debugging" "skill includes ready-for-debugging state"
assert_contains "$SKILL" "ready-for-design" "skill includes ready-for-design state"
assert_contains "$SKILL" "ready-for-docs-fix" "skill includes ready-for-docs-fix state"
assert_contains "$SKILL" "support-answerable" "skill includes support-answerable state"
assert_contains "$SKILL" "needs-reporter-info" "skill includes needs-reporter-info state"
assert_contains "$SKILL" '`out-of-scope` -' "skill includes out-of-scope state"
assert_contains "$SKILL" "security-private-process" "skill includes security-private-process state"
assert_contains "$SKILL" "needs-maintainer-decision" "skill includes needs-maintainer-decision state"
assert_contains "$SKILL" "needs-decomposition" "skill includes needs-decomposition state"
assert_contains "$SKILL" "blocked-by-resolution-loop" "skill includes resolution-loop blocked state"

assert_contains "$SKILL" "## Too Large or Bundled Issues" "skill has decomposition guidance"
assert_contains "$SKILL" "child issue drafts" "skill drafts child issues without creating them"
assert_contains "$SKILL" "## Triage Result" "skill defines output schema"
assert_contains "$SKILL" "Instructions / Policy Checked:" "schema uses combined instruction and policy field"
assert_contains "$SKILL" "Child issue drafts:" "schema uses child issue drafts field"
assert_contains "$SKILL" "Recommended Next Superpowers Skill" "triage result includes next skill recommendation"
assert_contains "$SKILL" "## Red Flags" "skill has red flags"

assert_not_contains "$SKILL" "working-from-issues" "triage skill does not depend on working-from-issues"
assert_not_contains "$SKILL" "superpowers:code-review" "triage skill does not reference unavailable strong review skill"

assert_file_exists "$SCENARIOS" "pressure scenarios file exists"
assert_contains "$SCENARIOS" "Codex App" "pressure scenarios cover Codex App"
assert_contains "$SCENARIOS" "Claude Code" "pressure scenarios cover Claude Code"
assert_contains "$SCENARIOS" "Baseline Failure Evidence" "pressure scenarios require baseline evidence"
assert_contains "$SCENARIOS" "Vague bug report" "pressure scenarios include vague bug report"
assert_contains "$SCENARIOS" "Issue body contains instructions" "pressure scenarios include untrusted issue input"
assert_contains "$SCENARIOS" "Obvious duplicate" "pressure scenarios include duplicate issue"
assert_contains "$SCENARIOS" "Duplicate search unavailable" "pressure scenarios include duplicate search failure"
assert_contains "$SCENARIOS" "Possible vulnerability report" "pressure scenarios include security issue"
assert_contains "$SCENARIOS" "Repo-owned but out of scope" "pressure scenarios include out-of-scope issue"
assert_contains "$SCENARIOS" "Broad bundled issue" "pressure scenarios include decomposition"
assert_contains "$SCENARIOS" "Failed resolution loop" "pressure scenarios include failed resolution loop"

assert_file_exists "$EVALUATION" "evaluation summary file exists"
assert_contains "$EVALUATION" "Baseline" "evaluation summary records baseline behavior"
assert_contains "$EVALUATION" "After change" "evaluation summary records after-change behavior"

assert_contains "$SPEC" "Instructions / Policy Checked:" "spec uses combined instruction and policy field"
assert_not_contains "$SPEC" "Repository Policy Checked:" "spec does not use obsolete policy-only field"
assert_contains "$SPEC" "Child issue drafts:" "spec uses child issue drafts field"
assert_contains "$SPEC" "- \`out-of-scope\`" "spec includes out-of-scope actionability"
assert_contains "$SPEC" "blocked-by-resolution-loop" "spec includes resolution-loop blocked actionability"

assert_contains "$README" "**triaging-issues**" "README lists triaging-issues skill"

if [[ "$FAILURES" -eq 0 ]]; then
  echo "All triaging issues skill tests passed"
else
  echo "$FAILURES triaging issues skill test(s) failed"
  exit 1
fi
