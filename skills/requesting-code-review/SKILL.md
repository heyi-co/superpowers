---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After each task in subagent-driven development
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## Review Modes

Ordinary review is the default: small diffs, development checkpoints, routine feature reviews, and routine branch or PR merge gates. Ordinary review dispatches a `general-purpose` subagent with [code-reviewer.md](code-reviewer.md) and returns human-readable strengths, issues, recommendations, and a merge assessment.

Use `code-review` for max review when the user explicitly asks for a "max review", "deep review", "strong review", "comprehensive review", "bug hunt", "security review", "contract-break review", or "regression search"; when the change is high-risk (auth or permissions, migrations or data integrity, public API contracts, concurrency, payment paths); or when a merge gate covers a large branch that spans many subsystems. The `code-review` skill runs the JSON-first max-review protocol.

If max review applies, invoke `code-review` instead of filling [code-reviewer.md](code-reviewer.md).

When `code-review` returns JSON findings, triage them by priority before finishing work. P0 and P1 findings are blocking. P2 findings are non-blocking by default: present each one to your human partner to fix now or track as follow-up. P3 findings are non-blocking by default. Only your human partner can explicitly accept blocking findings and choose to proceed anyway.

After fixing max-review findings, re-verify with a review scoped to the fixed findings and the code the fixes touched; rerun the full `code-review` protocol only when the fix wave was broad. Do not assume a fix wave cleared the review gate until the re-verification confirms it.

## How to Request Ordinary Review

Use this path only when max review does not apply.

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch code reviewer subagent:**

Dispatch a `general-purpose` subagent, filling the template at [code-reviewer.md](code-reviewer.md)

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit

**3. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## Integration with Workflows

**Subagent-Driven Development:**
- Per-task review uses the task-scoped SDD reviewer.
- Final whole-branch review uses ordinary review by default; use `code-review` when the branch is high-risk, large, or your human partner asks for max review.
- Blocking findings (Critical/Important from ordinary review, P0/P1 from `code-review`) block finishing the branch unless the human explicitly accepts them.
- P2 findings from `code-review` go to your human partner to fix now or track as follow-up; P3 findings are non-blocking by default and should be tracked or fixed based on judgment.
- After any final-review fix wave, re-verify with a review scoped to the fixes; rerun the full protocol only when the fix wave was broad.

**Executing Plans:**
- Use ordinary review after each task or at natural checkpoints, including routine merges.
- Use `code-review` when the change is high-risk or the user asks for strong review.

**Ad-Hoc Development:**
- Use ordinary review for small local checkpoints and routine pre-merge reviews.
- Use `code-review` for high-risk changes, explicit deep-review requests, or when stuck on subtle bugs.

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback
- Use ordinary review when the user explicitly asked for max, deep, strong, comprehensive, or bug-finding review
- Escalate a routine low-risk review to max review when nothing triggered it: no explicit ask, no risk signals, no large merge gate

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: [code-reviewer.md](code-reviewer.md)
