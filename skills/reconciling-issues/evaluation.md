# Reconciling Issues Evaluation

These notes record behavior evaluation for `reconciling-issues`.

## Baseline

No `reconciling-issues` skill existed. Expected baseline failures:

- parent issues remain open after child issues finish
- parent issues close from "all children closed" without atom coverage
- human-provided child mappings are treated as complete scope
- missing child links are not distinguished from child drafts
- non-close outcomes lack a next skill handoff

## After change

Expected changed behavior:

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
| Codex CLI 0.142.3 | Baseline: all children closed pressure | Expected failure mode recorded before skill implementation. |
| Claude Code 2.1.185 | Baseline: incomplete mapping pressure | Expected failure mode recorded before skill implementation. |
| Codex CLI 0.142.3 | After change: all children closed but partial coverage | Passed: emitted `## Parent Issue Reconciliation`, marked duplicate ID validation incomplete, refused parent closure, recommended `superpowers:decomposing-issues`, and performed no GitHub mutation. |
| Claude Code 2.1.195 | After change: human mapping omits parent atom | Passed: reconstructed XLSX as missing parent scope, refused parent closure, recommended `superpowers:decomposing-issues`, and performed no GitHub mutation. |
