# Code Review Skill Integration Design

## Status

Ready for user review.

## Goal

Add a strong, JSON-first `code-review` skill to this fork and connect it to the existing Superpowers review workflow without making every review heavy.

The new skill should preserve the shape of the authorized source skill as closely as practical: max-grade review, phased candidate generation, verification, final gap sweep, and JSON findings as the primary output.

## Background

The current repository already has review capabilities:

- `requesting-code-review` dispatches a general-purpose reviewer for broad human-readable code review.
- `subagent-driven-development` uses task-scoped review after each task and a whole-branch review at the end.
- spec and plan reviewer prompt templates exist for document quality gates.

These are useful but general. The fork needs a stronger review mode for PRs, merge gates, high-risk diffs, and explicit "find bugs" requests. That mode should be recall-oriented and structured enough to support future automation.

## Scope

In scope:

- Add `skills/code-review/SKILL.md`.
- Keep the new skill close to the authorized source protocol.
- Use JSON-first findings with `P0` / `P1` / `P2` / `P3` priorities.
- Support subagent-driven finder passes when subagents are available.
- Add fallback instructions for sequential execution when subagents are unavailable.
- Update `skills/requesting-code-review/SKILL.md` so strong review requests route to `code-review`.
- Update `skills/subagent-driven-development/SKILL.md` so final whole-branch review uses `code-review`.
- Keep per-task SDD review lightweight and task-scoped.

Out of scope:

- Do not create a generic `requesting-review` router yet.
- Do not replace every existing review with max review.
- Do not change Codex or Claude Code session-start hooks.
- Do not add GitHub PR comment automation.
- Do not automatically fix findings unless the user explicitly asks for fix mode.
- Do not add a full Drill/evals scenario in this first slice.

## File Structure

First slice:

```text
skills/
  code-review/
    SKILL.md

  requesting-code-review/
    SKILL.md
    code-reviewer.md

  subagent-driven-development/
    SKILL.md
    task-reviewer-prompt.md
```

Future review types should become sibling skills, not sections inside `code-review`:

```text
skills/security-review/
skills/architecture-review/
skills/api-contract-review/
```

Only after a second review type exists should the fork consider adding a generic `requesting-review` router.

## Review Mode Routing

`requesting-code-review` remains the compatibility entry point for existing Superpowers workflows.

Use the existing human-readable reviewer when:

- The user asks for a normal review without emphasizing strength or breadth.
- The diff is small and part of an active development checkpoint.
- SDD is reviewing an individual task.

Use the new `code-review` skill when:

- The user asks for a "max review", "deep review", "strong review", "comprehensive review", or similar.
- The user asks to review a PR, branch diff, commit range, or working tree diff with high confidence.
- The user asks to find bugs, regressions, security issues, contract breaks, or subtle correctness problems.
- SDD reaches final whole-branch review after all tasks are complete.

## Code Review Skill Protocol

`skills/code-review/SKILL.md` should retain the authorized source skill's protocol shape.

### Phase 0: Gather Context

Determine the review scope:

- working tree diff
- commit range
- branch diff
- PR diff

Collect the diff, stat summary, and relevant requirements or PR context. If the scope is ambiguous, ask before reviewing.

### Phase 1: Candidate Generation

Run multiple finder angles. If subagents are available, dispatch finder passes in parallel. If subagents are unavailable, execute the same finder angles sequentially in the current session.

Finder passes produce candidate findings only. They do not make final reporting decisions.

### Phase 2: Dedupe and Verify

Merge duplicate candidates and verify each one as:

- `confirmed`
- `plausible`
- `refuted`

Only `confirmed` and `plausible` findings are eligible for final output.

### Phase 3: Final Gap Sweep

Run a final sweep for commonly missed classes:

- contract drift
- authorization and access control
- data loss
- async and concurrency issues
- cache invalidation
- rollback and migration behavior
- API or schema changes
- test blind spots

### Reporting Gate

Return a JSON array as the primary output:

```json
[
  {
    "priority": "P1",
    "file": "path/to/file.ts",
    "line": 123,
    "category": "contract",
    "summary": "Changed return shape breaks existing callers",
    "failure_scenario": "Existing caller reads field x, but new code returns y, causing the caller to fail."
  }
]
```

Rules:

- Return at most 15 findings.
- Sort by `P0`, then `P1`, then `P2`, then `P3`.
- Return `[]` when no findings are found.
- Do not invent findings to appear useful.
- Do not emit refuted candidates.
- Human-readable notes may follow the JSON only when useful; the JSON array is the review result.

## SDD Integration

Per-task SDD review remains unchanged:

- Use `task-reviewer-prompt.md`.
- Keep the review task-scoped.
- Do not run max review after every task.

Final SDD whole-branch review changes:

- Use the new `code-review` skill.
- Review the final branch diff as a max-grade review.
- If `P0`, `P1`, or `P2` findings are returned, run a fix and re-review loop.
- Treat `P3` as non-blocking by default unless the user asks otherwise.

## Verification

First-slice verification is lightweight and structural.

Check structure:

- `skills/code-review/SKILL.md` exists.
- Frontmatter has `name: code-review`.
- The description includes triggers for max review, PR review, bug finding, and diff review.

Check routing:

- `requesting-code-review/SKILL.md` explains when to use the existing reviewer and when to route to `code-review`.
- `subagent-driven-development/SKILL.md` keeps per-task review lightweight and points final whole-branch review at `code-review`.

Check protocol:

- `code-review/SKILL.md` includes Phase 0, Phase 1, Phase 2, Phase 3, and Reporting Gate.
- It mentions subagent finder fallback.
- It includes `confirmed`, `plausible`, and `refuted`.
- It includes `P0`, `P1`, `P2`, and `P3`.
- It requires JSON array output, a 15-finding maximum, and `[]` for no findings.

Manual smoke test:

- Run the skill on a small real or synthetic diff.
- Confirm the output is JSON-first.
- Confirm it looks for concrete failure scenarios rather than producing a broad summary.

## Open Decisions

None for the first slice. A generic review router is intentionally deferred until a second review type exists.
