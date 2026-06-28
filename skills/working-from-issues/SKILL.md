---
name: working-from-issues
description: Use when asked to work on, fix, implement, resolve, make a PR for, or continue from a GitHub issue, issue number, bug report, feature request, support request, pasted issue report, or Triage Result
---

# Working From Issues

## Overview

Move from a `Triage Result` into the correct Superpowers workflow. This skill
does not replace triage, debugging, design, planning, TDD, or review.

**Core principle:** only ready issue states become implementation work; every
other state stops or asks for a human decision.

## Required Input

You need a current `Triage Result` before working from an issue.

If the user gives a raw issue URL, issue number, pasted issue, bug report,
feature request, support request, or follow-up comment without a `Triage
Result`, use `superpowers:triaging-issues` first. Do not start from a raw issue.

Read the `Actionability:` field from the `Triage Result`. If the actionability
state is missing, ambiguous, or conflicts with the evidence, return to
`superpowers:triaging-issues` instead of guessing.

If a valid `Triage Result` is present, do not re-run triage just because the
issue text mentions labels, feature requests, decomposition, triage, or other
issue-work words. Consume the existing `Actionability:` field and route from it.
The only exceptions are raw issue input with no `Triage Result`, missing or
conflicting actionability, an explicit human decision that changes a stop state
into a ready state, or the resolution loop guard.

## GitHub Mutation Gate

Working from an issue may lead to code or docs changes for ready states, but
GitHub issue mutation is still approval-gated.

- Do not post comments without explicit approval.
- Do not edit labels without explicit approval.
- Do not close, reopen, transfer, assign, or milestone issues without explicit
  approval.
- Do not create child issues without explicit approval.

Use two-step approval for every GitHub issue mutation:

1. Draft the exact comment text, exact labels, exact issue state change, and
   exact child issue title/body you would apply.
2. Ask the human to confirm that exact draft.

Blanket approval in the original task, such as "go ahead and comment" or
"create the child issues", is not enough. Mutate GitHub only after the human has
seen the exact draft and confirmed that version. If the draft changes, ask for
approval again.

## Route by Actionability

Use exactly one route from the `Actionability:` field.

### `ready-for-debugging`

Use `superpowers:systematic-debugging` before code changes. Establish
reproduction or root cause, then use `superpowers:test-driven-development` for
the fix. Use `superpowers:requesting-code-review` before finishing.

If reproduction cannot be established from available evidence, return to
`superpowers:triaging-issues` with the new missing-information evidence.

### `ready-for-design`

Use `superpowers:brainstorming` to turn the issue context into a design
conversation. After design approval, use `superpowers:writing-plans`, then
`superpowers:subagent-driven-development` or `superpowers:executing-plans` for
implementation.

Do not turn a feature issue directly into code.

### `ready-for-docs-fix`

Make only the narrow documentation change described by the `Triage Result`.

If the repository has doc tests, link checks, examples tests, or generated docs,
use `superpowers:test-driven-development` where a failing doc test can be
written. Otherwise verify with the relevant docs command or a focused manual
read-through, then use `superpowers:requesting-code-review` before finishing.

Do not expand a docs fix into product or code behavior changes.

## Stop States

Do not write code for these actionability states:

- `support-answerable` - draft an answer grounded in docs/code.
- `needs-reporter-info` - ask the specific questions from the `Triage Result`
  and explain why each is needed.
- `duplicate` - provide duplicate evidence and a reply draft.
- `not-repo-owned` - explain the ownership boundary and suggest where to file
  or continue.
- `out-of-scope` - explain the repository policy or maintainer decision that
  declines the request.
- `security-private-process` - stop public handling and point to `SECURITY.md`
  when present.
- `needs-maintainer-decision` - present the exact decision needed and the
  tradeoff; do not implement.
- `needs-decomposition` - present child issue drafts and ask which child to
  tackle first; do not create child issues.
- `blocked-by-resolution-loop` - stop the current fix loop, summarize attempts
  and remaining findings, then propose split or escalation.

If the human explicitly changes a stop state into a ready state, run
`superpowers:triaging-issues` again with that new decision recorded as evidence.

## Resolution Loop Guard

Do not let issue resolution become an infinite fix/review loop.

After a review finds blocking issues, fix and re-review as normal. Stop and
return to superpowers:triaging-issues if any of these happen:

- the implementer reports `BLOCKED` because scope is too large
- two full blocking fix/re-review cycles produce new blocking findings from
  different areas of the issue
- fixes repeatedly reveal independent problems bundled into one issue
- the plan or acceptance criteria must change to continue
- the root cause belongs to another subsystem or repository
- final review finds that the implementation solved only part of the issue

Default action: return to or invoke `superpowers:triaging-issues`. The resulting triage should produce a fresh `Triage Result` with `needs-decomposition`, `needs-maintainer-decision`, or `blocked-by-resolution-loop`. Continue into another fix/re-review cycle only if the human explicitly chooses that path after seeing the reassessment.

## Proposed Split

When scope needs to split, draft child issues:

```markdown
## Proposed Split

Parent Issue:
- Keep as umbrella / close after children / replace with child issues:

Child 1:
- Title:
- Problem:
- Acceptance criteria:
- Verification:
- Dependencies:
- Out of scope:

Child 2:
- Title:
- Problem:
- Acceptance criteria:
- Verification:
- Dependencies:
- Out of scope:

Suggested first child:

Why this split:
```

Do not create the child issues until the human has seen the exact child issue
drafts and confirmed that version.

## Red Flags

Stop and correct course if you are:

- Starting code from a raw issue without `Triage Result`
- Treating `needs-reporter-info` as permission to guess
- Turning a support answer into a code change
- Turning a vague feature request into implementation without brainstorming
- Publicly handling a security-sensitive report
- Creating labels, comments, or child issues without approval
- Treating blanket "go ahead" approval as permission to mutate GitHub before
  showing exact drafts
- Continuing review loops after scope is expanding
- Claiming an issue is fixed when only one child concern was fixed

## Behavior Testing

Use [pressure-scenarios.md](pressure-scenarios.md) before changing this skill.
Record baseline behavior without the changed skill, then verify the changed
skill routes `Triage Result` input through actionability instead of falling
back to raw triage or implementation.
