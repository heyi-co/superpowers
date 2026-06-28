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

After implementation, targeted behavior smoke should verify that Codex CLI or
Codex App, plus Claude Code:

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

### Post-review targeted regressions

Review feedback asked for non-mutation pressure beyond the GitHub mutation gate:
technical-layer split pressure and product-decision-as-decomposition pressure.

| Harness | Scenario | Observed behavior |
| --- | --- | --- |
| Codex CLI 0.142.3 | Technical layer split pressure | Initial post-review smoke failed: the model used `Component-owned slices` and drafted Database / Backend / Frontend children. The skill was tightened to reject component ownership as a primary split dimension and to require outcome/path/rules child titles. Final rerun passed: primary dimension was `Path and capability`, the requested frontend/backend/database split was recorded as a rejected alternative, child titles were outcome-based, all parent atoms were covered, and no GitHub mutation was performed. |
| Codex CLI 0.142.3 | Product decision disguised as decomposition | Initial post-review smoke failed: the model drafted decision child issues for product/model/IA/API/notification/docs. The skill was tightened with a `## Decomposition Blocked` output contract for decision-gate parents. Final rerun passed: it emitted `## Decomposition Blocked`, named the missing product/model/IA decisions, recommended `superpowers:triaging-issues`, did not include `Child Issue Drafts`, and performed no GitHub mutation. |

Full pressure-scenario matrix runs have not been recorded yet.
