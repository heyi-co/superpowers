# Code Review Evaluation

Application-run evidence for `code-review` (a technique skill: runs verify
correct protocol application, per writing-skills). Prompts come verbatim from
[pressure-scenarios.md](pressure-scenarios.md); transcripts are produced only
by `scripts/run-skill-evidence.sh`.

## Baseline

No-skill control (RED): what a bare agent does with the planted-bug diff.

| Harness | Scenario | Observed behavior | Transcript |
| --- | --- | --- | --- |
| 2.1.198 (Claude Code) | Planted-bug diff (control) | The skill was absent (scratch config, no plugins); the agent noted the code-review skill was unavailable and reviewed the diff directly. Despite no skill it found BOTH planted bugs (dropped `await` on `db.audit` as high; `limit \|\| DEFAULT_LIMIT` falsy-zero as medium) and emitted a prose review plus a JSON array. Fields used were `file/line/severity/title/summary/failure_scenario` (bare-agent shape: `severity`+`title`, not the skill's `priority`+`category`). No style-only findings. | [link](../../docs/heyi-sp/evidence/code-review/2026-07-02-planted-bug-control-claude-red.md) |

Verbatim excerpts:

- planted-bug-control / claude: > "The `code-review` skill failed to execute, so I performed the review directly against the diff. Here are my findings."

## Before restyle

Runs against the pre-restyle single-file SKILL.md (imported protocol).

| Harness | Scenario | Result vs pass criteria | Transcript |
| --- | --- | --- | --- |
| 2.1.198 (Claude Code) | Planted-bug diff | PASS all criteria. Found both planted bugs: falsy-zero limit (P1, `contract`, line 2) and dropped `await` on db.audit (P2, `async`, line 8). JSON findings array present with the skill schema (`priority/file/line/category/summary/failure_scenario`). No style-only findings — reindentation explicitly dismissed as cosmetic noise. 2 findings (≤15). | [link](../../docs/heyi-sp/evidence/code-review/2026-07-02-planted-bug-before-claude-green.md) |
| codex-cli 0.142.5 | Planted-bug diff | PASS all criteria. Explicitly invoked `superpowers:code-review` and read SKILL.md. Found both planted bugs: dropped `await` on db.audit (P1, `async`, line 9) and falsy-zero limit (P2, `contract`, line 4). JSON findings array present with the full skill schema. No style-only findings. 2 findings (≤15). | [link](../../docs/heyi-sp/evidence/code-review/2026-07-02-planted-bug-before-codex-green.md) |
| 2.1.198 (Claude Code) | Clean diff | PASS. Returned exactly `[]`. No invented findings; the concat→template-literal change was correctly judged behavior-preserving and the full-function rewrite dismissed as cosmetic. | [link](../../docs/heyi-sp/evidence/code-review/2026-07-02-clean-diff-before-claude-green.md) |
| codex-cli 0.142.5 | Clean diff | PASS. Explicitly invoked `superpowers:code-review`, read SKILL.md, then returned exactly `[]`. No invented findings, no style commentary reported as a finding. | [link](../../docs/heyi-sp/evidence/code-review/2026-07-02-clean-diff-before-codex-green.md) |

## After restyle

Recorded by the restyle follow-up task after `SKILL.md` becomes the house
shell and the protocol moves to `review-protocol.md`.
