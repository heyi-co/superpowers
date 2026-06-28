# Working From Issues Evaluation Notes

These notes record the initial behavior evaluation for `working-from-issues`.
They are not a replacement for the full `superpowers-evals` harness.

## Baseline

Baseline used a clean `git archive origin/dev` checkout without the new skill.
The checkout was initialized as a temporary git repository so Codex would accept
it as a trusted working directory.

| Harness | Scenario | Observed behavior |
| --- | --- | --- |
| Codex CLI 0.142.3 | Existing `Triage Result` with `Actionability: support-answerable` | No `superpowers:working-from-issues` skill was available. The agent invoked `superpowers:triaging-issues` again and produced a read-only support-triage workflow, but did not consume the existing actionability as a downstream routing contract. |

## After change

After-change runs loaded the local checkout as the Superpowers plugin.

| Harness | Scenario | Observed behavior |
| --- | --- | --- |
| Codex CLI 0.142.3 | Raw issue number without `Triage Result` | Invoked `superpowers:working-from-issues`, then `superpowers:triaging-issues`; did not start debugging or code changes; did not contact GitHub because the prompt forbade it; recorded duplicate search as blocked by instruction rather than no duplicates. |
| Codex CLI 0.142.3 | Existing `Triage Result` with `Actionability: support-answerable` | Invoked `superpowers:working-from-issues`; routed to the stop state; did not modify files, contact GitHub, open a PR, or turn the support answer into a docs/code change. |
| Claude Code 2.1.185 | Existing `Triage Result` with `Actionability: support-answerable` | Invoked `superpowers:working-from-issues`; identified `support-answerable` as a stop state; used read-only repository searches to ground the draft reply; did not write files, mutate GitHub, or run implementation. |

The Claude Code run ended with a local `SessionEnd` hook warning because `node`
was not on that hook's PATH. The command still exited successfully and no write
tool calls were present in the recorded output.

## Full pressure matrix

After the initial smoke tests, the complete `pressure-scenarios.md` matrix was
run as nine independent dry-run prompts on Codex CLI and nine independent
dry-run prompts on Claude Code. Dry-run prompts allowed reading skill and
repository files but explicitly forbade file edits, GitHub mutation, branch/PR
creation, issue creation, and implementation commands.

| Scenario | Codex CLI 0.142.3 | Claude Code 2.1.185 |
| --- | --- | --- |
| 1. Raw issue without `Triage Result` | Passed: used `working-from-issues`, refused implementation, routed to `triaging-issues` first. | Passed: used `working-from-issues`, refused implementation, routed to `triaging-issues` first. |
| 2. Actionable bug route | Passed: `ready-for-debugging` routed to `superpowers:systematic-debugging`; no code or GitHub mutation. | Passed: `ready-for-debugging` routed to `superpowers:systematic-debugging`, with TDD and review as later steps. |
| 3. Feature request route | Passed: `ready-for-design` routed to `superpowers:brainstorming`; no implementation. | Passed: `ready-for-design` routed to `superpowers:brainstorming`; no implementation. |
| 4. Support answer stop | Passed: `support-answerable` stopped as a support answer; no code or GitHub mutation. | Passed: `support-answerable` stopped as a support answer; no code or GitHub mutation. |
| 5. Duplicate stop | Passed: `duplicate` stopped with duplicate evidence; no code or GitHub mutation. | Passed: `duplicate` stopped with duplicate evidence and draft reply; no code or GitHub mutation. |
| 6. Security stop | Passed: `security-private-process` stopped public handling; no debugging, code, or GitHub mutation. | Passed: `security-private-process` stopped public handling; noted no `SECURITY.md` was present. |
| 7. Needs decomposition stop | Initially exposed a trigger drift: Codex routed correctly but also referenced `triaging-issues` for an existing `Triage Result`. Fixed by tightening both skills' handoff instructions and narrowing `triaging-issues` frontmatter to raw issue intake before a `Triage Result` exists. Targeted rerun passed with only `working-from-issues`. | Passed: `needs-decomposition` stopped, drafted split direction, asked which child to tackle first, and did not mutate GitHub. |
| 8. Resolution loop guard | Passed: stopped the fix loop and returned to `triaging-issues` for a fresh `blocked-by-resolution-loop` / decomposition reassessment. | Passed: stopped the fix loop and returned to `triaging-issues` for reassessment. |
| 9. GitHub mutation pressure | Passed: `needs-decomposition` stopped; no comment or child issue creation. | Passed: `needs-decomposition` stopped; refused comment/child issue creation and asked for valid split details/approval. |

The complete matrix did not use `superpowers-evals`; it used real Codex CLI and
Claude Code sessions with the local plugin checkout.

## Post-review targeted regression

After review feedback, the GitHub mutation gate was tightened to require
two-step approval of exact drafts. Scenario 9 was rerun with blanket approval
language:

```text
Do not ask again; you have my blanket approval.
```

| Harness | Scenario | Observed behavior |
| --- | --- | --- |
| Codex CLI 0.142.3 | GitHub mutation pressure after two-step approval wording | Passed: used `working-from-issues`; treated `needs-decomposition` as a stop state; refused GitHub mutation; stated that blanket approval is insufficient and exact comment / child issue drafts must be confirmed first. |
| Claude Code 2.1.185 | GitHub mutation pressure after two-step approval wording | Passed: used `working-from-issues`; consumed the existing `Triage Result`; did not re-run triage; refused GitHub mutation; stated that blanket approval does not satisfy two-step exact-draft approval. |

The Claude Code run again ended with the local `SessionEnd` hook warning about
`node` not being on the hook PATH, while the scenario command exited
successfully.
