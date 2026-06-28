---
name: decomposing-issues
description: Use when asked to split, decompose, break down, or draft child issues from a Triage Result with needs-decomposition or blocked-by-resolution-loop, a failed issue resolution loop, or an approved request to create coverage-preserving child issues
---

# Decomposing Issues

## Overview

Turn a triaged broad or blocked issue into coverage-preserving child issue
drafts. The output is an `Issue Decomposition`, not implementation, GitHub
mutation, or a replacement for triage.

**Core principle:** every child must trace back to the parent scope, and every
parent requirement must be covered, explicitly deferred, ruled out, or escalated.

## Required Input

Use this skill only after issue intake or reassessment has established one of:

- `Actionability: needs-decomposition`
- `Actionability: blocked-by-resolution-loop`
- an explicit human decision to split a parent issue
- a failed fix/review loop summary that needs decomposition

If the user gives a raw issue URL, issue number, pasted issue, bug report, or
feature request without a `Triage Result`, use `superpowers:triaging-issues`
first. Do not consume raw issues directly.

If the issue is not too broad and the real blocker is missing information,
ownership, security handling, or maintainer/product direction, return to
`superpowers:triaging-issues` instead of forcing a split.

## Read-Only Default

Decomposition is read-only unless the human approves a specific mutation.

- Do not write code.
- Do not post comments.
- Do not edit labels.
- Do not close, reopen, transfer, assign, or milestone issues.
- Do not create child issues.

Draft comments, parent updates, labels, and child issues in the response for
human approval.

## Decomposition Method

### Reframe the parent

State the parent issue as actor or owner, capability, outcome, and why
decomposition is needed. If the parent is solution-shaped, reframe it as the
observable user, maintainer, operator, or learning outcome it serves.

### Extract Scope Atoms

Create `Scope Atoms` from parent acceptance criteria, evidence, examples,
failure modes, user-visible outcomes, explicit maintainer decisions, and
remaining review findings. Each atom needs an id and source.

Atoms are the unit of coverage. Do not let an atom disappear because it is hard,
boring, or inconvenient.

### Choose the split strategy

Prefer vertical, end-to-end child issues over component or technical layer
splits. Useful dimensions:

- capability: narrower user or maintainer outcome
- path: happy path, alternate path, error path, or workflow branch
- interface: UI, CLI, API, integration, device, or channel
- data: subset, type, size, field set, or file format
- rules: business, validation, permission, or policy variation
- quality: smaller safe scale, lower fidelity, batch/manual mode, or release
  constraint
- SPIDR: spike, path, interface, data, rules

Use Hamburger slicing when the obvious split is frontend/backend/database:
choose the smallest acceptable bite across the necessary layers so at least one
child produces observable behavior or learning.

Spikes are valid only for a specific unknown with explicit questions,
time/effort bounds, and a follow-up decision.

### Build the coverage matrix

Every scope atom must map to one of:

- a child issue
- an explicit deferral with follow-up
- out-of-scope with policy or maintainer evidence
- needs maintainer decision
- needs reporter information

No child may be orphaned from the parent scope. If a child does not cover a
parent atom, move it to parking lot or drop it.

### Draft child issues

Each child issue draft must include:

- title
- problem
- value or learning outcome
- acceptance criteria
- verification
- dependencies
- out of scope
- parent coverage
- release constraint

Children should be independently understandable, reviewable, and verifiable. A
technical task can live inside a child issue, but should not masquerade as a
child issue unless it has an independently useful learning or operational
outcome.

### Recommend parent disposition

Recommend whether the parent should stay as an umbrella, close after children
are created, or remain blocked pending maintainer decision. Do not claim the
parent can close unless the coverage matrix is complete.

## Issue Decomposition

Output this structure:

```markdown
## Issue Decomposition

Parent:
- Issue:
- Actor / owner:
- Capability:
- Outcome:
- Why decomposition is needed:

Scope Atoms:
| ID | Source | Atom | Type |
| --- | --- | --- | --- |

Split Strategy:
- Primary dimension:
- Alternatives considered:
- Why this preserves scope:

Coverage Matrix:
| Atom | Covered by | Status | Notes |
| --- | --- | --- | --- |

Child Issue Drafts:
1. Title:
   Problem:
   Value / learning outcome:
   Acceptance criteria:
   Verification:
   Dependencies:
   Out of scope:
   Parent coverage:
   Release constraint:

Dependency Order:
- ...

Parent Disposition:
- ...

Gaps / Decisions Needed:
- ...

Mutation Preview:
- ...
```

Write `None` for sections that do not apply. Keep the decomposition grounded in
the parent issue and evidence.

## GitHub Mutation Gate

Use two-step approval for every GitHub issue mutation:

1. Draft the exact parent comment or update, exact labels or state changes, and
   exact child issue title/body you would apply.
2. Ask the human to confirm that exact draft.

Blanket approval in the original task, such as "go ahead and create the child
issues", is not enough. Mutate GitHub only after the human has seen the exact
draft and confirmed that version. If the draft changes, ask for approval again.

When the prompt requests mutation, the `Mutation Preview` section must state
that no GitHub mutation was performed, blanket approval is insufficient, and the
human must confirm the exact draft before any child issues, comments, labels, or
parent updates are created.

## Red Flags

Stop and correct course if you are:

- Splitting by component layer instead of observable capability
- Dropping parent acceptance criteria into out of scope without evidence
- Creating children that must all finish before any one can be verified
- Adding child issues not traceable to parent scope
- Treating a vague product decision as decomposition
- Treating a spike as unbounded research
- Creating GitHub child issues from blanket approval
- Claiming the parent can close without a complete coverage matrix

## Behavior Testing

Use [pressure-scenarios.md](pressure-scenarios.md) before changing this skill.
Record baseline behavior without the skill, then verify the changed skill emits
`## Issue Decomposition`, preserves parent scope through `Scope Atoms` and
`Coverage Matrix`, avoids implementation, and performs no GitHub mutation
without exact-draft approval.
