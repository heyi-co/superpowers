# Evidence transcript

- Date: 2026-07-02
- Harness: 2.1.198 (Claude Code)
- Phase: green
- Prompt file: /tmp/cr-planted-bug.md
- Workspace: scratch git repository (created by run-skill-evidence.sh)
- Plugin load: --plugin-dir /Users/liqiongyu/heyi/superpowers (working tree loaded directly; no cache to drift)

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
The target file isn't in the working tree, so I reviewed the supplied unified diff directly (the diff is self-contained). The reindentation of the whole function is cosmetic noise; the two substantive changes are the limit-defaulting rewrite and the dropped `await`. Both introduce real defects.

## Findings

**[P1] `src/orders.js:2` — `contract` / falsy-zero: `limit || DEFAULT_LIMIT` mis-handles `limit === 0`**
The old code defaulted only when `limit` was `undefined` or `null` (`limit === undefined || limit === null`), so an explicit `limit = 0` was passed straight through to the query. The new `const effectiveLimit = limit || DEFAULT_LIMIT` treats every falsy value as missing. A caller invoking `listOrders(db, id, 0)` — expecting zero rows — now silently gets `LIMIT 50`. Empty string, `NaN`, and `false` are similarly coerced to the default. This is a behavioral regression introduced by the diff, not just style.

**[P2] `src/orders.js:8` — `async`: removed `await` on `db.audit(...)` makes the audit write fire-and-forget**
The change drops `await` from `await db.audit('orders.list', customerId)` → `db.audit(...)`. `db.audit` is (was) an async call returning a promise. Consequences: (1) the audit record is no longer guaranteed to be persisted before `listOrders` returns its rows — ordering/durability of the audit trail is lost, and if the process/request completes quickly the write may never flush; (2) if the audit promise rejects, it is now an unhandled promise rejection (no `.catch`, no `await`), which in modern Node terminates the process by default and is silently swallowed otherwise. The audit failure previously propagated to the caller; now it is invisible. For an audit/compliance call this is a meaningful integrity loss.

## JSON

```json
[
  {
    "priority": "P1",
    "file": "src/orders.js",
    "line": 2,
    "category": "contract",
    "summary": "Switching from an explicit undefined/null check to `limit || DEFAULT_LIMIT` treats a falsy limit as missing, so an explicit limit of 0 (or '', NaN) is overridden to DEFAULT_LIMIT.",
    "failure_scenario": "Caller invokes listOrders(db, customerId, 0) expecting zero rows; `0 || DEFAULT_LIMIT` evaluates to 50, so the query runs with LIMIT 50 and returns up to 50 orders instead of none."
  },
  {
    "priority": "P2",
    "file": "src/orders.js",
    "line": 8,
    "category": "async",
    "summary": "Dropping `await` on db.audit turns the audit write into fire-and-forget, losing completion ordering and surfacing rejections as unhandled promise rejections.",
    "failure_scenario": "db.audit('orders.list', customerId) rejects (e.g. audit DB unavailable): with no await/catch the rejection is unhandled (process-terminating under Node's default unhandledRejection behavior) and the failure no longer propagates to the caller; on success, listOrders can return rows before the audit record is persisted, so a crash between return and flush loses the audit entry."
  }
]
```

No other substantive defects survived verification (remaining diff lines are pure reindentation).
````

- Exit code: 0
