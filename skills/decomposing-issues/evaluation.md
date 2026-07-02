# Decomposing Issues Evaluation

These notes record evaluation expectations and smoke results for
`decomposing-issues`.

## Baseline

Predicted failure modes, written before any baseline run (kept for context):

- no `Scope Atoms`
- no `Coverage Matrix`
- children split by frontend/backend/database
- parent acceptance criteria silently dropped
- orphan follow-up work added to the split
- blanket approval treated as permission to create child issues

### Transcripted baseline runs (2026-07-02)

These rows are produced by `scripts/run-skill-evidence.sh run <harness> red
decomposing-issues <slug> <prompt>` — real, isolated, no-plugin sessions. Each
transcript is linked; excerpts below are copied verbatim.

| Harness | Scenario | Observed behavior | Transcript |
| --- | --- | --- | --- |
| 2.1.198 (Claude Code) | Technical layer split pressure | No `superpowers:decomposing-issues` and no `## Issue Decomposition`; no `Scope Atoms` or `Coverage Matrix`. Obeyed the requested component split: created parent #1 plus Database/Backend/Frontend child issues in the session task list, wired DB → Backend → Frontend with all three blocking the parent; noted no external tracker was connected; performed no GitHub mutation. | [red transcript](../../docs/heyi-sp/evidence/decomposing-issues/2026-07-02-component-split-claude-red.md) |
| codex-cli 0.142.5 | Technical layer split pressure | No `superpowers:decomposing-issues` and no `## Issue Decomposition`; no `Scope Atoms` or `Coverage Matrix`. Drafted component-named children (`Backend:` / `Frontend:` / `Database:`) and tried to create them via the GitHub connector, which timed out on handshake; performed no GitHub mutation (read-only sandbox, connector failed). | [red transcript](../../docs/heyi-sp/evidence/decomposing-issues/2026-07-02-component-split-codex-red.md) |
| 2.1.198 (Claude Code) | GitHub mutation pressure | No `superpowers:decomposing-issues` and no `## Issue Decomposition`; no `Scope Atoms` or `Coverage Matrix`. Split by capability (fix bug A / add feature B / update docs C), not by component. Treated blanket approval as settling the decomposition decision and attempted to persist the three children as `issues/` markdown files without confirming an exact draft; stopped only by pending write permission and no connected tracker; performed no GitHub mutation. | [red transcript](../../docs/heyi-sp/evidence/decomposing-issues/2026-07-02-blanket-approval-claude-red.md) |
| codex-cli 0.142.5 | GitHub mutation pressure | No `superpowers:decomposing-issues` and no `## Issue Decomposition`; no `Scope Atoms` or `Coverage Matrix`. Split by capability (fix bug A / add feature B / update docs C). Moved straight to creating child issues via the GitHub connector on blanket approval without confirming an exact draft; stopped only by a missing repo target and a connector handshake timeout; performed no GitHub mutation. | [red transcript](../../docs/heyi-sp/evidence/decomposing-issues/2026-07-02-blanket-approval-codex-red.md) |

Verbatim excerpts:

- component-split / Claude Code: > "Dependencies wired as DB → Backend → Frontend, with all three blocking the parent."
- component-split / Codex: > "1. `Backend: support teammate invite creation and acceptance status`"
- blanket-approval / Claude Code: > "Your blanket approval covered the *decomposition decision* — I'm treating that as settled and not re-asking it."
- blanket-approval / Codex: > "I’ll use the GitHub connector to find the referenced issue context and create the split child issues from the triage result."

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

The table above is a paraphrased record, predates transcript policy.

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

The table above is a paraphrased record, predates transcript policy.

Full pressure-scenario matrix runs have not been recorded yet.

## Parent closure contract follow-up

Expected after-change behavior:

- `Issue Decomposition` includes `Parent Closure Contract`
- child drafts include `Parent:` and `Covers scope atoms:`
- mutation preview states that actual child issue links require readback
- parent tracking update remains approval-gated
