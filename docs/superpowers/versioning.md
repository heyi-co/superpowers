# Fork Versioning Policy

This fork (`heyi-co/superpowers`) tracks upstream `obra/superpowers` and layers
its own changes on top. To keep the plugin version meaningful across every
harness manifest without colliding with upstream's numbers, the fork uses a
**baseline + fork-iteration** scheme.

## The scheme

```
6.1.1-heyi.1
└─┬─┘ └──┬─┘
  │      └─ fork iteration on top of that upstream baseline
  └──────── the upstream version this fork is currently based on
```

- **Prefix = the upstream baseline.** It is always a real upstream release
  (currently `6.1.1`, upstream's latest tag). We never invent a prefix — no
  self-minted `6.2.0`, `6.3.0`, and so on.
- **`-heyi.N` suffix = fork iteration.** Every fork-side change ships as an
  increment of `N`, no matter how big the change is. The claiming protocol, CI
  guards, skill tweaks — all are `heyi.N` bumps, never prefix bumps.

## Rules

1. **Never bump the prefix yourself.** The prefix changes only when you sync a
   new upstream release into the fork.
2. **On upstream sync:** set the prefix to the new upstream version and reset
   the suffix to `heyi.1`. Example: syncing upstream `6.1.2` turns
   `6.1.1-heyi.4` into `6.1.2-heyi.1`.
3. **On any fork-only change you release:** increment the suffix within the
   current baseline. Example: `6.1.1-heyi.1` -> `6.1.1-heyi.2`.
4. **Always bump via `scripts/bump-version.sh <version>`**, never by hand — it
   keeps all seven manifests in sync. `bump-version.sh --check` runs in
   fork-tests CI and as a pre-commit hook to catch drift.

## Why the `-` prerelease suffix, not `+` build metadata

Both Claude Code and Codex decide "is there an update?" by **string
inequality**, not SemVer precedence (verified against Claude Code 2.1.204's
update gate `o.version === v` and openai/codex `core-plugins` `IfVersionChanged`
string equality). Any string change triggers an update; ordering does not
matter for these harnesses.

We use `-heyi.N` (SemVer prerelease) rather than `+heyi.N` (build metadata)
because the version string becomes a filesystem cache-directory name
(`cache/<marketplace>/<plugin>/<version>/`), and `+` is unverified and riskier
there on the Claude side. `-` is safe on both.

Note: strictly per SemVer, `6.1.1-heyi.1` sorts *below* `6.1.1`. That is
harmless here because neither harness orders versions — but keep it in mind if
some future tool ever does a real SemVer comparison on these strings.

## History

Earlier fork releases (`6.1.2`, `6.2.0`) were self-minted numbers from when the
fork reused upstream's clean SemVer line, which would collide with upstream's
own future numbering. Starting at `6.1.1-heyi.1`, the fork uses this
baseline-tracking scheme instead. See PR #15 (drift fix + initial fork version
line) and its follow-up that adopted this policy.
