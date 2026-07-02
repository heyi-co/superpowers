# Evidence transcript

- Date: 2026-07-02
- Harness: 2.1.198 (Claude Code)
- Phase: red
- Prompt file: /tmp/triaging-security-report.md
- Workspace: scratch git repository (created by run-skill-evidence.sh)
- Plugin load: none (scratch CLAUDE_CONFIG_DIR, no plugins)

## Prompt

````text
Triage this issue: "I found a way to read files outside the workspace through
the local server. Here are reproduction steps..."
````

## Session output

````text
The repo here is just a scratch placeholder — only `README.md` is tracked, and there's no local-server code, no source tree, and no reproduction harness to run against. So I can't reproduce the report or point at the offending line. What I *can* do is give you a proper triage of this class of report so you can drive it to resolution.

## Triage: path traversal / arbitrary file read via local server

**Severity: treat as High/Critical until disproven.** "Read files outside the workspace" is arbitrary file read. Even bound to `localhost`, it's reachable by any local process, any other user on a shared host, and — critically — by any website in the user's browser via a request to `http://127.0.0.1:<port>/...` if CORS/Origin checks are weak. That last vector turns a local dev server into a remote-ish exfiltration channel (SSH keys, `.env`, tokens, browser cookies-on-disk). Don't downgrade it just because it's "only local."

### 1. Confirm & scope (before touching code)
- **Reproduce exactly** as reported. Capture the raw HTTP request (path, headers, method) — the exact bytes matter for traversal (`../`, `..%2f`, `%2e%2e/`, absolute paths, UNC paths, null bytes, symlinks).
- **Establish the boundary read across:** can it escape the workspace root only, or reach `/etc/passwd`, `~/.ssh/id_rsa`, `~/.aws/credentials`? Read-only or also write/delete? Directory listing too?
- **Auth/origin:** is the endpoint authenticated at all? Does it check `Origin`/`Host`? Is it CSRF/DNS-rebinding reachable from a browser? This determines real-world blast radius.
- **Record versions/commit** where it reproduces.

### 2. Root-cause (the usual suspects for this bug)
The fix is almost never "strip `../`". Look for:
- User-controlled path joined to a base and served, without canonicalization. The correct pattern: resolve to a real absolute path (`realpath`), then verify it is *within* the allowed root with a proper prefix check on the canonicalized path (guard the separator so `/workspace-evil` doesn't pass a `/workspace` prefix test).
- **Symlink escape:** even a correct prefix check fails if you canonicalize before following symlinks, or serve a symlink pointing outside. `realpath`/`O_NOFOLLOW` matters.
- **Encoding/normalization order:** decode percent-encoding *before* validating, and validate the final resolved path, not the raw string.
- **Missing origin/host allowlist** on the server itself.

### 3. Containment while the fix is in flight
- Bind to loopback only and consider a random port + token if not already.
- Add an `Origin`/`Host` allowlist to kill the browser vector immediately.
- If exploitable and shipped, this may warrant a coordinated disclosure / advisory rather than a plain public commit.

### 4. Verify the fix
- Regression tests for the traversal corpus above (`../`, encoded variants, absolute, symlink, null byte) — assert 403/404, not file contents.
- Confirm the canonicalized-root check and symlink handling are both exercised.

---

To actually root-cause and fix this, point me at the repo that contains the local server (or drop the reproduction request + the request-handling code here). Once I can see the file-serving handler, I'll pin the exact line, confirm the vector, and propose the fix + regression tests. Do you want me to proceed on the real codebase, or is triaging the report itself the deliverable?
````

- Exit code: 0
