#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILL="$REPO_ROOT/skills/code-review/SKILL.md"
REQUESTING="$REPO_ROOT/skills/requesting-code-review/SKILL.md"
SDD="$REPO_ROOT/skills/subagent-driven-development/SKILL.md"
EXPECTED_SKILL_SHA256="a71428ab647d57015da21a373be371f65fc5a17ded76fd7a2397f5652869b5ae"

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
assert_sha256 "$SKILL" "$EXPECTED_SKILL_SHA256" "code-review skill matches pinned source digest"
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
assert_contains "$REQUESTING" "Use \`code-review\` for max review" "requesting-code-review routes max review to code-review"
assert_contains "$REQUESTING" "ordinary review" "requesting-code-review keeps ordinary review path"
assert_contains "$REQUESTING" "strong review" "requesting-code-review documents strong review trigger"
assert_contains "$SDD" "Final whole-branch review: use \`code-review\`" "SDD final review uses code-review"
assert_contains "$SDD" "Per-task reviews remain task-scoped" "SDD preserves lightweight per-task review"
assert_not_contains "$SDD" "[Dispatch final code-reviewer]" "SDD example does not use stale final code-reviewer path"

if [[ "$FAILURES" -gt 0 ]]; then
  echo "STATUS: FAILED ($FAILURES failure(s))"
  exit 1
fi

echo "STATUS: PASSED"
