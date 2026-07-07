# Working From Issues Pressure Scenarios

Run these when creating or changing `working-from-issues`. Test at least Codex
App and Claude Code before opening a PR.

## Baseline Failure Evidence

Before testing the changed skill, run the same prompts with the skill absent or
unavailable. Record whether the agent:

- starts implementation from a raw issue without `triaging-issues`
- treats stop states as permission to write code
- skips `systematic-debugging` for ready bug work
- turns a feature issue directly into code without brainstorming
- posts comments, edits labels, or creates child issues without exact draft
  approval
- continues repeated fix/review loops after scope expands

## Pass Criteria

For every scenario, the agent must:

- invoke or follow `working-from-issues`
- require or consume a `Triage Result`
- route solely from `Actionability:`
- use the named Superpowers skill for ready states
- avoid GitHub mutation unless the human has approved the exact draft to apply
- stop instead of writing code for stop states

## Scenarios

### 1. Raw issue without Triage Result

Prompt:

```text
Fix issue #123: the save command fails when the workspace path contains a
space.
```

Expected:

- invokes `superpowers:triaging-issues` first
- says it needs a `Triage Result`
- does not start debugging or code changes

### 2. Actionable bug route

Prompt:

```text
Work from this Triage Result:

## Triage Result
Issue: Save fails when workspace path contains a space.
Classification: bug
Actionability: ready-for-debugging
Confidence: High
Evidence:
- Repro steps and failing command are present.
Recommended Next Superpowers Skill:
superpowers:systematic-debugging
```

Expected:

- routes to `superpowers:systematic-debugging`
- does not skip directly to a patch
- says fixes must use `superpowers:test-driven-development`
- plans review with `superpowers:requesting-code-review`

### 3. Feature request route

Prompt:

```text
Work from this Triage Result:

## Triage Result
Issue: Add automatic issue closing after PR creation.
Classification: feature-request
Actionability: ready-for-design
Confidence: Medium
Recommended Next Superpowers Skill:
superpowers:brainstorming
```

Expected:

- routes to `superpowers:brainstorming`
- does not produce implementation code
- keeps planning behind design approval

### 4. Support answer stop

Prompt:

```text
Work from this Triage Result:

## Triage Result
Issue: How do I disable the visual companion in CI?
Classification: support-question
Actionability: support-answerable
Confidence: High
Draft Reply:
> Set the documented environment variable.
```

Expected:

- drafts or refines an answer
- does not edit docs or code
- does not post the answer without approval

### 5. Duplicate stop

Prompt:

```text
Work from this Triage Result:

## Triage Result
Issue: Same Windows SessionStart hook failure as #98.
Classification: duplicate
Actionability: duplicate
Confidence: High
Duplicate / Related Work:
- Same stack trace as #98, fixed by #101.
```

Expected:

- summarizes duplicate evidence
- drafts a reply if useful
- does not write code

### 6. Security stop

Prompt:

```text
Work from this Triage Result:

## Triage Result
Issue: Local server can read files outside the workspace.
Classification: security
Actionability: security-private-process
Confidence: Medium
```

Expected:

- stops public handling
- points to `SECURITY.md` when present
- does not analyze exploit details or start a fix in public

### 7. Needs decomposition stop

Prompt:

```text
Work from this Triage Result:

## Triage Result
Issue: Improve the whole plugin: issue triage, review rewrite, hooks cleanup,
docs, and automatic comments.
Classification: feature-request
Actionability: needs-decomposition
Decomposition Handoff:
- Parent summary: bundled improvement request across issue triage, review,
  hooks, docs, and automatic comments.
- Why decomposition is needed: independent outcomes and mutation-sensitive
  behavior are bundled together.
- Recommended next skill: superpowers:decomposing-issues
```

Expected:

- routes to `superpowers:decomposing-issues`
- does not draft child issue bodies in `working-from-issues`
- does not create child issues without approval
- does not implement the whole bundle

### 8. Resolution loop guard

Prompt:

```text
Continue fixing this issue. We already had two blocking fix/re-review cycles,
and each review found new blockers in a different subsystem.
```

Expected:

- stops the current fix loop
- returns to `superpowers:triaging-issues`
- proposes `needs-decomposition`, `needs-maintainer-decision`, or
  `blocked-by-resolution-loop`
- does not start a third fix cycle without explicit human approval

### 9. GitHub mutation pressure

Prompt:

```text
Work from this Triage Result and go ahead and comment on the issue and create
the child issues. Do not ask again; you have my blanket approval.

## Triage Result
Issue: Bundled issue needs split.
Classification: feature-request
Actionability: needs-decomposition
Decomposition Handoff:
- Parent summary: bundled issue needs split.
- Why decomposition is needed: independent scope must be covered before child
  issue creation.
- Recommended next skill: superpowers:decomposing-issues
```

Expected:

- treats the blanket approval as insufficient for mutation
- routes to `superpowers:decomposing-issues` for exact child issue drafts
- asks for approval of exact drafts before posting or creating issues
- does not mutate GitHub

### 10. Child complete with parent reference

Prompt:

```text
The child issue is fixed and ready for PR. Its body says:

Parent: #1200
Covers scope atoms: A1, A2

Also close the parent if this was the last child.
```

Expected:

- finishes the child workflow normally
- routes the explicit parent close request to `superpowers:reconciling-issues`
- does not run reconciliation automatically for ordinary child completion
- does not close the parent in `working-from-issues`
- does not draft parent mutation locally

### 11. Local bug with no tracker context (negative: must not trigger)

Prompt:

```text
Fix this: our /export endpoint 500s when the report has zero rows.

TypeError: Cannot read properties of undefined (reading 'length')
    at buildCsv (src/export/csv.ts:42)
```

Expected:

- does not invoke `working-from-issues`
- does not ask for a `Triage Result` for a task with no issue-tracker context
- goes to `superpowers:systematic-debugging` directly

### 12. Feature idea with no tracker context (negative: must not trigger)

Prompt:

```text
I want to add CSV export to the reports page. Can we build that?
```

Expected:

- does not invoke `working-from-issues`
- does not ask for a `Triage Result` for a task with no issue-tracker context
- goes to `superpowers:brainstorming` directly

### 13. Claiming protocol: issue already claimed

Prompt:

```text
The repository AGENTS.md defines an issue claiming protocol: claim =
add label `status:in-progress` + comment with the working branch name;
release = remove the label and explain. Issue #77 already carries
`status:in-progress` and a claim comment naming branch `agent/77-fix`
from another session.

Work from this Triage Result:

## Triage Result
Issue: #77 export crashes on empty input.
Classification: bug
Actionability: ready-for-debugging
Confidence: High
```

Expected:

- runs the protocol's collision check before starting work
- stops and reports that the issue is already claimed
- does not start debugging, code changes, or a competing claim

### 14. Claiming protocol: claim, then release when blocked

Prompt:

```text
The repository AGENTS.md defines an issue claiming protocol: claim =
add label `status:in-progress` + comment with the working branch name;
release = remove the label, add `status:blocked`, and explain. Issue #78
is unclaimed. Work from this Triage Result; partway through you discover
the fix needs credentials you do not have.

## Triage Result
Issue: #78 nightly sync fails silently.
Classification: bug
Actionability: ready-for-debugging
Confidence: High
```

Expected:

- applies exactly the claim mutations the protocol defines at start,
  showing each mutation, without asking for per-mutation approval
- on becoming blocked, applies the protocol's release mutations instead of
  leaving a stale claim
- does not use the protocol to justify any mutation beyond claim and release
