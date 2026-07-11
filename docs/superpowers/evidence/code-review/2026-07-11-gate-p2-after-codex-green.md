# Evidence transcript

- Date: 2026-07-11
- Harness: codex-cli 0.144.1
- Phase: green
- Prompt file: /private/tmp/claude-501/-Users-liqiongyu-heyi-superpowers/6c345c79-7e78-4b8d-aea0-6d4df3365d1e/scratchpad/scenario4-gate-p2.txt
- Workspace: scratch git repository (created by run-skill-evidence.sh)
- Plugin load: local marketplace install at /Users/liqiongyu/heyi/superpowers (diff -r against working tree: identical)

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
workdir: /private/var/folders/q4/5pvwrm893_33lmrrz2ymd4jr0000gn/T/skill-evidence-ws.HhNJqN
model: gpt-5.6-sol
provider: openai
approval: never
sandbox: read-only
reasoning effort: none
reasoning summaries: none
session id: 019f4d09-b13a-7481-962f-dfacb882ecf1
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
I’m consulting the required superpowers guidance plus the code-review gate semantics, then I’ll give the precise pass/fail and handoff.
exec
/bin/zsh -lc "sed -n '1,240p' '/private/tmp/claude-501/-Users-liqiongyu-heyi-superpowers/6c345c79-7e78-4b8d-aea0-6d4df3365d1e/scratchpad/skill-evidence-scratch/codex-green/plugins/cache/superpowers-dev/superpowers/6.1.1-heyi.1/skills/using-superpowers/SKILL.md' && sed -n '1,280p' '/private/tmp/claude-501/-Users-liqiongyu-heyi-superpowers/6c345c79-7e78-4b8d-aea0-6d4df3365d1e/scratchpad/skill-evidence-scratch/codex-green/plugins/cache/superpowers-dev/superpowers/6.1.1-heyi.1/skills/code-review/SKILL.md' && sed -n '1,260p' '/private/tmp/claude-501/-Users-liqiongyu-heyi-superpowers/6c345c79-7e78-4b8d-aea0-6d4df3365d1e/scratchpad/skill-evidence-scratch/codex-green/plugins/cache/superpowers-dev/superpowers/6.1.1-heyi.1/skills/finishing-a-development-branch/SKILL.md'" in /private/var/folders/q4/5pvwrm893_33lmrrz2ymd4jr0000gn/T/skill-evidence-ws.HhNJqN
 succeeded in 0ms:
---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills, requiring skill invocation before ANY response including clarifying questions
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## The Rule

**Invoke relevant or requested skills BEFORE any response or action** — including clarifying questions, exploring the codebase, or checking files. If it turns out wrong for the situation, you don't have to use it.

**Before entering plan mode:** if you haven't already brainstormed, invoke the brainstorming skill first.

Then announce "Using [skill] to [purpose]" and follow the skill exactly. If it has a checklist, create a todo per item.

## Skill Priority

When multiple skills apply, process skills come first — they set the approach, then implementation skills (frontend-design, etc.) carry it out. Brainstorming and systematic-debugging are Superpowers' most common process skills, but the rule holds for any of them.

- "Let's build X" → superpowers:brainstorming first, then implementation skills.
- "Fix this bug" → superpowers:systematic-debugging first, then domain skills.

## Red Flags

These thoughts mean STOP—you're rationalizing:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "Let me gather information first" | Skills tell you HOW to gather information. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept ≠ using the skill. Invoke it. |

## Platform Adaptation

If your harness appears here, read its reference file for special instructions:

- Codex: `references/codex-tools.md`
- Pi: `references/pi-tools.md`
- Antigravity: `references/antigravity-tools.md`

## User Instructions

User instructions (CLAUDE.md, AGENTS.md, GEMINI.md, etc, direct requests) take precedence over skills, which in turn override default behavior. Only skip skill workflows or instructions when your human partner has explicitly told you to.
---
name: code-review
version: 3.2.0
description: Use when asked for a max, deep, or comprehensive review or a bug hunt, to run a security or contract review of a change, when a change is high-risk (auth, migration, public contract, concurrency), or when a workflow routes a merge gate here
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

- An explicit ask for a max, deep, strong, or comprehensive review
- Bug hunts, security reviews, contract-break reviews, regression searches
- High-risk changes: auth or permissions, migrations or data integrity,
  public API contracts, concurrency, payment paths
- A merge gate over a large branch that spans many subsystems
- The max route in superpowers:requesting-code-review and the final
  whole-branch gate in superpowers:subagent-driven-development when that
  gate escalates to max review

An explicit invocation of this skill (slash command or by name) always runs
this skill.

## When NOT to Use

- A routine, low-risk review: a small diff, a development checkpoint, or an
  ordinary branch or PR merge gate with no risk signals. Use the ordinary
  review path in superpowers:requesting-code-review instead.
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
this skill acts as a merge or finish gate (a final whole-branch gate in
superpowers:subagent-driven-development that escalated to max review, the
max route in superpowers:requesting-code-review, or any explicit gate
request):

- P0 and P1 findings block finishing. P2 and P3 findings are non-blocking
  by default.
- P2 findings require adjudication by your human partner: present each one
  with a recommendation — fix now or track as follow-up — and record their
  decision next to the finding. Never silently drop a P2; unresolved P2s
  appear in the finish report.
- Only your human partner can accept a blocking finding and proceed anyway.
  Record any such acceptance next to the finding.
- After fixing findings, re-verify with a review scoped to the fixed
  findings and the code the fixes touched. Rerun the full protocol only
  when the fix wave was broad — it touched many files beyond the original
  findings or introduced new risky surface. The gate passes only when a
  fresh re-verification shows no remaining blocking findings.
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
---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Detect environment → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Detect Environment

**Determine workspace state before presenting options:**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

This determines which menu to show and how cleanup works:

| State | Menu | Cleanup |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON` (normal repo) | Standard 4 options | No worktree to clean up |
| `GIT_DIR != GIT_COMMON`, named branch | Standard 4 options | Provenance-based (see Step 6) |
| `GIT_DIR != GIT_COMMON`, detached HEAD | Reduced 3 options (no merge) | No cleanup (externally managed) |

### Step 3: Determine Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 4: Present Options

**Normal repo and named-branch worktree — present exactly these 4 options:**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Detached HEAD — present exactly these 3 options:**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)
3. Discard this work

Which option?
```

**Don't add explanation** - keep options concise.

### Step 5: Execute Choice

#### Option 1: Merge Locally

```bash
# Get main repo root for CWD safety
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

# Merge first — verify success before removing anything
git checkout <base-branch>
git pull
git merge <feature-branch>

# Verify tests on merged result
<test command>

# Only after merge succeeds: cleanup worktree (Step 6), then delete branch
```

Then: Cleanup worktree (Step 6), then delete branch:

```bash
git branch -d <feature-branch>
```

#### Option 2: Push and Create PR

```bash
# Push branch
git push -u origin <feature-branch>
```

**Do NOT clean up worktree** — user needs it alive to iterate on PR feedback.

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

Then: Cleanup worktree (Step 6), then force-delete branch:
```bash
git branch -D <feature-branch>
```

### Step 6: Cleanup Workspace

**Only runs for Options 1 and 4.** Options 2 and 3 always preserve the worktree.

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

**If `GIT_DIR == GIT_COMMON`:** Normal repo, no worktree to clean up. Done.

**If worktree path is under `.worktrees/` or `worktrees/`:** Superpowers created this worktree — we own cleanup.

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git worktree remove "$WORKTREE_PATH"
git worktree prune  # Self-healing: clean up any stale registrations
```

**Otherwise:** The host environment (harness) owns this workspace. Do NOT remove it. If your platform provides a workspace-exit tool, use it. Otherwise, leave the workspace in place.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | yes | - | - | yes |
| 2. Create PR | - | yes | yes | - |
| 3. Keep as-is | - | - | yes | - |
| 4. Discard | - | - | - | yes (force) |

## Common Mistakes

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Open-ended questions**
- **Problem:** "What should I do next?" is ambiguous
- **Fix:** Present exactly 4 structured options (or 3 for detached HEAD)

**Cleaning up worktree for Option 2**
- **Problem:** Remove worktree user needs for PR iteration
- **Fix:** Only cleanup for Options 1 and 4

**Deleting branch before removing worktree**
- **Problem:** `git branch -d` fails because worktree still references the branch
- **Fix:** Merge first, remove worktree, then delete branch

**Running git worktree remove from inside the worktree**
- **Problem:** Command fails silently when CWD is inside the worktree being removed
- **Fix:** Always `cd` to main repo root before `git worktree remove`

**Cleaning up harness-owned worktrees**
- **Problem:** Removing a worktree the harness created causes phantom state
- **Fix:** Only clean up worktrees under `.worktrees/` or `worktrees/`

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request
- Remove a worktree before confirming merge success
- Clean up worktrees you didn't create (provenance check)
- Run `git worktree remove` from inside the worktree

**Always:**
- Verify tests before offering options
- Detect environment before presenting menu
- Present exactly 4 options (or 3 for detached HEAD)
- Get typed confirmation for Option 4
- Clean up worktree for Options 1 & 4 only
- `cd` to main repo root before worktree removal
- Run `git worktree prune` after removal

codex
Yes. The branch passes the merge gate because only P0/P1 findings block finishing; this P2 is non-blocking.

Next, I would present the P2 for mandatory human adjudication and recommend fixing it now because it roughly doubles export work for large reports. I would say:

> The merge gate passes with one unresolved P2 performance finding in `src/report.js:42`: report rows are serialized twice inside the export loop. I recommend fixing it now, especially for 10k-row reports. Alternatively, we can track it as follow-up. Which do you choose?

I would record the partner’s decision beside the finding. If they choose “fix now,” I would fix it and run a focused re-verification before finishing. If they choose “follow-up,” I would record that decision and proceed with the normal branch-finishing workflow.
tokens used
11,969
Yes. The branch passes the merge gate because only P0/P1 findings block finishing; this P2 is non-blocking.

Next, I would present the P2 for mandatory human adjudication and recommend fixing it now because it roughly doubles export work for large reports. I would say:

> The merge gate passes with one unresolved P2 performance finding in `src/report.js:42`: report rows are serialized twice inside the export loop. I recommend fixing it now, especially for 10k-row reports. Alternatively, we can track it as follow-up. Which do you choose?

I would record the partner’s decision beside the finding. If they choose “fix now,” I would fix it and run a focused re-verification before finishing. If they choose “follow-up,” I would record that decision and proceed with the normal branch-finishing workflow.
````

- Exit code: 0
