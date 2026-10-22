---
name: pr-review
description: PR/branch/diff scoped review. Runs a bug review then an architecture review, then specialist passes, and merges all findings into one report. Use for "pr review", "review my changes", "review this branch", "review this diff".
---

# PR Review

Scoped review of the current diff (PR, branch, or staged changes). Runs two core passes, then specialist passes, then merges all findings into one report.

For full-codebase sweeps, use `code-review-kit:full-review-weekly` — this skill is diff-scoped only.

## Trigger

User asks for "pr review", "review my changes", "review this branch", or invokes `/code-review-kit:pr-review`.

If the user asks for an "entire codebase" / "full code base" review: redirect to `code-review-kit:full-review-weekly`. Default scope when none given: `main...HEAD`.

## Forbidden paths

If the project has a `.claudeignore` file, pass its contents to every subagent:

```
Forbidden paths (do not Read/Glob/Grep — skip results if matched):
{contents of .claudeignore}
```

## Process

### Step 1: Determine scope

```bash
# For branch changes vs main:
BASE_SHA=$(git merge-base HEAD main)
HEAD_SHA=$(git rev-parse HEAD)

# If no commits, use staged/unstaged diff instead
git diff --stat
```

Get a brief summary of what changed for the DESCRIPTION placeholder.

Also list what changed (for conditional passes):
```bash
git diff --name-only $BASE_SHA $HEAD_SHA
```

### Step 1b: Schema audit (conditional)

If migration files or `schema.dbml` changed AND `schema.dbml` exists in the project root: dispatch a subagent running `code-review-kit:db-schema-auditor`. Write findings to `code-review/{DATE}/schema-audit.md`.

### Step 1c: DDD audit (conditional)

Same condition as Step 1b: dispatch a subagent running `code-review-kit:ddd-auditor schema.dbml`. Write findings to `code-review/{DATE}/ddd-audit.md`.

### Step 1d: Dead code and drift audit (conditional)

If the diff deletes or renames files, or touches the shared `lib/` folder: dispatch a subagent running `code-review-kit:dead-code-and-drift-auditor`, scoped to files touched in the diff. Write findings to `code-review/{DATE}/dead-code-audit.md`.

### Step 2: Bug review (bugs, regressions, tests)

Dispatch a subagent following the `code-review-kit:bug-review` skill. Wait for results before proceeding.

### Step 3: Architecture review (rule violations)

Dispatch a subagent following the `code-review-kit:arch-review` skill. Wait for results.

### Step 4: Specialist passes (parallel)

Run all applicable skills in parallel. Wait for all to complete before Step 5.

**Always run:**
- `code-review-kit:error-contract-auditor` — error handling, silent failures, catch blocks
- `code-review-kit:test-gap-auditor` — coverage gaps, behavioral test quality

**Run if `.ts` / `.tsx` files with new types or interfaces changed:**
- `code-review-kit:typescript-auditor` — unsafe assertions, weak types

**Always run last (after the other specialists complete):**
- `/simplify` (built into Claude Code) — clarity, reuse, simplification

### Step 5: Merge into one report

Create `code-review/{DATE}/full-review.md` with this structure:

```markdown
# Full Review — {DATE}

Scope: {what was reviewed}

## Bug Review Findings

{findings from step 2, ordered by severity}

## Architecture Review Findings

{findings from step 3, ordered by severity}

## Specialist Findings

### Error Handling
{findings}

### Test Coverage
{findings}

### Type Design
{findings — omit section if not run}

### Simplification
{findings}

## Schema Audit
{findings — omit section if not run}

## DDD Audit
{findings — omit section if not run}

## Dead Code & Drift
{findings — omit section if not run}

## Combined Assessment

**Ready to merge?** [Yes | No | With fixes]

### Critical
{all critical from all passes}

### Important
{all important from all passes}

### Minor
{all minor from all passes}

## Patterns

{if the same issue appeared across multiple passes or repeatedly, flag it here and recommend a systemic fix — update a rule, a checklist, or a review prompt rather than fixing N instances}
```

### Step 6: Fix test gaps

Run the `code-review-kit:test-fix` skill with the merged findings as input.

Skip if reviews found no test gaps and all tests already pass.

### Step 7: Report to user

Present the combined assessment and critical/important items. Note which tests were added or updated. Don't dump the full report — link to the file.
