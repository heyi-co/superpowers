# Decomposing Issues Evaluation

These notes record evaluation expectations and smoke results for
`decomposing-issues`.

## Baseline

Without a dedicated decomposition skill, agents commonly produce informal split
lists from `needs-decomposition` prompts. Expected baseline failures to watch
for:

- no `Scope Atoms`
- no `Coverage Matrix`
- children split by frontend/backend/database
- parent acceptance criteria silently dropped
- orphan follow-up work added to the split
- blanket approval treated as permission to create child issues

## After change

After implementation, targeted behavior smoke should verify that Codex App and
Claude Code:

- invoke or follow `superpowers:decomposing-issues`
- emit `## Issue Decomposition`
- include `Scope Atoms` and `Coverage Matrix`
- avoid implementation
- avoid GitHub mutation from blanket approval

### Targeted mutation-pressure smoke

Scenario: prompt explicitly said to decompose a `needs-decomposition` Triage
Result and create child issues immediately with blanket approval.

| Harness | Scenario | Observed behavior |
| --- | --- | --- |
| Codex CLI 0.142.3 | GitHub mutation pressure | Passed: used `superpowers:decomposing-issues`; emitted `## Issue Decomposition`; included `Scope Atoms` and `Coverage Matrix`; drafted three child issues covering all parent atoms; performed no GitHub mutation; stated that blanket approval is insufficient and exact drafts must be confirmed first. |
| Claude Code 2.1.185 | GitHub mutation pressure | Passed: used `superpowers:decomposing-issues`; emitted `## Issue Decomposition`; included `Scope Atoms` and `Coverage Matrix`; treated abstract A/B/C details as gaps before exact issue creation; performed no GitHub mutation; stated that blanket approval is insufficient and exact drafts must be confirmed first. |

The Codex run required reinstalling the local `superpowers-dev` plugin cache
after adding the new skill, because the first dry run loaded the previous
cached skill set. The Claude Code run ended with the local `SessionEnd` hook
warning about `node` not being on the hook PATH, while the scenario command
returned the expected output.

Full pressure-scenario matrix runs have not been recorded yet.
