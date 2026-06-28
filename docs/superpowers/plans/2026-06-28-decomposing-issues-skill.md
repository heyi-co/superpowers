# Decomposing Issues Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use heyi-sp:subagent-driven-development (recommended) or heyi-sp:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a repository-agnostic `decomposing-issues` skill that produces coverage-preserving child issue drafts from triaged large or blocked issues.

**Architecture:** Add one new skill directory with `SKILL.md`, pressure scenarios, and evaluation notes. Add one structural shell test mirroring the existing issue workflow tests. Update `triaging-issues`, `working-from-issues`, README, and the issue workflow spec so `needs-decomposition` routes to the new skill instead of inline deep decomposition.

**Tech Stack:** Markdown skills, Bash structural tests, existing Superpowers skill conventions.

## Global Constraints

- Target repository is Superpowers core; keep the skill repository-agnostic.
- Do not add third-party runtime dependencies.
- Do not add automatic GitHub issue mutation.
- Use `apply_patch` for manual file edits.
- Follow existing issue skill patterns in `skills/triaging-issues` and `skills/working-from-issues`.
- Skill behavior changes need pressure scenarios and evaluation notes.

---

### Task 1: Structural Test First

**Files:**
- Create: `tests/decomposing-issues/test-decomposing-issues-skill.sh`
- Modify: none

**Interfaces:**
- Consumes: expected new files under `skills/decomposing-issues/`
- Produces: failing structural test that defines the new skill contract

- [ ] **Step 1: Write failing structural test**

Create `tests/decomposing-issues/test-decomposing-issues-skill.sh` with the same helper functions used by existing issue skill tests. Assert:

- `skills/decomposing-issues/SKILL.md` exists
- frontmatter name is `decomposing-issues`
- description includes split/decompose/child issue triggers and `Triage Result`
- raw issues route to `superpowers:triaging-issues`
- output includes `## Issue Decomposition`
- output contract includes `Scope Atoms`, `Coverage Matrix`, `Child Issue Drafts`, `Parent Disposition`, `Mutation Preview`
- method includes parent reframe, vertical slicing, SPIDR, Hamburger, explicit deferrals, orphan-child check, component-split warning
- GitHub mutation uses two-step exact-draft approval
- pressure scenarios and evaluation files exist
- README lists `decomposing-issues`
- `triaging-issues` recommends `superpowers:decomposing-issues`
- `working-from-issues` routes `needs-decomposition` and `blocked-by-resolution-loop` to `superpowers:decomposing-issues`

- [ ] **Step 2: Run test to verify RED**

Run:

```bash
bash tests/decomposing-issues/test-decomposing-issues-skill.sh
```

Expected: FAIL because `skills/decomposing-issues/SKILL.md` and related files do not exist.

### Task 2: New Skill Files

**Files:**
- Create: `skills/decomposing-issues/SKILL.md`
- Create: `skills/decomposing-issues/pressure-scenarios.md`
- Create: `skills/decomposing-issues/evaluation.md`

**Interfaces:**
- Consumes: design spec and external prior-art summary
- Produces: discoverable skill and behavior evaluation artifacts

- [ ] **Step 1: Implement `SKILL.md`**

Use concise sections:

- Overview
- Required Input
- Read-Only Default
- Decomposition Method
- Output Contract
- GitHub Mutation Gate
- Red Flags
- Behavior Testing

The output contract must include `Scope Atoms` and `Coverage Matrix` so child issues can be checked against parent scope.

- [ ] **Step 2: Add pressure scenarios**

Create scenarios for:

- mixed broad issue
- easy-to-drop parent criterion
- frontend/backend/database split pressure
- repeated failed fix/review loop
- product decision disguised as decomposition
- security-sensitive parent
- blanket approval mutation pressure
- orphan child draft

- [ ] **Step 3: Add evaluation notes**

Record baseline expected failures before the skill and note that full behavior smoke testing must cover Codex App and Claude Code before PR.

- [ ] **Step 4: Run test to verify GREEN for new files**

Run:

```bash
bash tests/decomposing-issues/test-decomposing-issues-skill.sh
```

Expected: remaining failures only for README and handoff updates.

### Task 3: Handoff Updates

**Files:**
- Modify: `skills/triaging-issues/SKILL.md`
- Modify: `skills/working-from-issues/SKILL.md`
- Modify: `docs/superpowers/specs/2026-06-28-issue-to-workflow-skills-draft.md`

**Interfaces:**
- Consumes: `decomposing-issues` skill name and output contract
- Produces: stable routing from triage/router skills to the decomposition skill

- [ ] **Step 1: Update `triaging-issues`**

For `needs-decomposition` and `blocked-by-resolution-loop`, recommend `superpowers:decomposing-issues`. Keep triage read-only and avoid depending on `working-from-issues`.

- [ ] **Step 2: Update `working-from-issues`**

For `needs-decomposition` and `blocked-by-resolution-loop`, stop implementation and route to `superpowers:decomposing-issues`. Keep the resolution loop returning to `triaging-issues` for fresh actionability first.

- [ ] **Step 3: Update issue workflow spec**

Add the new skill as Phase 3/4 follow-up and replace deep inline split language with the `decomposing-issues` handoff.

- [ ] **Step 4: Run related tests**

Run:

```bash
bash tests/decomposing-issues/test-decomposing-issues-skill.sh
bash tests/triaging-issues/test-triaging-issues-skill.sh
bash tests/working-from-issues/test-working-from-issues-skill.sh
```

Expected: all pass.

### Task 4: README and Verification

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: new skill name and placement
- Produces: discoverability in Collaboration skill list

- [ ] **Step 1: Add README entry**

Add `decomposing-issues` after `triaging-issues` and before `working-from-issues`.

- [ ] **Step 2: Run full local verification**

Run:

```bash
bash tests/decomposing-issues/test-decomposing-issues-skill.sh
bash tests/triaging-issues/test-triaging-issues-skill.sh
bash tests/working-from-issues/test-working-from-issues-skill.sh
git diff --check
bash scripts/lint-shell.sh
bash tests/shell-lint/test-lint-shell.sh
```

Expected: all commands exit 0.

### Task 5: Behavior Smoke

**Files:**
- Modify: `skills/decomposing-issues/evaluation.md`

**Interfaces:**
- Consumes: pressure scenarios and local plugin checkout
- Produces: recorded Codex and Claude behavior evidence

- [ ] **Step 1: Run at least targeted dry-run prompts**

Run one Codex CLI and one Claude Code dry-run for the highest-risk scenario:
blanket approval to create child issues from a decomposition result.

- [ ] **Step 2: Record observations**

Update `evaluation.md` with harness versions, whether the skill was invoked or followed, whether coverage matrix was produced, and whether GitHub mutation was avoided.

- [ ] **Step 3: Re-run structural verification**

Run:

```bash
bash tests/decomposing-issues/test-decomposing-issues-skill.sh
```

Expected: pass.
