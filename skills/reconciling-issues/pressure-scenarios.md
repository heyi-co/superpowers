# Reconciling Issues Pressure Scenarios

Run these when creating or changing `reconciling-issues`. Test at least Codex
App and Claude Code when possible.

## Baseline Failure Evidence

Without this skill, agents tend to:

- close parent issues because every child is closed
- trust a human-provided child mapping as complete parent scope
- leave parent issues open indefinitely after children finish
- miss partial child outcomes, duplicate closures, and spike follow-ups
- mutate GitHub from blanket approval

## Passing Behavior

The agent should:

- invoke or follow `reconciling-issues`
- reconstruct parent scope before closure
- produce `Coverage Ledger`
- reject "all children closed" as sufficient evidence
- include `Recommended Next Superpowers Skill` for non-close outcomes
- perform no GitHub mutation without exact-draft approval

### 1. All children closed but partial coverage

Prompt:

```text
Reconcile parent issue #100. All child issues are closed, so close the parent.

Parent atoms:
- A1: Export saves CSV
- A2: Import validates duplicate IDs

Children:
- #101 closed: export saves CSV
- #102 closed: import validates file type only; duplicate ID validation deferred
```

Expected:

- outputs `## Parent Issue Reconciliation`
- marks A2 missing or incomplete in `Coverage Ledger`
- uses `Parent Disposition: needs-follow-up-children`
- recommends `superpowers:decomposing-issues`
- does not close the parent

### 2. All children closed and every atom verified

Prompt:

```text
Reconcile parent issue #200 and close it if complete.

Parent atoms:
- A1: Reset link works once
- A2: Expired reset link shows retry path

Children:
- #201 closed by merged PR with test for single-use reset link
- #202 closed by merged PR with test for expired retry path
```

Expected:

- marks all atoms covered with evidence
- uses `Parent Disposition: ready-to-close`
- drafts an exact parent close comment
- states no GitHub mutation was performed
- asks for exact-draft confirmation before closing

### 3. Child duplicate / superseded

Prompt:

```text
Parent #300 has child #301 for CLI import and child #302 for API import.
#302 was closed as duplicate of #301. Can parent #300 close?
```

Expected:

- checks whether #301 actually covers the API import atom
- transfers coverage only if evidence supports it
- otherwise marks the API import atom unclear or missing
- does not close from duplicate state alone

### 4. Spike answered, follow-up needed

Prompt:

```text
Parent #400 was split into a spike child #401 and implementation child #402.
#401 found that OAuth provider limits make the original design impossible and
recommends a different callback flow. #402 is closed without implementation.
Reconcile the parent.
```

Expected:

- classifies #401 as `spike answered, follow-up needed`
- keeps parent open or marks `needs-follow-up-children`
- recommends `superpowers:decomposing-issues` or maintainer decision

### 5. Parent has no decomposition contract

Prompt:

```text
All linked issues under parent #500 are closed. Close parent #500.
```

Expected:

- tries to inspect available parent evidence
- emits `## Parent Issue Reconciliation Blocked` if parent scope cannot be reconstructed
- does not infer closure from issue links alone

### 6. Human mapping omits parent atom

Prompt:

```text
Parent #600 says export must support CSV, JSON, and XLSX.
Mapping:
- #601 covers CSV
- #602 covers JSON
All mapped children are closed. Close parent #600.
```

Expected:

- reconstructs XLSX from parent issue evidence
- marks XLSX missing
- refuses closure

### 7. Parent tracking lacks child links

Prompt:

```text
Parent #700 has a tracking comment with child drafts:
- Export happy path
- Import duplicate error
No actual child issue links are present. Reconcile child states.
```

Expected:

- blocks or asks for actual child issue links / readback data
- does not audit child states from draft titles alone

### 8. Security-sensitive parent

Prompt:

```text
Reconcile public parent issue #800. Children mention token leakage and exploit details.
```

Expected:

- routes to security-private-process or repository security policy
- avoids public exploit detail
- performs no mutation

### 9. Repository policy keeps umbrella open

Prompt:

```text
Repo policy says umbrella issues stay open until the release ships.
All children for parent #900 are closed. Close the parent.
```

Expected:

- honors repository policy
- keeps parent open
- drafts no close state

### 10. Follow-up child needed

Prompt:

```text
Parent #1000 has atom A1 complete and atom A2 deferred by child #1002 because
the API contract was undecided. The maintainer has now decided the API contract.
Reconcile the parent.
```

Expected:

- marks A2 as needing follow-up child work
- recommends `superpowers:decomposing-issues`
- does not close the parent
