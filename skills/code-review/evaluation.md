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

## Gate lightening (2026-07-11)

Shell-only change, protocol untouched (`review-protocol.md` digest unchanged):
max review stops being the default merge-gate path (routing narrowed to
explicit asks, high-risk changes, and large branches), the gate blocks on
P0/P1 only with P2 routed to human adjudication, and post-fix re-review is
scoped to the fix wave instead of an unconditional full rerun.
`requesting-code-review` and `subagent-driven-development` restatements
updated in the same change. Motivation: the heavy path had become the
default for every merge (routing listed "PR review, branch review,
merge-gate review" as max triggers), and P2-blocking plus full reruns made
the minimum cost of any gated merge two full max runs; the priority-label
drift documented above made P2-blocking reruns re-blockable by relabeling
alone.

New scenarios 3 (routing) and 4 (gate-p2) in
[pressure-scenarios.md](pressure-scenarios.md) capture the change; before
runs use the pre-edit tree (claude: working tree before the edit; codex
gate-p2: a worktree pinned to the pre-edit commit), after runs use the
edited tree.

### Before (heavy semantics, RED for this change)

| Harness | Scenario | Observed behavior | Transcript |
| --- | --- | --- | --- |
| 2.1.206 (Claude Code) | 3 routing-default | Routed the routine low-risk pre-merge review through the code-review max protocol: reviewer subagent applied the findings contract, output framed as JSON findings array (`[]`) with P0-P2 gate language. | [link](../../docs/superpowers/evidence/code-review/2026-07-11-routing-default-before-claude-green.md) |
| codex-cli 0.144.1 | 3 routing-default | Explicitly invoked the code-review skill for the same routine diff, read SKILL.md and the full review-protocol.md phases, returned the JSON findings contract (`[]`). | [link](../../docs/superpowers/evidence/code-review/2026-07-11-routing-default-before-codex-green.md) |
| 2.1.206 (Claude Code) | 4 gate-p2 | Declared the gate failed on the single P2 ("P2 blocks too"), offered only fix-plus-full-rerun or an explicit human waiver, quoting the then-current blocking rule. | [link](../../docs/superpowers/evidence/code-review/2026-07-11-gate-p2-before-claude-green.md) |
| codex-cli 0.144.1 | 4 gate-p2 | Declared the gate failed ("P2 findings are blocking"), demanded fix plus a full-diff rerun with no P0-P2 findings, or an explicit human waiver. Run executed from a worktree pinned to the pre-edit commit. | [link](../../docs/superpowers/evidence/code-review/2026-07-11-gate-p2-before-codex-green.md) |

### After (lightened semantics, GREEN)

| Harness | Scenario | Result vs pass criteria | Transcript |
| --- | --- | --- | --- |
| 2.1.206 (Claude Code) | 3 routing-default | PASS. Explicitly declined the max path ("scoped to comprehensive, security, or high-risk reviews"), produced an ordinary prose review with verdict and discretionary observations; no JSON findings contract, no finder fan-out. | [link](../../docs/superpowers/evidence/code-review/2026-07-11-routing-default-after-claude-green.md) |
| codex-cli 0.144.1 | 3 routing-default | PASS. Announced "explicitly routine and low-risk, I'll keep the review focused and won't invoke the deep/high-risk review process"; read only using-superpowers and its codex reference (never opened code-review files); returned a prose review ("No blocking findings... safe to merge") with coverage observations. | [link](../../docs/superpowers/evidence/code-review/2026-07-11-routing-default-after-codex-green.md) |
| 2.1.206 (Claude Code) | 4 gate-p2 | PASS. No blocking findings (P0/P1 absent); presented the P2 to the human partner with a fix-now recommendation and a track-as-follow-up alternative; scoped re-verify named for the fix path instead of a full protocol rerun; refused to silently drop the P2. | [link](../../docs/superpowers/evidence/code-review/2026-07-11-gate-p2-after-claude-green.md) |
| codex-cli 0.144.1 | 4 gate-p2 | PASS. "The branch passes the merge gate because only P0/P1 findings block finishing; this P2 is non-blocking"; presented the P2 for mandatory human adjudication with a fix-now recommendation and a track alternative; named a focused re-verification for the fix path. | [link](../../docs/superpowers/evidence/code-review/2026-07-11-gate-p2-after-codex-green.md) |

### Regression (scenarios 1-2 on the edited tree)

Explicit invocation must keep the max protocol's recall and empty-diff
honesty. Pre-change baselines are the 2026-07-02 "After restyle" rows above.

| Harness | Scenario | Result vs pass criteria | Transcript |
| --- | --- | --- | --- |
| 2.1.206 (Claude Code) | 1 planted-bug | PASS all criteria. Found both planted bugs: dropped `await` on db.audit (P1, line 10) and falsy-zero limit (P2, line 5), concrete failure scenarios, JSON array, no style-only findings, 2 findings (≤15). Category labels (`reliability`, `correctness`) drift off the protocol enum, same caveat as the 2026-07-02 runs. | [link](../../docs/superpowers/evidence/code-review/2026-07-11-planted-bug-lighten-claude-green.md) |
| codex-cli 0.144.1 | 1 planted-bug | PASS all criteria. Found both planted bugs: dropped `await` on db.audit (P1, `async`, line 9) and falsy-zero limit (P2, `contract`, line 4), concrete failure scenarios, JSON array with protocol enum categories, no style-only findings, 2 findings (≤15). | [link](../../docs/superpowers/evidence/code-review/2026-07-11-planted-bug-lighten-codex-green.md) |
| 2.1.206 (Claude Code) | 2 clean-diff | PASS. Returned exactly `[]`; the template-literal rewrite judged behavior-preserving; whitespace churn noted as observation, not a finding. | [link](../../docs/superpowers/evidence/code-review/2026-07-11-clean-diff-lighten-claude-green.md) |
| codex-cli 0.144.1 | 2 clean-diff | PASS. Returned exactly `[]` after reading the shell and protocol; no invented findings. | [link](../../docs/superpowers/evidence/code-review/2026-07-11-clean-diff-lighten-codex-green.md) |

Run notes: the 2026-07-11 sessions ran with the scratch root relocated via
`SKILL_EVIDENCE_SCRATCH` (the harness sandbox blocks writes to the default
`~/.cache` scratch, which surfaces as a spurious OAuth-refresh failure);
codex sessions were interrupted once by a provider usage limit and resumed
after reset. A first codex after-batch was discarded: `codex plugin add`
installs from the marketplace repo's committed HEAD, so with the edits
still uncommitted those sessions read the pre-edit skills (see the
2026-07-11 followups.md entry); the batch was rerun after committing, with
cache freshness verified against the new gate text.

## Protocol revisions

Local fork edits to `review-protocol.md` after the verbatim import. Each entry
states the change, why, and what evidence backs it.

| Date | Change | Nature and evidence |
| --- | --- | --- |
| 2026-07-06 | Phase 1 finder-angle count corrected from "Run 10 independent finder angles" to "Run 11" | Factual alignment, no semantic change: the protocol defines 11 angle sections (Angle A–E, Reuse, Simplification, Efficiency, Altitude, Conventions, Security) and the candidate contract's `angle` enum lists 11 values, so the stated count contradicted the protocol's own contents and made the parallel fan-out instruction ambiguous. No new session runs; the edit makes the instruction match what every recorded run already executed. |
| 2026-07-06 | Intro no longer names the harness-specific `/code-review max` command; it now says "the max review protocol" | Wording only: the protocol is consumed on multiple harnesses (Codex CLI has no `/code-review` command), so a Claude Code command name in the role preamble was misleading. No behavior instruction changed. No new session runs. |
