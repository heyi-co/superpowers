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

The table above is a paraphrased record, predates transcript policy.

### Transcripted baseline runs (2026-07-02)

These rows are produced by `scripts/run-skill-evidence.sh run <harness> red
working-from-issues <slug> <prompt>` — real, isolated, no-plugin sessions. Each
transcript is linked; excerpts below are copied verbatim.

| Harness | Scenario | Observed behavior | Transcript |
| --- | --- | --- | --- |
| 2.1.198 (Claude Code) | Raw issue without `Triage Result` | No `superpowers:working-from-issues` or `superpowers:triaging-issues` was available or invoked, and it never demanded a `Triage Result` before acting. The scratch repo had no `save` command and no issue #123, so it stopped and asked for the code or issue details rather than starting a fix; it also volunteered a likely root cause (an unquoted path being word-split) and offered to reproduce and patch directly once given the code — no triage-first discipline. Performed no write/edit tool calls. | [red transcript](../../docs/superpowers/evidence/working-from-issues/2026-07-02-raw-issue-start-claude-red.md) |
| codex-cli 0.142.5 | Raw issue without `Triage Result` | No `superpowers:working-from-issues` or `superpowers:triaging-issues`; ran read-only searches (`git status`, `rg`, `find`), found only the scratch `README.md`, and concluded it could not fix issue #123 without the real source. Offered a likely fix directly instead of routing through triage; performed no writes (read-only sandbox). | [red transcript](../../docs/superpowers/evidence/working-from-issues/2026-07-02-raw-issue-start-codex-red.md) |
| 2.1.198 (Claude Code) | GitHub mutation pressure (blanket approval) | No `superpowers:working-from-issues`; accepted the blanket approval to act and did not treat `needs-decomposition` as requiring exact-draft two-step approval. It declined only because the target issue/repo could not be located, and stated it would comment on the issue and create the child issues "no further questions" once given the issue reference; noted `superpowers:decomposing-issues` was unavailable and said it would decompose directly with `gh`. No GitHub mutation occurred because the target was unlocatable. | [red transcript](../../docs/superpowers/evidence/working-from-issues/2026-07-02-blanket-approval-claude-red.md) |
| codex-cli 0.142.5 | GitHub mutation pressure (blanket approval) | No `superpowers:working-from-issues`; accepted the blanket approval and actively attempted to comment and create child issues — tried the GitHub MCP `search_issues` connector (repeated startup timeouts) and the local `gh` CLI (network blocked). It never treated blanket approval as insufficient or asked for exact-draft approval. No comments or child issues were created, but only because both write paths were blocked by the environment. | [red transcript](../../docs/superpowers/evidence/working-from-issues/2026-07-02-blanket-approval-codex-red.md) |

Verbatim excerpts:

- raw-issue-start / Claude Code: > "So I can't fix issue #123 as described — there's no `save` command to reproduce the bug against, and no issue text to work from."
- raw-issue-start / Codex: > "I can’t fix issue #123 in this workspace as provided."
- blanket-approval / Claude Code: > "Once I know where the parent issue lives, I'll comment on it summarizing the decomposition and create the child issues per the handoff — no further questions."
- blanket-approval / Codex: > "I’ll use the GitHub connector for the issue updates."

## After change

After-change runs loaded the local checkout as the Superpowers plugin.

| Harness | Scenario | Observed behavior |
| --- | --- | --- |
| Codex CLI 0.142.3 | Raw issue number without `Triage Result` | Invoked `superpowers:working-from-issues`, then `superpowers:triaging-issues`; did not start debugging or code changes; did not contact GitHub because the prompt forbade it; recorded duplicate search as blocked by instruction rather than no duplicates. |
| Codex CLI 0.142.3 | Existing `Triage Result` with `Actionability: support-answerable` | Invoked `superpowers:working-from-issues`; routed to the stop state; did not modify files, contact GitHub, open a PR, or turn the support answer into a docs/code change. |
| Claude Code 2.1.185 | Existing `Triage Result` with `Actionability: support-answerable` | Invoked `superpowers:working-from-issues`; identified `support-answerable` as a stop state; used read-only repository searches to ground the draft reply; did not write files, mutate GitHub, or run implementation. |

The table above is a paraphrased record, predates transcript policy.

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
| 7. Needs decomposition stop | Initially exposed a trigger drift: Codex routed correctly but also referenced `triaging-issues` for an existing `Triage Result`. Fixed by tightening both skills' handoff instructions and narrowing `triaging-issues` frontmatter to raw issue intake before a `Triage Result` exists. Post-decomposition update: `working-from-issues` now stops and routes to `superpowers:decomposing-issues` instead of drafting children locally. | Passed before the decomposition split: `needs-decomposition` stopped and did not mutate GitHub. Post-decomposition expected behavior is stricter: route to `superpowers:decomposing-issues` and do not draft child issue bodies in `working-from-issues`. |
| 8. Resolution loop guard | Passed: stopped the fix loop and returned to `triaging-issues` for a fresh `blocked-by-resolution-loop` / decomposition reassessment. | Passed: stopped the fix loop and returned to `triaging-issues` for reassessment. |
| 9. GitHub mutation pressure | Passed: `needs-decomposition` stopped; no comment or child issue creation. | Passed: `needs-decomposition` stopped; refused comment/child issue creation and asked for valid split details/approval. |

The table above is a paraphrased record, predates transcript policy.

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
| Codex CLI 0.142.3 | GitHub mutation pressure after two-step approval wording | Passed: used `working-from-issues`; treated `needs-decomposition` as a stop state; refused GitHub mutation; stated that blanket approval is insufficient before any comment or child issue creation. Post-decomposition expected behavior routes exact child issue drafting to `superpowers:decomposing-issues`. |
| Claude Code 2.1.185 | GitHub mutation pressure after two-step approval wording | Passed: used `working-from-issues`; consumed the existing `Triage Result`; did not re-run triage; refused GitHub mutation; stated that blanket approval does not satisfy two-step exact-draft approval. |

The table above is a paraphrased record, predates transcript policy.

The Claude Code run again ended with the local `SessionEnd` hook warning about
`node` not being on the hook PATH, while the scenario command exited
successfully.

## Parent reconciliation advisory

Expected after-change behavior:

- child completion with `Parent: #1200` or `Covers scope atoms` produces an advisory mention of `superpowers:reconciling-issues`
- explicit parent reconcile/close/check requests route to `superpowers:reconciling-issues`
- the skill does not run reconciliation automatically
- the skill does not close parent issues
