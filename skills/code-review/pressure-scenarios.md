# Code Review Pressure Scenarios

Application scenarios for a technique skill: they verify the skill applies its
protocol correctly, not rule compliance under pressure. Run them with
`scripts/run-skill-evidence.sh` before and after any change to `SKILL.md` or
`review-protocol.md`, on Codex CLI and Claude Code.

## Baseline Failure Evidence

Run scenario 1 once with the skill absent (RED) as a control. Record what a
bare agent reports without the protocol: typically a prose review, no severity
ranking, no JSON contract, and no guarantee both planted bugs are found.

## Pass Criteria

- Scenario 1: output contains a JSON array of findings; both planted bugs are
  reported (the falsy-zero limit regression and the dropped `await` on the
  audit call) with concrete `failure_scenario` values; no style-only findings;
  at most 15 findings.
- Scenario 2: output is exactly the empty JSON array `[]` (plus surrounding
  prose at most); no invented findings.
- No session modifies files or contacts GitHub.

## Scenarios

### 1. Planted-bug diff

Prompt:

```text
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
```

Expected:

- Finds the falsy-zero regression: `limit || DEFAULT_LIMIT` turns an explicit
  `limit = 0` request into 50 rows, where the old code honored 0.
- Finds the dropped `await` on `db.audit(...)`: the audit write becomes
  fire-and-forget; a rejection is unhandled and the audit row is not
  guaranteed before return.
- Reports both as JSON findings with priority, file, line, category, summary,
  and failure_scenario. Returns no style-only findings.

### 2. Clean diff

Prompt:

```text
Review the following change. Use the code-review skill if it is available.
Do not modify any files and do not contact any external service; produce the
review as text with your findings as a JSON array.

diff --git a/src/greeting.js b/src/greeting.js
index 82ab114..f10c377 100644
--- a/src/greeting.js
+++ b/src/greeting.js
@@ -1,5 +1,5 @@
-function greet(name) {
-  return 'Hello, ' + name + '!';
-}
+function greet(name) {
+  return `Hello, ${name}!`;
+}
 
 module.exports = { greet };
```

Expected:

- Returns the empty JSON array `[]`. No invented findings, no style
  commentary reported as a finding.
