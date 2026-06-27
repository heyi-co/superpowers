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

Use ordinary review for small diffs, development checkpoints, and routine feature reviews. Ordinary review dispatches a `general-purpose` subagent with [code-reviewer.md](code-reviewer.md) and returns human-readable strengths, issues, recommendations, and a merge assessment.

Use `code-review` for max review when the user asks for a "max review", "deep review", "strong review", "comprehensive review", PR review, branch review, bug hunt, security review, contract-break review, regression search, or merge-gate review. The `code-review` skill runs the JSON-first max-review protocol and is the preferred final review for high-risk or pre-merge changes.

If max review applies, invoke `code-review` instead of filling [code-reviewer.md](code-reviewer.md).

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
- Final whole-branch review should use `code-review` for max review.
- Fix blocking findings before finishing the branch.

**Executing Plans:**
- Use ordinary review after each task or at natural checkpoints.
- Use `code-review` before merge or when the user asks for strong review.

**Ad-Hoc Development:**
- Use ordinary review for small local checkpoints.
- Use `code-review` before merge, for PR review, or when stuck on subtle bugs.

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback
- Use ordinary review when the user explicitly asked for max, deep, strong, comprehensive, PR, or bug-finding review

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: [code-reviewer.md](code-reviewer.md)
