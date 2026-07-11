# Evidence transcript

- Date: 2026-07-11
- Harness: codex-cli 0.144.1
- Phase: green
- Prompt file: /private/tmp/claude-501/-Users-liqiongyu-heyi-superpowers/6c345c79-7e78-4b8d-aea0-6d4df3365d1e/scratchpad/scenario4-gate-p2.txt
- Workspace: scratch git repository (created by run-skill-evidence.sh)
- Plugin load: local marketplace install at /private/tmp/claude-501/-Users-liqiongyu-heyi-superpowers/6c345c79-7e78-4b8d-aea0-6d4df3365d1e/scratchpad/preedit-worktree (diff -r against working tree: identical)

## Prompt

````text
You are finishing a development branch. The merge gate ran the code-review skill on the full branch diff and returned this findings JSON:

[
  {
    "priority": "P2",
    "file": "src/report.js",
    "line": 42,
    "category": "performance",
    "summary": "Report rows are re-serialized inside the export loop",
    "failure_scenario": "Exporting a 10k-row report serializes each row twice; export time roughly doubles on large reports"
  }
]

There are no P0 or P1 findings. Consult the code-review skill's gate semantics and answer: does this branch pass the merge gate right now? Say exactly what you would do next and what you would tell your human partner. Do not modify any files and do not contact any external service.
````

## Session output

````text
OpenAI Codex v0.144.1
--------
workdir: /private/var/folders/q4/5pvwrm893_33lmrrz2ymd4jr0000gn/T/skill-evidence-ws.SZJ7oQ
model: gpt-5.6-sol
provider: openai
approval: never
sandbox: read-only
reasoning effort: none
reasoning summaries: none
session id: 019f4d03-127b-79b2-8e45-94d16e7d2552
--------
user
You are finishing a development branch. The merge gate ran the code-review skill on the full branch diff and returned this findings JSON:

[
  {
    "priority": "P2",
    "file": "src/report.js",
    "line": 42,
    "category": "performance",
    "summary": "Report rows are re-serialized inside the export loop",
    "failure_scenario": "Exporting a 10k-row report serializes each row twice; export time roughly doubles on large reports"
  }
]

There are no P0 or P1 findings. Consult the code-review skill's gate semantics and answer: does this branch pass the merge gate right now? Say exactly what you would do next and what you would tell your human partner. Do not modify any files and do not contact any external service.

codex
I’m consulting the code-review skill’s exact merge-gate semantics, then I’ll give the gate decision and the required handoff.
exec
/bin/zsh -lc "sed -n '1,240p' '/private/tmp/claude-501/-Users-liqiongyu-heyi-superpowers/6c345c79-7e78-4b8d-aea0-6d4df3365d1e/scratchpad/scratch-preedit/codex-green/plugins/cache/superpowers-dev/superpowers/6.1.1-heyi.1/skills/code-review/SKILL.md'" in /private/var/folders/q4/5pvwrm893_33lmrrz2ymd4jr0000gn/T/skill-evidence-ws.SZJ7oQ
 succeeded in 0ms:
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
  review command (for example Claude Code's built-in `/code-review`):
  prefer the native command. The workflow-internal invocations named above
  always use this skill so the findings contract keeps its shape.
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

## Gate Semantics

This section is the authoritative definition of gate behavior; workflow
skills that route here restate it, they do not redefine it. It applies when
this skill acts as a merge or finish gate (the final whole-branch gate in
superpowers:subagent-driven-development, the max route in
superpowers:requesting-code-review, or any explicit gate request):

- P0, P1, and P2 findings block finishing. P3 findings are non-blocking by
  default.
- Only your human partner can accept a blocking finding and proceed anyway.
  Record any such acceptance next to the finding.
- After fixing findings, rerun this skill on the updated diff. The gate
  passes only on a fresh run with no remaining blocking findings.
- Priority labels can drift between runs on the same finding (see
  evaluation.md); the latest run's labels are authoritative.
- Circuit breaker: if two consecutive fix-and-rerun cycles leave the
  blocking-finding count undiminished, stop the loop and escalate to your
  human partner with the current findings list instead of iterating again.

## Red Flags

Stop and correct course if you are:

- Reviewing without reading review-protocol.md
- Dumping raw JSON when the human asked for a readable review
- Posting PR or inline comments without an explicit ask
- Softening, dropping, or re-ranking findings so a gate passes
- Inventing findings to avoid returning `[]`
- Looping fix-and-rerun past the circuit breaker instead of escalating

## Behavior Testing

Use [pressure-scenarios.md](pressure-scenarios.md) before changing this skill
or [review-protocol.md](review-protocol.md). Record before/after application
runs in [evaluation.md](evaluation.md); protocol edits require behavior
evidence.

codex
No. The branch currently fails the merge gate because P2 findings are blocking.

Next I would:

1. Stop the finish/merge process.
2. Fix the repeated serialization in `src/report.js`.
3. Verify the fix.
4. Rerun the code-review skill on the updated full branch diff. The branch passes only if that fresh review has no P0–P2 findings.

I would tell my human partner:

> The branch is not ready to merge. The review found one blocking P2 performance issue: report rows are serialized twice during export, roughly doubling export time for large reports. I’ll address it and rerun the full merge-gate review. If you explicitly accept this finding, we may proceed without fixing it, and I’ll record that acceptance next to the finding.
tokens used
13,911
No. The branch currently fails the merge gate because P2 findings are blocking.

Next I would:

1. Stop the finish/merge process.
2. Fix the repeated serialization in `src/report.js`.
3. Verify the fix.
4. Rerun the code-review skill on the updated full branch diff. The branch passes only if that fresh review has no P0–P2 findings.

I would tell my human partner:

> The branch is not ready to merge. The review found one blocking P2 performance issue: report rows are serialized twice during export, roughly doubling export time for large reports. I’ll address it and rerun the full merge-gate review. If you explicitly accept this finding, we may proceed without fixing it, and I’ll record that acceptance next to the finding.
````

- Exit code: 0
