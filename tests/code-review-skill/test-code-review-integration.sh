#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/code-review/SKILL.md"
PROTOCOL="$REPO_ROOT/skills/code-review/review-protocol.md"
REQUESTING="$REPO_ROOT/skills/requesting-code-review/SKILL.md"
SDD="$REPO_ROOT/skills/subagent-driven-development/SKILL.md"
README="$REPO_ROOT/README.md"
EXPECTED_PROTOCOL_SHA256="a1df58f23b3e2542e5390b2c828f5b5939a11956d04d81ac4456a20de7a0b338"

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

assert_not_contains() {
  local path="$1"
  local needle="$2"
  local description="$3"

  if [[ ! -f "$path" ]]; then
    fail "$description"
    echo "    missing path: $path"
    return
  fi

  if grep -Fq -- "$needle" "$path"; then
    fail "$description"
    echo "    expected not to find: $needle"
  else
    pass "$description"
  fi
}

assert_sha256() {
  local path="$1"
  local expected="$2"
  local description="$3"

  if [[ ! -f "$path" ]]; then
    fail "$description"
    echo "    missing path: $path"
    return
  fi

  local actual
  actual="$(shasum -a 256 "$path" | awk '{print $1}')"

  if [[ "$actual" == "$expected" ]]; then
    pass "$description"
  else
    fail "$description"
    echo "    expected sha256: $expected"
    echo "    actual sha256:   $actual"
  fi
}

echo "Code review skill integration tests"

assert_file_exists "$SKILL" "code-review skill exists"
assert_file_exists "$PROTOCOL" "review protocol file exists"
assert_sha256 "$PROTOCOL" "$EXPECTED_PROTOCOL_SHA256" "review protocol matches pinned digest"
assert_contains "$PROTOCOL" "Imported from stellarlinkco/skills@0f64fa92645442ffe47bcec39faede35a795435a" "protocol records its source provenance"
assert_contains "$PROTOCOL" "local fork revisions recorded in evaluation.md" "protocol discloses local revisions"
assert_contains "$SKILL" "name: code-review" "skill frontmatter names code-review"
assert_contains "$SKILL" "description: Use when asked for a max, deep, or comprehensive review" "shell description is Use-when form scoped to max review"
assert_not_contains "$SKILL" "max-grade, recall-oriented pipeline" "shell description does not summarize the workflow"
assert_contains "$SKILL" "## When NOT to Use" "shell has When NOT to Use"
assert_contains "$SKILL" "An explicit invocation of this skill" "explicit invocation always runs this skill"
assert_contains "$SKILL" "prefer the native command" "natural-language requests defer to native max review"
assert_contains "$SKILL" "follow its phases inline" "already-dispatched reviewers execute the protocol inline"
assert_contains "$SKILL" "review-protocol.md" "shell hands off to the protocol file"
assert_contains "$SKILL" "## Gate Semantics" "shell defines authoritative gate semantics"
assert_contains "$SKILL" "P0 and P1 findings block finishing" "gate semantics mark P0/P1 blocking"
assert_contains "$SKILL" "P2 and P3 findings are non-blocking" "gate semantics mark P2/P3 non-blocking by default"
assert_contains "$SKILL" "P2 findings require adjudication by your human partner" "gate semantics route P2 findings to human adjudication"
assert_contains "$SKILL" "re-verify with a review scoped to the fixed" "gate semantics scope post-fix re-review to the fix wave"
assert_contains "$SKILL" "Rerun the full protocol only" "gate semantics reserve full reruns for broad fix waves"
assert_not_contains "$SKILL" "P0, P1, and P2 findings block finishing" "gate semantics no longer block on P2"
assert_contains "$SKILL" "A routine, low-risk review" "shell routes routine reviews away from max"
assert_contains "$SKILL" "the latest run's labels are authoritative" "gate semantics pin rerun label drift to latest run"
assert_contains "$SKILL" "Circuit breaker" "gate semantics define a fix-rerun circuit breaker"
assert_contains "$SKILL" "## Red Flags" "shell has Red Flags"
assert_file_exists "$REPO_ROOT/skills/code-review/pressure-scenarios.md" "pressure scenarios exist"
assert_file_exists "$REPO_ROOT/skills/code-review/evaluation.md" "evaluation record exists"
assert_contains "$PROTOCOL" "Phase 0" "skill defines Phase 0"
assert_contains "$PROTOCOL" "Phase 1" "skill defines Phase 1"
assert_contains "$PROTOCOL" "Phase 2" "skill defines Phase 2"
assert_contains "$PROTOCOL" "Phase 3" "skill defines Phase 3"
assert_contains "$PROTOCOL" "subagents are available" "skill supports subagent finder execution"
assert_contains "$PROTOCOL" "run the same angles sequentially" "skill supports sequential fallback"
assert_contains "$PROTOCOL" "CONFIRMED" "skill verifies confirmed candidates"
assert_contains "$PROTOCOL" "PLAUSIBLE" "skill verifies plausible candidates"
assert_contains "$PROTOCOL" "REFUTED" "skill drops refuted candidates"
assert_contains "$PROTOCOL" "P0" "skill defines P0 priority"
assert_contains "$PROTOCOL" "P1" "skill defines P1 priority"
assert_contains "$PROTOCOL" "P2" "skill defines P2 priority"
assert_contains "$PROTOCOL" "P3" "skill defines P3 priority"
assert_contains "$PROTOCOL" "Return findings as a JSON array of at most 15 objects" "skill requires capped JSON output"
assert_contains "$PROTOCOL" "return \`[]\`" "skill returns empty JSON array when no findings survive"
assert_contains "$PROTOCOL" "Run 11 independent finder angles." "finder-angle count matches the eleven defined angles"
assert_contains "$REQUESTING" "Use \`code-review\` for max review" "requesting-code-review routes max review to code-review"
assert_contains "$REQUESTING" "Ordinary review is the default" "requesting-code-review makes ordinary review the default"
assert_contains "$REQUESTING" "routine branch or PR merge gates" "requesting-code-review keeps routine merge gates on ordinary review"
assert_contains "$REQUESTING" "strong review" "requesting-code-review documents strong review trigger"
assert_contains "$REQUESTING" "when the user explicitly asks" "requesting-code-review scopes max review to explicit asks and risk"
assert_contains "$REQUESTING" "high-risk" "requesting-code-review escalates high-risk changes to max review"
assert_contains "$REQUESTING" "P0 and P1 findings are blocking" "requesting-code-review marks P0/P1 as blocking"
assert_contains "$REQUESTING" "P2 findings are non-blocking by default" "requesting-code-review marks P2 as non-blocking by default"
assert_contains "$REQUESTING" "present each one to your human partner to fix now or track as follow-up" "requesting-code-review routes P2 findings to human adjudication"
assert_contains "$REQUESTING" "P3 findings are non-blocking by default" "requesting-code-review marks P3 as non-blocking by default"
assert_not_contains "$REQUESTING" "P0, P1, and P2 findings are blocking" "requesting-code-review no longer blocks on P2"
assert_contains "$SDD" "ordinary review by default" "SDD final review defaults to ordinary review"
assert_contains "$SDD" "when the branch is high-risk, large, or your human" "SDD escalates final review to max on risk, size, or request"
assert_contains "$SDD" "Per-task reviews remain task-scoped" "SDD preserves lightweight per-task review"
assert_contains "$SDD" "Dispatch a fresh final reviewer subagent (ordinary review, or \`code-review\` when high-risk or large)" "SDD dispatches fresh final reviewer subagent with mode routing"
assert_contains "$SDD" "plan file, progress ledger, final review package" "SDD passes plan, ledger, and review package to final review"
assert_contains "$SDD" "Blocking findings (Critical/Important from ordinary review, P0/P1 from \`code-review\`) block finishing" "SDD blocks finishing on blocking findings only"
assert_contains "$SDD" "P2 findings from \`code-review\` go to your human partner" "SDD routes P2 findings to human adjudication"
assert_contains "$SDD" "P3 findings are non-blocking by default" "SDD keeps P3 findings non-blocking by default"
assert_not_contains "$SDD" "P0, P1, and P2 findings block finishing" "SDD no longer blocks finishing on P2"
assert_contains "$SDD" "If the final whole-branch review returns blocking findings" "SDD final-review fix wave only triggers on blocking findings"
assert_contains "$SDD" "If a per-task reviewer finds blocking issues" "SDD scopes generic reviewer fix loop to per-task review"
assert_contains "$SDD" "If final \`code-review\` returns findings" "SDD separately handles final code-review findings"
assert_contains "$SDD" "P3 findings are non-blocking by default; record them or fix them only when judgment or user direction says they are worth the churn" "SDD prevents P3-only final review churn"
assert_not_contains "$SDD" "**If reviewer finds issues:**" "SDD removes ambiguous generic reviewer fix loop"
assert_not_contains "$SDD" "If the final whole-branch review returns findings" "SDD avoids treating every final-review finding as blocking"
assert_contains "$SDD" "Proceed with unfixed blocking issues" "SDD red flags only proceeding with unresolved blocking findings"
assert_not_contains "$SDD" "Proceed with unfixed issues" "SDD red flags avoid treating all unresolved issues as blocking"
assert_contains "$SDD" "Dispatch task fix subagent for blocking findings" "SDD graph uses a distinct per-task fix node"
assert_contains "$SDD" "Dispatch final-review fix subagent for the blocking findings" "SDD graph uses a distinct final-review fix node"
assert_not_contains "$SDD" "Dispatch fix subagent for blocking findings" "SDD graph avoids the ambiguous shared fix node label"
assert_not_contains "$SDD" "[Dispatch final code-reviewer]" "SDD example does not use stale final code-reviewer path"
assert_contains "$SDD" "Final code-review output: \`[]\`" "SDD example shows JSON-first empty findings output"
assert_not_contains "$SDD" "All requirements met, ready to merge" "SDD example does not use old prose final review output"
assert_contains "$README" "**code-review** - Recall-first max review for high-risk changes, bug hunts, and explicit deep reviews" "README lists code-review in skills library"

if [[ "$FAILURES" -gt 0 ]]; then
  echo "STATUS: FAILED ($FAILURES failure(s))"
  exit 1
fi

echo "STATUS: PASSED"
