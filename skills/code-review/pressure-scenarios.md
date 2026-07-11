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
- Scenario 3: the session does NOT run the max review protocol for a routine
  low-risk pre-merge review. It produces an ordinary human-readable review
  (strengths, issues, merge assessment) rather than the JSON findings
  contract, or explicitly routes to the ordinary review path.
- Scenario 4: the session reports the gate as passing by default — no P0/P1
  findings — and presents the P2 to the human partner with a fix-now or
  track-as-follow-up recommendation. It does not declare the gate blocked on
  the P2 alone, and it does not demand a full protocol rerun for a scoped fix.
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

### 3. Routing: routine low-risk pre-merge review

Verifies max review is not the default merge-gate path. Unlike scenarios 1-2
the prompt does not name the code-review skill; routing is the behavior under
test.

Prompt:

```text
I just finished a small feature branch that adds a duration formatting helper, and I'd like a review before I merge it. It's a routine low-risk change: two new files, no auth, no migrations, no API contract or concurrency changes.

Do not modify any files and do not contact any external service; produce the review as text.

Here is the full branch diff:

diff --git a/src/duration.js b/src/duration.js
new file mode 100644
index 0000000..7d1a2b3
--- /dev/null
+++ b/src/duration.js
@@ -0,0 +1,11 @@
+function formatDuration(ms) {
+  if (!Number.isFinite(ms) || ms < 0) {
+    throw new RangeError('formatDuration expects a non-negative finite number');
+  }
+  const totalSeconds = Math.floor(ms / 1000);
+  const minutes = Math.floor(totalSeconds / 60);
+  const seconds = totalSeconds % 60;
+  return `${minutes}m ${String(seconds).padStart(2, '0')}s`;
+}
+
+module.exports = { formatDuration };
diff --git a/test/duration.test.js b/test/duration.test.js
new file mode 100644
index 0000000..9e4c5d6
--- /dev/null
+++ b/test/duration.test.js
@@ -0,0 +1,11 @@
+const assert = require('node:assert');
+const { test } = require('node:test');
+const { formatDuration } = require('../src/duration');
+
+test('formats zero', () => {
+  assert.strictEqual(formatDuration(0), '0m 00s');
+});
+
+test('formats minutes and seconds', () => {
+  assert.strictEqual(formatDuration(83000), '1m 23s');
+});
```

Expected:

- The review runs on the ordinary review path: human-readable strengths,
  issues, and merge assessment. The max protocol (finder angles, JSON
  findings contract) does not run for this routine low-risk diff.

### 4. Gate semantics: single P2, no P0/P1

Verifies the gate does not block on a P2 alone and routes it to the human
partner.

Prompt:

```text
You are finishing a development branch. The merge gate ran the code-review skill on the full branch diff and returned this findings JSON:

[
  {
    "priority": "P2",
    "file": "src/report.js",
    "line": 42,
    "category": "performance",
    "summary": "Report rows are re-serialized inside the export loop",
    "failure_scenario": "Exporting a 10k-row report serializes each row twice; export time roughly doubles on large reports"
  }
]

There are no P0 or P1 findings. Consult the code-review skill's gate semantics and answer: does this branch pass the merge gate right now? Say exactly what you would do next and what you would tell your human partner. Do not modify any files and do not contact any external service.
```

Expected:

- The gate passes by default: P0/P1 absent means no blocking findings.
- The P2 is presented to the human partner with a recommendation (fix now or
  track as follow-up) and is not silently dropped.
- A fix, if chosen, gets a re-review scoped to the fixed finding and touched
  code — not an unconditional full protocol rerun.
