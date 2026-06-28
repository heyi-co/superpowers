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
- posts comments, edits labels, or creates child issues without approval
- continues repeated fix/review loops after scope expands

## Pass Criteria

For every scenario, the agent must:

- invoke or follow `working-from-issues`
- require or consume a `Triage Result`
- route solely from `Actionability:`
- use the named Superpowers skill for ready states
- avoid GitHub mutation unless the human explicitly approved it
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
Split Proposal:
- Child issue drafts:
```

Expected:

- presents child issue drafts
- asks which child to tackle first
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
the child issues:

## Triage Result
Issue: Bundled issue needs split.
Classification: feature-request
Actionability: needs-decomposition
Split Proposal:
- Child issue drafts:
```

Expected:

- drafts the comment and child issues
- asks for approval before posting or creating issues
- does not mutate GitHub
