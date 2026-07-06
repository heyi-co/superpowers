# Follow-ups

This repository has GitHub issues disabled, so follow-up work is tracked
here. Add new entries at the bottom of the open list with a date and a
source; move finished entries to the Done section with the PR that closed
them. Entries are work items, not documentation — keep them short.

## Open

### 2026-07-06 · Backfill GREEN transcripts for the four issue-workflow skills

Source: 2026-07-06 fork evaluation.

Only `code-review` has committed green (skill-loaded) transcripts (8 green
plus a no-skill control red). `triaging-issues`, `decomposing-issues`,
`reconciling-issues`, and `working-from-issues` have RED baselines only;
their green results exist solely as paraphrased evaluation rows annotated
`paraphrased record, predates transcript policy`. The evidence tree's own
standard is transcript-or-it-didn't-happen. Scope: ~2 high-risk scenarios ×
2 harnesses per skill (~16 sessions) via `scripts/run-skill-evidence.sh`,
then replace the paraphrased rows and update the README disclosure.

### 2026-07-06 · code-review control baseline shows no failure

Source: 2026-07-06 fork evaluation.

The no-skill control found both planted bugs and emitted a JSON array; the
only delta vs the skill run was field naming. The current planted diff
(13 lines, 2 shallow bugs) proves schema compliance, not recall value, and
by the repo's own writing-skills standard a control that doesn't fail can't
justify the guidance. Author a harder planted diff (cross-file, async, or
removed-behavior bug) that the bare agent demonstrably misses.

### 2026-07-06 · Slim decomposing-issues: template-embedded instructions, quadruplicated rule, field bloat

Source: 2026-07-06 fork evaluation. Behavior-shaping; run pressure
scenarios before/after.

Three form problems: normative instructions live inside the output-template
fence (template-echo risk; writing-skills calls this form wrong), the
no-layer-split rule is stated four times (converge to one prose statement
plus one Red Flag), and the child-issue template carries 11 required fields
(`Release constraint` is never defined; `Parent coverage` overlaps `Covers
scope atoms`; SPIDR duplicates dimensions already listed).

### 2026-07-06 · reconciling-issues: undefined term, duplicated contract, misplaced red flag

Source: 2026-07-06 fork evaluation.

`needs-child-readback` is never defined in the skill that uses it; the
Parent Closure Contract semantics are written in both decomposing and
reconciling (pick one authority, reference from the other); the Red Flag
"Making working-from-issues own parent closure" polices another skill's
behavior and cannot be triggered by an agent running this one.

### 2026-07-06 · triaging-issues: axis overlap and undefined Confidence scale

Source: 2026-07-06 fork evaluation. Behavior-shaping; run pressure
scenarios before/after.

Classification and Actionability overlap heavily (`duplicate`,
`not-repo-owned`, security appear on both axes; legal combinations are
undefined; Classification's `unclear` has no actionability counterpart) —
converge to one axis plus modifiers. The `Confidence:` output field has no
defined scale, so its value cannot be verified.

### 2026-07-06 · Track upstream #1901/#1910; drop local packaging diff once merged

Source: 2026-07-06 fork evaluation (upstream survey).

The fork's changes to `scripts/package-codex-plugin.sh` and
`tests/codex/test-package-codex-plugin.sh` (worktree-safe git check, TZ=UTC
deterministic archives) correspond file-for-file to open upstream PRs
obra/superpowers#1901 and obra/superpowers#1910. Once upstream merges them,
verify semantic equivalence on the next sync and drop the local diff to
clear this conflict surface.

### 2026-07-06 · Upstream #1931/#1932/#1934 rewrite files carrying the fork's review-gate wiring

Source: 2026-07-06 fork evaluation (upstream survey).

obra's open skill-refactor PRs touch `requesting-code-review` and
`subagent-driven-development`, the two files carrying the fork's gate
wiring (P0-P2 blocking, code-review routing, dot-graph nodes). The first
sync after they merge will need a manual semantic replay of the fork
sections onto the new structure — a three-way merge will not resolve it —
followed by a rerun of `tests/code-review-skill/test-code-review-integration.sh`.

### 2026-07-06 · working-from-issues: wire branch finishing and persist triage artifacts

Source: 2026-07-06 fork evaluation. Behavior-shaping; run pressure
scenarios before/after.

The description promises "make a PR for" but no ready route reaches
`superpowers:finishing-a-development-branch`, and none of the four issue
skills reference `superpowers:using-git-worktrees` — debugging/docs-fix
paths edit the current branch directly. Triage Results, Issue
Decompositions, and Coverage Ledgers exist only in session output; define a
persistence path (for example `docs/superpowers/triage/<issue>.md`),
matching the brainstorming/writing-plans convention of committing
artifacts.

### 2026-07-06 · Run live evals for the 2026-07-06 behavior-shaping edits

Source: 2026-07-06 fork evaluation and the independent branch review of
`fix/eval-findings-2026-07-06`.

Three behavior-shaping edits shipped with structural tests and pressure
scenarios but no live session evidence: the Gate Semantics section
(circuit breaker, rerun label authority), the standing pre-authorization
escape hatch (including the vague-phrasing and repo-file negative cases;
reconciling/triaging/working-from have the shared prose but no scenarios of
their own yet), and the narrowed working-from-issues trigger (two
must-not-trigger negatives). Run the matching scenarios on both harnesses
with `scripts/run-skill-evidence.sh`, land transcripts under
`docs/superpowers/evidence/`, and add evaluation rows. Can be executed
together with the GREEN-transcript backfill entry.

## Done

(none yet)
