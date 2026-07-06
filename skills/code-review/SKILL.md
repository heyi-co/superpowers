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
