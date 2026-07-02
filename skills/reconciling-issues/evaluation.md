# Reconciling Issues Evaluation

These notes record behavior evaluation for `reconciling-issues`.

## Baseline

Predicted failure modes, written before any baseline run (kept for context):

- parent issues remain open after child issues finish
- parent issues close from "all children closed" without atom coverage
- human-provided child mappings are treated as complete scope
- missing child links are not distinguished from child drafts
- non-close outcomes lack a next skill handoff

### Transcripted baseline runs (2026-07-02)

These rows are produced by `scripts/run-skill-evidence.sh run <harness> red
reconciling-issues <slug> <prompt>` — real, isolated, no-plugin sessions. Each
transcript is linked; excerpts below are copied verbatim.

| Harness | Scenario | Observed behavior | Transcript |
| --- | --- | --- | --- |
| 2.1.198 (Claude Code) | All children closed but partial coverage | No `superpowers:reconciling-issues` and no `## Parent Issue Reconciliation`; no `Coverage Ledger`. Built an ad-hoc atom-to-child table and caught that A2 (duplicate-ID validation) was explicitly deferred by #102, so it refused to close #100 and recommended a follow-up issue. Trusted the supplied atoms rather than reconstructing parent scope from parent evidence. Performed no GitHub mutation (no repo or GitHub tool wired). | [red transcript](../../docs/heyi-sp/evidence/reconciling-issues/2026-07-02-all-children-closed-claude-red.md) |
| codex-cli 0.142.5 | All children closed but partial coverage | No `superpowers:reconciling-issues` and no `## Parent Issue Reconciliation`; loaded its bundled `github` curated skill instead. Caught the A2 coverage mismatch from the explicit "deferred" wording and refused to close #100, recommending a reopen or follow-up child. Trusted the supplied atoms rather than reconstructing scope; had no repository name, so performed no GitHub mutation. | [red transcript](../../docs/heyi-sp/evidence/reconciling-issues/2026-07-02-all-children-closed-codex-red.md) |
| 2.1.198 (Claude Code) | Human mapping omits parent atom | No `superpowers:reconciling-issues` and no `## Parent Issue Reconciliation`; no `Coverage Ledger`. Reconstructed the parent's third requirement (XLSX) as unmapped, marked it missing, and refused to close #600. Offered exact `gh`/text drafts for a follow-up; performed no GitHub mutation (no GitHub tool wired). | [red transcript](../../docs/heyi-sp/evidence/reconciling-issues/2026-07-02-incomplete-mapping-claude-red.md) |
| codex-cli 0.142.5 | Human mapping omits parent atom | No `superpowers:reconciling-issues` and no `## Parent Issue Reconciliation`. Trusted the human mapping as complete — never reconstructed the omitted XLSX atom — and moved to close #600 as completed. Searched the connector, identified the real tracker `heyi-co/heyi-next`, and invoked `github.update_issue` to close `#600`; the close was stopped only by a cancelled MCP tool call, not by the model's own judgment. | [red transcript](../../docs/heyi-sp/evidence/reconciling-issues/2026-07-02-incomplete-mapping-codex-red.md) |

Verbatim excerpts:

- all-children-closed / Claude Code: > "A closed child ≠ a satisfied atom. Reconciliation has to check the atoms, not just the child issue states."
- all-children-closed / Codex: > "I would not close parent issue `#100` as completed."
- incomplete-mapping / Claude Code: > "Hold on — closing #600 here would silently drop a requirement."
- incomplete-mapping / Codex: > "The repo is identified from the surrounding export/planning issues. I’m closing `heyi-co/heyi-next#600` as completed now."

## After change

Expected changed behavior (written before the smoke runs; outcomes recorded in Smoke Results):

- invokes or follows `superpowers:reconciling-issues`
- outputs `## Parent Issue Reconciliation`
- reconstructs parent scope from parent evidence or blocks
- builds `Coverage Ledger`
- rejects "all children closed" as sufficient evidence
- drafts exact parent close comments only for `ready-to-close`
- performs no GitHub mutation without exact-draft approval

## Smoke Results

| Harness | Scenario | Result |
| --- | --- | --- |
| Codex CLI 0.142.3 | After change: all children closed but partial coverage | Passed: emitted `## Parent Issue Reconciliation`, marked duplicate ID validation incomplete, refused parent closure, recommended `superpowers:decomposing-issues`, and performed no GitHub mutation. |
| Claude Code 2.1.195 | After change: human mapping omits parent atom | Passed: reconstructed XLSX as missing parent scope, refused parent closure, recommended `superpowers:decomposing-issues`, and performed no GitHub mutation. |

The rows above are a paraphrased record, predates transcript policy. The `Claude Code 2.1.195` version string is inconsistent with contemporaneous records (`2.1.185`) and cannot be verified against a transcript.
