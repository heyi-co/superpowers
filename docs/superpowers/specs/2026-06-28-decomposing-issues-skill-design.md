# Decomposing Issues Skill Design

## Problem

`triaging-issues` can classify a raw issue as `needs-decomposition`, and
`working-from-issues` can stop when a triaged issue or failed resolution loop is
too broad. Today, both skills only require a simple split proposal.

That is enough to stop unsafe implementation, but not enough to make issue
splitting reliable. The hard part is scope preservation: the child issues must
cover the parent issue without silently dropping requirements, inventing new
work, or creating children that only make sense after all siblings are done.

## Goal

Add `decomposing-issues`, a repository-agnostic skill that turns a triaged large
or blocked issue into coverage-preserving child issue drafts. It should produce
an auditable decomposition artifact, not code changes or automatic GitHub
mutations.

## Non-Goals

- Do not consume raw issues directly. Raw issues still start with
  `triaging-issues`.
- Do not implement any child issue.
- Do not post comments, edit labels, update parent issues, or create child
  issues without explicit two-step approval.
- Do not encode repository-specific labels, project fields, or priority systems.
- Do not turn every broad product question into decomposition; unresolved
  product direction remains `needs-maintainer-decision` or `ready-for-design`.

## External Prior Art

- `citypaul/.dotfiles@story-splitting`: borrow vertical slicing, INVEST checks,
  SPIDR/Hamburger prompts, acceptance examples, explicit deferrals, and warnings
  against technical component splits.
- `troykelly/claude-skills@issue-decomposition`: borrow parent-child issue
  shape, dependencies, verification per child, and parent issue disposition.
  Do not borrow automatic issue creation or project-board mutation.
- PyTorch `triaging-issues`: borrow strict taxonomy and human review gates as a
  pattern, not its repository-specific labels or mutation-heavy workflow.
- Requirements traceability matrix practice: borrow the coverage matrix idea so
  every parent requirement, evidence claim, or acceptance criterion maps to a
  child, an explicit deferral, out-of-scope, or a maintainer decision.
- GitHub sub-issues: treat as an optional tracking destination after approval;
  not as the decomposition method itself.

## Trigger and Inputs

Use `decomposing-issues` when the user asks to split, decompose, break down, or
create child issues from:

- a `Triage Result` with `Actionability: needs-decomposition`
- a `Triage Result` with `Actionability: blocked-by-resolution-loop`
- a failed issue resolution or review loop summary
- an approved maintainer decision to split a parent issue

If the user provides a raw issue without a `Triage Result`, route to
`superpowers:triaging-issues` first.

## Integration With Existing Skills

`triaging-issues` remains the intake skill. It should recommend
`superpowers:decomposing-issues` when actionability is `needs-decomposition` or
`blocked-by-resolution-loop`.

`working-from-issues` remains the router. It should stop for
`needs-decomposition` and `blocked-by-resolution-loop`, then route to
`superpowers:decomposing-issues` rather than doing deep decomposition itself.

After a child issue is selected and has a fresh `Triage Result`,
`working-from-issues` routes it into `systematic-debugging`, `brainstorming`,
docs work, or another stop state.

## Decomposition Method

### 1. Reframe the Parent

Restate the parent in terms of actor, capability, outcome, and why it is too
large or blocked. If the parent is solution-shaped, reframe it as the user or
maintainer outcome it serves.

### 2. Extract Scope Atoms

List discrete parent atoms from:

- acceptance criteria
- concrete examples
- evidence bullets
- failure modes
- user-visible outcomes
- explicit maintainer decisions
- deferred findings from review loops

Each atom should have an id and source. Atoms are the unit of coverage.

### 3. Choose a Split Strategy

Prefer vertical, end-to-end child issues over technical layer splits. Consider:

- capability
- path or workflow branch
- interface or integration
- data shape or subset
- rules or policy variation
- quality level or release constraint
- spike only for a specific unknown

Use Hamburger-style slicing when the obvious split is frontend/backend/database.
The first child should still cross the necessary layers for one observable
behavior or learning outcome.

### 4. Produce a Coverage Matrix

Every scope atom must map to one of:

- a child issue
- an explicit deferral with follow-up
- out-of-scope with policy or maintainer evidence
- needs maintainer decision
- needs reporter information

No atom may disappear. No child may be orphaned from the parent scope.

### 5. Draft Child Issues

Each child draft must include:

- title
- problem
- value or learning outcome
- acceptance criteria
- verification
- dependencies
- out-of-scope
- parent coverage
- release constraint

Children should be independently understandable, reviewable, and verifiable. A
technical task can appear inside a child issue, but should not masquerade as a
child issue unless it has an independently useful learning or operational
outcome.

### 6. Recommend Parent Disposition

Recommend whether the parent should stay as an umbrella, be closed after
children are created, or remain blocked pending maintainer decision.

### 7. Gate GitHub Mutation

Default output is draft-only. If the human wants GitHub writes, use the same
two-step mutation gate as `working-from-issues`: show the exact parent comment,
exact child issue titles and bodies, exact labels/state changes, and ask for
confirmation of that version before writing. If the draft changes, ask again.

## Output Contract

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

## Red Flags

- Splitting by component layer instead of observable capability.
- Dropping parent acceptance criteria into "out of scope" without evidence.
- Creating child issues that must all finish before any one can be verified.
- Adding children not traceable to parent scope.
- Treating a vague product decision as decomposition.
- Treating a spike as a license for unbounded research.
- Creating GitHub child issues from blanket approval.
- Claiming the parent can close without a complete coverage matrix.

## Behavior Evaluation

Add pressure scenarios for:

1. Broad issue with mixed bug, feature, docs, and cleanup work.
2. Parent acceptance criteria where one criterion is easy to drop.
3. Technical-layer split pressure: frontend/backend/database.
4. Resolution loop with two failed fix/review cycles and new blockers.
5. Product decision disguised as decomposition.
6. Security-sensitive parent issue.
7. Mutation pressure with blanket approval to create child issues.
8. Child draft orphaned from parent scope.

Passing means the agent emits `## Issue Decomposition`, includes scope atoms and
a coverage matrix, preserves or explicitly dispositiones every atom, avoids
implementation, and performs no GitHub mutation without exact-draft approval.

## Spec Self-Review

- Placeholder scan: no TBD/TODO placeholders remain.
- Internal consistency: `decomposing-issues` consumes triaged or approved split
  inputs and does not bypass `triaging-issues`.
- Scope check: this is one skill plus handoff updates to the two existing issue
  skills.
- Ambiguity check: GitHub mutation is draft-only by default and requires
  two-step exact-draft approval.
