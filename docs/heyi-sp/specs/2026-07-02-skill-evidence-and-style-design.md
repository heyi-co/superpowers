# Skill Evidence Backfill and Code-Review Restyle

Status: approved design, 2026-07-02.

Two workstreams on the fork-added skills. Workstream 1 backfills the missing
RED-phase behavior evidence for the issue-workflow suite and fixes the
integrity defects in the existing evaluation records. Workstream 2 restructures
`skills/code-review` to match the house skill style without changing the review
protocol's behavior content.

This fork is not targeting upstream merge; upstream-sync economics are out of
scope for both workstreams.

## Background

An audit of the five fork-added skills against `skills/writing-skills/SKILL.md`
found:

- `decomposing-issues` and `reconciling-issues` have no executed RED baseline.
  `skills/reconciling-issues/evaluation.md` presents two baseline rows inside
  its Smoke Results table whose result cells read "Expected failure mode
  recorded before skill implementation" — planned runs recorded as results.
- `triaging-issues` has one real baseline scenario of twelve;
  `working-from-issues` has one real baseline scenario on one harness.
- `skills/code-review/` has no `evaluation.md` and no `pressure-scenarios.md`.
- No verbatim transcripts exist anywhere; all recorded runs are paraphrased.
- One after-change row records `Claude Code 2.1.195` while every other record
  in the repo says `2.1.185`.
- The five shell tests are structural greps; they cannot distinguish a real
  evaluation record from typed-in prose.
- `skills/code-review/SKILL.md` is a verbatim import
  (`stellarlinkco/skills@0f64fa92645442ffe47bcec39faede35a795435a`, v3.0.0)
  whose provenance is not recorded in the artifact, whose frontmatter
  description summarizes workflow and output (violating the repo's own SDO
  rule), and whose system-prompt voice does not match the house skill
  structure. Its name also collides with Claude Code's built-in
  `/code-review` command on that harness.

## Decisions

1. Evidence runs use real clean CLI sessions on both harnesses
   (`codex` 0.142.5, `claude` 2.1.198 at design time; record actual versions
   at run time), with full transcripts committed to the repo.
2. Scope is highest-risk scenarios first (about 25 sessions), not the full
   scenario matrix.
3. `skills/code-review` is restructured as a house-style `SKILL.md` shell plus
   a verbatim `review-protocol.md`; the protocol text does not change.
4. The skill keeps the name `code-review`; the built-in-command collision is
   handled by a routing clause in When NOT to Use, not by renaming.

## Sequencing

- The four issue skills' RED baseline runs are independent of Workstream 2
  and can run at any point.
- Workstream 2 runs in this order: write
  `skills/code-review/pressure-scenarios.md`; run the before-restyle
  application sessions against the current single-file skill; restructure the
  skill; run the after-restyle sessions.
- Workstream 1's code-review row is therefore executed inside Workstream 2's
  order, with prompts taken from the pressure-scenarios.md written in its
  first step.

## Workstream 1 — Evidence backfill

### Run matrix

Prompts are taken verbatim from each skill's `pressure-scenarios.md`. Each row
below runs on both harnesses unless noted.

| Skill | Runs | Sessions |
| --- | --- | --- |
| triaging-issues | RED: public handling of a security report; bundled too-large issue | 4 |
| working-from-issues | RED: blanket-approval mutation pressure; starting code from a raw issue | 4 |
| decomposing-issues | RED: component-split pressure; blanket-approval child-issue creation | 4 |
| reconciling-issues | RED: all-children-closed closure pressure; incomplete human mapping | 4 |
| code-review | Application scenarios per writing-skills' technique-skill guidance, each run twice on both harnesses — before the restyle against the current single-file skill, and after it against the restructured skill: a diff with a planted known bug must yield contract-conformant findings; a clean diff must yield `[]`. Plus one no-skill control on one harness | 9 |

The existing real records (triaging prompt-injection baseline, working-from
Codex baseline, the real after-change rows) are kept and annotated as
historical paraphrased records; they are not deleted or re-fabricated.

### Run mechanics

- RED baseline sessions run with a scratch config directory
  (`CLAUDE_CONFIG_DIR` / `CODEX_HOME` pointed at a temporary directory) so the
  plugin and its skills are genuinely absent. A scratch directory also lacks
  credentials and first-run state, and the two harnesses differ here (Codex
  keeps `auth.json` in `CODEX_HOME`; Claude Code credentials live in the macOS
  Keychain): the runner seeds each scratch directory with the minimum
  authentication and onboarding/trust state its harness needs, and performs a
  no-op preflight session per harness to prove non-interactive runs work
  before any evidence run counts.
- GREEN/application sessions must load the working-tree version of the skills.
  The runner records the load mechanism in `evaluation.md` and verifies it by
  checking that every file of the loaded skill directory matches the working
  tree (hash comparison of `SKILL.md` and any companion behavior files, such
  as code-review's `review-protocol.md`) before the run counts as evidence.
- A committed runner script, `scripts/run-skill-evidence.sh`, drives the
  sessions so runs are repeatable. One scenario, one harness, one phase per
  invocation; it writes the transcript file and prints the path.

### Evidence storage and format

- Transcripts:
  `docs/heyi-sp/evidence/<skill>/<YYYY-MM-DD>-<scenario-slug>-<harness>-<red|green>.md`.
  Evidence lives under `docs/`, not `skills/`, because `skills/` ships in the
  installed plugin package.
- Every new `evaluation.md` row includes: date, harness and exact version,
  scenario id, observed outcome, and a relative link to the transcript.
- RED rows additionally quote the agent's rationalizations verbatim, as
  `writing-skills` requires.
- The two fabricated baseline rows in `skills/reconciling-issues/evaluation.md`
  are replaced by the real runs. The after-change row recording `2.1.195` is
  kept as a paraphrased historical record, annotated that its version string is
  inconsistent with contemporaneous records (`2.1.185`) and cannot be verified
  against a transcript.
- Pre-existing paraphrased rows gain the annotation
  "paraphrased record, predates transcript policy".

### Structural test updates

- Tests that assert version-string literals (for example
  `tests/working-from-issues/test-working-from-issues-skill.sh` asserting
  `Codex CLI 0.142.3` and `Claude Code 2.1.185`) change to assert that
  every evaluation row not annotated as a paraphrased historical record links
  to an existing transcript file under `docs/heyi-sp/evidence/`, and that no
  results-table cell contains the string `Expected failure mode recorded`.
- New assertions apply to all five skills' evaluation files.

### Honesty rule

If a RED baseline run does not exhibit the predicted failure, the record says
so plainly. A non-failing baseline weakens the necessity claim for that
scenario and is recorded as a finding, not adjusted or discarded.

### Acceptance criteria

- Each of the four issue skills has at least two RED baseline scenarios with
  committed transcripts on both harnesses.
- `skills/code-review/` has `evaluation.md` and `pressure-scenarios.md` with
  the before/after application runs above (both files are created in
  Workstream 2's first step; see Sequencing).
- No evaluation file presents an unrun scenario as a result.
- Version strings in transcripted rows match their transcripts; paraphrased
  historical rows carry the annotation instead.
- All five structural tests pass once both workstreams have landed (the
  code-review test changes are Workstream 2 deliverables).

## Workstream 2 — code-review restyle

### File structure

`skills/code-review/SKILL.md` becomes a house-style shell of roughly 400
words:

- Frontmatter `description` rewritten to Use-when form: triggering conditions
  only (review a PR / branch / diff, find bugs, security or contract review,
  merge gate), no pipeline or output summary.
- Overview with the core principle: recall first — at this grade a missed bug
  is worse than a plausible finding that needs maintainer judgment.
- When to Use / When NOT to Use, containing the routing clause:
  - An explicit invocation of this skill (slash command or by name) always
    runs this skill; the native-command preference below applies only to
    natural-language review requests.
  - For a natural-language review request on a harness with a native
    max-grade review command (for example Claude Code's built-in
    `/code-review`), prefer the native command.
  - Workflow-internal invocations (the subagent-driven-development final
    whole-branch gate, requesting-code-review's max route) always use this
    skill so the P0–P3 / at-most-15 / JSON findings contract keeps its shape.
  - Reviewing received feedback belongs to `superpowers:receiving-code-review`;
    the pre-review checklist belongs to `superpowers:requesting-code-review`.
- Dispatch instruction: hand `review-protocol.md` to a fresh reviewer
  subagent (preserving the reviewer isolation subagent-driven-development
  requires). A reader that is itself an already-dispatched reviewer subagent
  (the subagent-driven-development final gate) follows the protocol phases
  inline instead of dispatching again; harnesses without subagents do the
  same.
- Output contract summary: JSON array of at most 15 findings, P0–P3 ranked,
  `[]` when nothing survives; same order as prose when a human-readable
  report is requested.
- Red Flags: reviewing without reading the protocol file; dumping raw JSON
  when the user asked for a readable review; posting PR comments without an
  explicit ask; softening or dropping findings to pass a gate.
- Behavior Testing pointer to `pressure-scenarios.md`.

`skills/code-review/review-protocol.md` receives the imported protocol body
verbatim, with a header comment recording the source
(`stellarlinkco/skills@0f64fa92645442ffe47bcec39faede35a795435a`, v3.0.0) and
the rule that edits to the protocol require behavior evidence.

New `skills/code-review/pressure-scenarios.md` and
`skills/code-review/evaluation.md` hold the Workstream 1 application runs.

### Wiring updates

- `skills/requesting-code-review/SKILL.md` needs no changes.
  `skills/subagent-driven-development/SKILL.md` also needs no changes, but
  only because the shell's dispatch instruction explicitly tells an
  already-dispatched reviewer to execute the protocol inline — without that
  clause its final gate would double-dispatch.
- README's one-line description of code-review is updated to match the new
  description.
- `tests/code-review-skill/test-code-review-integration.sh`: the sha256 pin
  moves from `SKILL.md` to `review-protocol.md` (the protocol is verbatim, so
  a pin remains meaningful); new structural assertions cover the shell
  (Use-when description, routing clause, dispatch instruction, Red Flags,
  provenance header in the protocol file).

### Acceptance criteria

- At migration time, a diff shows `review-protocol.md` is byte-identical to
  the protocol body previously embedded in `SKILL.md` apart from the added
  provenance header; the updated sha256 pin then guards against later drift.
- The new `SKILL.md` contains no workflow summary in its description and
  passes the updated structural test.
- The after-restyle application runs pass on both harnesses and match or
  improve on the before-restyle runs; the before/after comparison is recorded
  in `skills/code-review/evaluation.md`.

## Out of scope

Deferred as separate future work items, in no order:

- Any change to the review protocol's behavior content.
- A size-based downgrade path for the subagent-driven-development final
  review.
- Unifying the per-task Critical/Important vocabulary with the P0–P3 scale.
- Removing stale `GEMINI.md` references from the issue skills.
- Documentation drift fixes: the 2026-06-28 decomposing design predates the
  Parent Closure Contract; an untracked stale copy of the issue-to-workflow
  draft sits at `docs/heyi-sp/specs/2026-06-28-issue-to-workflow-skills-draft.md`.
- Wiring the pressure scenarios into the superpowers-evals drill harness.

## Risks

- A RED baseline may not fail. Handled by the honesty rule; the scenario list
  may then need revisiting rather than the record.
- Harness versions drift between design and run time. Records always carry the
  run-time version from the transcript.
- Codex and Claude Code plugin-loading behavior may differ in how a
  working-tree skill is injected; the runner's whole-directory hash check is
  the guard that the right version of every behavior file was actually
  loaded.
- Keychain-based Claude Code credentials may not be visible to a
  scratch-config session in every setup; the per-harness preflight run
  catches auth or onboarding blockers before any evidence run counts.
