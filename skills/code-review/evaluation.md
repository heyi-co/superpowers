# Code Review Evaluation

Application-run evidence for `code-review` (a technique skill: runs verify
correct protocol application, per writing-skills). Prompts come verbatim from
[pressure-scenarios.md](pressure-scenarios.md); transcripts are produced only
by `scripts/run-skill-evidence.sh`.

## Baseline

No-skill control (RED): what a bare agent does with the planted-bug diff.

| Harness | Scenario | Observed behavior | Transcript |
| --- | --- | --- | --- |
| 2.1.198 (Claude Code) | Planted-bug diff (control) | The skill was absent (scratch config, no plugins); the agent noted the code-review skill was unavailable and reviewed the diff directly. Despite no skill it found BOTH planted bugs (dropped `await` on `db.audit` as high; `limit \|\| DEFAULT_LIMIT` falsy-zero as medium) and emitted a prose review plus a JSON array. Fields used were `file/line/severity/title/summary/failure_scenario` (bare-agent shape: `severity`+`title`, not the skill's `priority`+`category`). No style-only findings. | [link](../../docs/superpowers/evidence/code-review/2026-07-02-planted-bug-control-claude-red.md) |

Verbatim excerpts:

- planted-bug-control / claude: > "The `code-review` skill failed to execute, so I performed the review directly against the diff. Here are my findings."

## Before restyle

Runs against the pre-restyle single-file SKILL.md (imported protocol).

| Harness | Scenario | Result vs pass criteria | Transcript |
| --- | --- | --- | --- |
| 2.1.198 (Claude Code) | Planted-bug diff | PASS all criteria. Found both planted bugs: falsy-zero limit (P1, `contract`, line 2) and dropped `await` on db.audit (P2, `async`, line 8). JSON findings array present with the skill schema (`priority/file/line/category/summary/failure_scenario`). No style-only findings — reindentation explicitly dismissed as cosmetic noise. 2 findings (≤15). | [link](../../docs/superpowers/evidence/code-review/2026-07-02-planted-bug-before-claude-green.md) |
| codex-cli 0.142.5 | Planted-bug diff | PASS all criteria. Explicitly invoked `superpowers:code-review` and read SKILL.md. Found both planted bugs: dropped `await` on db.audit (P1, `async`, line 9) and falsy-zero limit (P2, `contract`, line 4). JSON findings array present with the full skill schema. No style-only findings. 2 findings (≤15). | [link](../../docs/superpowers/evidence/code-review/2026-07-02-planted-bug-before-codex-green.md) |
| 2.1.198 (Claude Code) | Clean diff | PASS. Returned exactly `[]`. No invented findings; the concat→template-literal change was correctly judged behavior-preserving and the full-function rewrite dismissed as cosmetic. | [link](../../docs/superpowers/evidence/code-review/2026-07-02-clean-diff-before-claude-green.md) |
| codex-cli 0.142.5 | Clean diff | PASS. Explicitly invoked `superpowers:code-review`, read SKILL.md, then returned exactly `[]`. No invented findings, no style commentary reported as a finding. | [link](../../docs/superpowers/evidence/code-review/2026-07-02-clean-diff-before-codex-green.md) |

## After restyle

Runs against the restructured skill: `SKILL.md` is the house shell and the
review procedure lives verbatim in `review-protocol.md`. Same prompts as
_Before restyle_.

| Harness | Scenario | Result vs pass criteria | Transcript |
| --- | --- | --- | --- |
| 2.1.198 (Claude Code) | Planted-bug diff | PASS all criteria. Dispatched a fresh reviewer subagent that followed the protocol phases inline. Found both planted bugs: dropped `await` on db.audit (P1, `async-correctness / audit-integrity`, line 9) and falsy-zero limit (P2, `logic / falsy-coercion`, line 4). JSON findings array present with the skill schema (`priority/file/line/category/summary/failure_scenario`). No style-only findings — the whitespace reindentation was explicitly dismissed as cosmetic. 2 findings (≤15). | [link](../../docs/superpowers/evidence/code-review/2026-07-02-planted-bug-after-claude-green.md) |
| codex-cli 0.142.5 | Planted-bug diff | PASS all criteria. Explicitly invoked `superpowers:code-review`, read the shell `SKILL.md`, then read `review-protocol.md` and followed its phases. Found both planted bugs: dropped `await` on db.audit (P2, `async`, line 9) and falsy-zero limit (P2, `contract`, line 4). JSON findings array present with the full skill schema. No style-only findings. 2 findings (≤15). | [link](../../docs/superpowers/evidence/code-review/2026-07-02-planted-bug-after-codex-green.md) |
| 2.1.198 (Claude Code) | Clean diff | PASS. Returned exactly `[]`. No invented findings; the concat→template-literal change was judged behavior-preserving and the whitespace re-add dismissed as cosmetic. | [link](../../docs/superpowers/evidence/code-review/2026-07-02-clean-diff-after-claude-green.md) |
| codex-cli 0.142.5 | Clean diff | PASS. Explicitly invoked `superpowers:code-review`, read `SKILL.md` then `review-protocol.md`, and returned exactly `[]`. No invented findings, no style commentary reported as a finding. | [link](../../docs/superpowers/evidence/code-review/2026-07-02-clean-diff-after-codex-green.md) |

### Before/after comparison

No pass criterion changed on any run: both harnesses still find both planted
bugs (the falsy-zero `limit` regression and the dropped `await` on the audit
write) with concrete `failure_scenario` values and the JSON findings contract,
and both still return exactly `[]` on the clean diff — the restyle stands.
Severity and category labels did shift on both harnesses across runs: claude
swapped the two priorities (before falsy-zero P1 / await P2, after await P1 /
falsy-zero P2) and its after-run categories (`logic / falsy-coercion`,
`async-correctness / audit-integrity`) drift off the protocol's category enum,
while codex relabeled P1→P2 so both bugs are P2 after; none of this affects
any pass criterion. One caveat: both claude after-runs could not read
`review-protocol.md` in the headless sandbox and worked from the SKILL.md
shell overview, so the split protocol file was only directly exercised on
codex — claude compliance is inferred from its output contract.
