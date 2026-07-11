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

Related fact discovered by fork CI (2026-07-06): the script's tar.gz branch
uses bsdtar-only flags (`--uid/--gid/--uname/--gname`), so packaging only
works where bsdtar is the system tar (macOS). Fork CI runs on macos-latest
for this reason. If portability ever matters, GNU tar needs
`--owner=0 --group=0` instead — an upstream-shaped fix, not fork-local.

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

Update 2026-07-11: the Gate Semantics portion is superseded — the gate was
rewritten (P0/P1 blocking, P2 adjudication, scoped re-verify) with live
before/after transcripts under `docs/superpowers/evidence/code-review/`
(scenario 4, gate-p2). The escape-hatch and working-from-issues portions
remain open.

### 2026-07-11 · tests/claude-code LLM tests break under non-English operator config

Source: 2026-07-11 review-gate lightening session.

`tests/claude-code/test-helpers.sh` `run_claude` invokes plain `claude -p`
with the operator's real `~/.claude` config, so a user-level "respond in
Chinese" instruction makes the English keyword assertions fail
(`test-subagent-driven-development.sh` "Mentions loading plan", exit 1)
even though the described workflow is correct. Reproduced identically on an
untouched pre-edit checkout, so it is environmental, not content drift.
Fix direction: isolate sessions with a scratch `CLAUDE_CONFIG_DIR` seeded
with credentials only, as `scripts/run-skill-evidence.sh` already does.

### 2026-07-11 · run-skill-evidence codex GREEN installs git HEAD, and its load check can pass vacuously

Source: 2026-07-11 review-gate lightening session.

`codex plugin add` materializes the plugin cache from the marketplace
repo's committed state, not the working tree, so a codex GREEN run against
uncommitted skill edits silently tests the old content (observed live: the
cached `code-review/SKILL.md` carried the pre-edit gate text while the
working tree carried the new one). `verify_codex_green_load` did not catch
it because the path it extracts from `codex plugin list` resolved to the
marketplace root (the working tree itself), making the `diff -r` vacuous.
Fix direction: verify against the version-keyed cache directory the session
actually reads (`$CODEX_HOME/plugins/cache/...`), and either require a
clean committed tree for codex GREEN runs or fail loudly when
`git status --porcelain` is non-empty in the marketplace root.

## Done

(none yet)
