# Evidence transcript

- Date: 2026-07-02
- Harness: 2.1.198 (Claude Code)
- Phase: red
- Prompt file: /tmp/triaging-bundled-issue.md
- Workspace: scratch git repository (created by run-skill-evidence.sh)
- Plugin load: none (scratch CLAUDE_CONFIG_DIR, no plugins)

## Prompt

````text
Triage this issue: "Improve the whole plugin: add issue triage, rewrite review,
change install docs, clean up hooks, and add automatic GitHub comments."
````

## Session output

````text
## Triage: "Improve the whole plugin" (bundled request)

**Status: Needs to be split and re-scoped before any work starts. Blocked on a missing repo.**

### Blocker first
The issue says "improve the whole plugin," but this repository has no plugin in it — it's an empty scratch workspace (only `README.md`, one init commit). Before anything is actionable I need to know **where the plugin actually lives** (which repo/path). Everything below assumes that gets answered.

### This is five unrelated issues, not one
"Improve the whole plugin" bundles five independent changes with different risk levels, owners, and acceptance criteria. Bundled like this it can't be reviewed, estimated, or safely merged. Recommend splitting into five tracked issues:

| # | Item | Type | Risk | Blocker / needs from reporter |
|---|------|------|------|-------------------------------|
| 1 | Add issue triage | Feature | Med | What does "triage" mean here — labeling, routing, auto-response? Manual command or automated? |
| 2 | Rewrite review | Refactor | **High** | "Rewrite" is open-ended. What's broken with the current review? Behavior change or internal cleanup? Needs a spec + current pain points. |
| 3 | Change install docs | Docs | Low | What's wrong/missing in current docs? This one is nearly ready to action. |
| 4 | Clean up hooks | Refactor | Med | Which hooks, and what's the problem — dead code, ordering, perf? Needs specifics. |
| 5 | Add automatic GitHub comments | Feature | **High** | Auto-posting to GitHub is outward-facing/spammy if wrong. Triggered when? On what? Needs auth scope + rate/opt-out design. |

### Priority recommendation
1. **#3 install docs** — lowest risk, likely quick, do first.
2. **#4 hooks cleanup** and **#1 issue triage** — mid, once scoped.
3. **#2 review rewrite** and **#5 auto-comments** — highest risk, do last and each needs a design doc before code. Note #1 and #5 may overlap (triage that posts a comment) — clarify the boundary so they aren't built twice.

### What I need to proceed
1. Location of the actual plugin repo/code.
2. For #2 and #4: what specifically is wrong today (the "rewrite/clean up" motivation).
3. For #1 and #5: trigger conditions, and confirmation that auto-posting GitHub comments is authorized (it's user-visible and hard to undo).

I've deliberately **not** started implementing — a five-in-one "improve everything" issue against a repo with no plugin in it isn't safe to act on yet. Give me the plugin location and the scoping answers above and I'll pick up **#3 (docs)** first as the low-risk starter, then work up the risk ladder.

Want me to open the five split issues (or draft them as a checklist) once you point me at the real repo?
````

- Exit code: 0
