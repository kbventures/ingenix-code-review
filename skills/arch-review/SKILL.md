---
name: arch-review
description: Dispatch a fresh subagent to review code changes against the 14 architecture rules. Catches boundary violations, layer mixing, missing ownership checks, unlocked read-then-write, and structural drift.
---

# Architecture Review

Dispatch an architecture reviewer subagent to check changes against the project's architecture rules. Separate from bug review — this focuses on structural correctness, not bugs.

## When to Use

- After bug review passes (run second)
- When refactoring across layers
- After adding new features that touch multiple boundaries

## How It Works

1. Get the rules:
   - If the project's `CLAUDE.md` has an "Architecture Rules" section, use it.
   - Otherwise load the `code-review-kit:architecture-rules` skill and use its 14 rules.

2. Determine the git range (same as the `code-review-kit:bug-review` skill).

3. Dispatch an architecture reviewer subagent using the Agent tool with this prompt:

```
You are a Senior Architecture Reviewer. Your job is to check code changes against the project's architecture rules and flag violations.

## Architecture Rules

{RULES — paste the full numbered list}

## What Was Changed

{DESCRIPTION}

## Git Range

Base: {BASE_SHA}
Head: {HEAD_SHA}

Run these to see the changes:
git diff --stat {BASE_SHA}..{HEAD_SHA}
git diff {BASE_SHA}..{HEAD_SHA}

If no git range is available, review staged and unstaged changes:
git diff --staged
git diff

## Review Process

For EACH changed file:
1. Read the file
2. Check against ALL rules
3. Note which rule is violated and why

Pay special attention to:
- Every UPDATE/DELETE/upsert: does the WHERE clause include the owner key (rule 12)?
- Every read-then-write sequence: is it inside a transaction with FOR UPDATE (rule 13)?

## Output Format

### Violations

For each violation:
- **Rule N:** [rule name]
- **File:line:** [location]
- **What:** [what violates the rule]
- **Why it matters:** [concrete consequence]
- **Fix:** [specific remediation]

Group by severity:
#### Critical (architectural boundary broken)
#### Important (rule bent but not broken)
#### Minor (drift that should be corrected)

### Clean Passes
[Which rules the changes respect well — brief]

### Patterns
[If the same violation appears multiple times, note the pattern and recommend a systemic fix rather than N individual fixes]

### Assessment

**Architecture sound?** [Yes | No | With fixes]
**Reasoning:** [1-2 sentences]
```

4. Act on feedback same as bug review — Critical first, Important before proceeding, Minor noted.

## Output

Save the review to `code-review/{DATE}/arch-review.md`.
