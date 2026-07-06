# Skill behavior evidence

This tree holds verbatim transcripts of real, isolated agent sessions that
back the claims in each skill's `evaluation.md`. Every evaluation row that
reports a run links a file here; the skills' structural tests fail if a
linked transcript is missing or if a results table presents an unrun
scenario as a result.

## Semantics

- Transcripts are **dated historical records**, not claims about current
  behavior. Each header records the run date, harness and exact version,
  phase, and plugin-load mechanism. A newer harness may behave differently;
  that does not invalidate the record.
- Transcripts are produced **only** by `scripts/run-skill-evidence.sh`.
  Never hand-write or edit one — an edited transcript is worse than no
  transcript. To refresh evidence, run new sessions and add new rows; do
  not alter old files.
- `red` = baseline session with the plugin absent (scratch config).
  `green` = verification session with the working-tree plugin loaded.

## Regenerating

```bash
scripts/run-skill-evidence.sh preflight <claude|codex> <red|green>
scripts/run-skill-evidence.sh run <claude|codex> <red|green> <skill> <scenario-slug> <prompt-file>
```

Prompts come verbatim from the skill's `pressure-scenarios.md`.

## Known limitations

- **GREEN transcript coverage is uneven.** Only `code-review` has committed
  green transcripts (plus a no-skill control red). For the four
  issue-workflow skills (`triaging-issues`, `decomposing-issues`,
  `reconciling-issues`, `working-from-issues`) the committed transcripts are
  RED baselines only; their green (skill-loaded) results in `evaluation.md`
  are paraphrased rows annotated `paraphrased record, predates transcript
  policy`. Backfilling green transcripts with the runner is tracked as
  follow-up work.
- Transcripts dated 2026-07-02 predate the runner's path redaction and may
  contain local home-directory paths or the operator's git identity from
  session-internal commands (no credentials; verified at review). They are
  kept unaltered as historical records.
- Claude Code headless capture contains the session's final message only;
  Codex capture includes the event stream. Rows note when a claim is
  inferred from output rather than an observed tool call.
- This tree provides **provenance** for point-in-time claims. Repeatable
  regression testing of skill behavior is the job of the superpowers-evals
  drill harness (`evals/`, not yet wired up here); the two are
  complementary, not alternatives.
