# Evidence transcript

- Date: 2026-07-02
- Harness: 2.1.198 (Claude Code)
- Phase: red
- Prompt file: /tmp/cr-planted-bug.md
- Workspace: scratch git repository (created by run-skill-evidence.sh)
- Plugin load: none (scratch CLAUDE_CONFIG_DIR, no plugins)

## Prompt

````text
Review the following change. Use the code-review skill if it is available.
Do not modify any files and do not contact any external service; produce the
review as text with your findings as a JSON array.

diff --git a/src/orders.js b/src/orders.js
index 3f1c2aa..9d04b71 100644
--- a/src/orders.js
+++ b/src/orders.js
@@ -1,15 +1,13 @@
 const DEFAULT_LIMIT = 50;
 
-async function listOrders(db, customerId, limit) {
-  if (limit === undefined || limit === null) {
-    limit = DEFAULT_LIMIT;
-  }
-  const rows = await db.query(
-    'SELECT * FROM orders WHERE customer_id = ? ORDER BY created_at DESC LIMIT ?',
-    [customerId, limit]
-  );
-  await db.audit('orders.list', customerId);
-  return rows;
-}
+async function listOrders(db, customerId, limit) {
+  const effectiveLimit = limit || DEFAULT_LIMIT;
+  const rows = await db.query(
+    'SELECT * FROM orders WHERE customer_id = ? ORDER BY created_at DESC LIMIT ?',
+    [customerId, effectiveLimit]
+  );
+  db.audit('orders.list', customerId);
+  return rows;
+}
 
 module.exports = { listOrders, DEFAULT_LIMIT };
````

## Session output

````text
The `code-review` skill failed to execute, so I performed the review directly against the diff. Here are my findings.

## Review of `src/orders.js`

Two behavioral regressions were introduced by this refactor.

### 1. `limit || DEFAULT_LIMIT` breaks an explicit `limit` of `0`
The old code only substituted the default when `limit` was `undefined` or `null`. The new `limit || DEFAULT_LIMIT` also triggers on `0` (and any other falsy value like `NaN` or `""`). A caller passing `limit = 0` — which previously produced `LIMIT 0` (zero rows) — now silently gets `LIMIT 50`. This is a genuine semantic change to the public API.

### 2. Dropped `await` on `db.audit(...)` makes auditing fire-and-forget
`await db.audit('orders.list', customerId)` became `db.audit('orders.list', customerId)`. Consequences:
- The function can return `rows` before the audit record is persisted; if the process exits or the request completes, the audit write may be lost — a compliance concern for an order-listing audit trail.
- If `db.audit` returns a rejecting promise, the rejection is now unhandled (potential `unhandledRejection`, and in newer Node with default settings, process crash), rather than propagating to the caller.

```json
[
  {
    "file": "src/orders.js",
    "line": 5,
    "severity": "high",
    "title": "Dropped await on db.audit makes audit logging fire-and-forget",
    "summary": "Changing `await db.audit(...)` to `db.audit(...)` means listOrders can return before the audit is persisted, the audit write may be lost, and a rejected audit promise becomes an unhandled rejection instead of propagating to the caller.",
    "failure_scenario": "db.audit performs an async write that rejects (e.g., audit store unavailable). Previously the caller received the rejection; now the promise is unhandled — the audit is silently lost and, under Node's default unhandled-rejection handling, may crash the process. Even on success, listOrders resolves before the audit is durably written, so a fast process exit can drop the record."
  },
  {
    "file": "src/orders.js",
    "line": 2,
    "severity": "medium",
    "title": "limit || DEFAULT_LIMIT overrides an explicit limit of 0",
    "summary": "Replacing the `undefined`/`null` check with `limit || DEFAULT_LIMIT` treats a falsy `limit` of 0 as unset, so an explicit `limit = 0` now returns 50 rows instead of 0.",
    "failure_scenario": "A caller invokes listOrders(db, customerId, 0) expecting `LIMIT 0` (no rows). The old code passed 0 through; the new code substitutes DEFAULT_LIMIT (50) and returns up to 50 rows — a behavior change that can leak more data than the caller requested. Other falsy inputs (NaN, empty string) are likewise coerced to the default rather than surfacing as errors."
  }
]
```

Both findings are behavioral changes, not stylistic — the refactor's intent (dedupe the default-assignment) is reasonable, but preserve `limit == null ? DEFAULT_LIMIT : limit` (or the original explicit check) and keep the `await` on `db.audit`.
````

- Exit code: 0
