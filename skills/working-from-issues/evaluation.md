# Working From Issues Evaluation Notes

These notes record the initial smoke evaluation for `working-from-issues`.
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
