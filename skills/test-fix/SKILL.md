---
name: test-fix
description: Add missing tests and fix broken tests based on review findings. Run after code review and arch review are complete.
---

# Test Fix

Dispatch a subagent to add missing tests and fix broken tests based on review findings.

## When to Use

- After `code-review-kit:pr-review` completes (called automatically as final step)
- After a manual `code-review-kit:bug-review` or `code-review-kit:arch-review` when test gaps were flagged
- Standalone when you know tests are missing or broken

## Input

Reads the most recent review report from `code-review/{DATE}/` to identify:

- **Missing tests** flagged by code review
- **Uncovered edge cases** identified in either review
- **Regression risks** from arch review (boundary violations, validation gaps)
- **Broken tests** that need fixing

If no review report exists, analyze the current diff to determine what needs test coverage.

## How It Works

Dispatch a subagent using the Agent tool with this prompt:

```
You are a Senior Test Engineer. Your job is to add missing tests and fix broken tests based on review findings.

## Review Findings

{PASTE_RELEVANT_FINDINGS}

## Git Range

Base: {BASE_SHA}
Head: {HEAD_SHA}

## Rules

- Tests verify real behavior, not mocks (unless external services require it)
- One test per concern — don't bundle unrelated assertions
- Match existing test patterns and conventions in the codebase
- Integration tests for boundary violations and validation gaps
- Unit tests for logic bugs and edge cases
- Name tests after the behavior they verify, not the function they call

## Process

1. Read the review findings
2. Read existing tests to understand patterns and conventions
3. For each test gap:
   - Determine test type (unit / integration)
   - Write the test
   - Verify it passes
4. For each broken test:
   - Determine root cause
   - Fix the test (or the code if the test is correct)
5. Run the full test suite
6. Report what was added/fixed and suite status

## Output Format

### Tests Added
- [file:test name] — covers [what behavior / finding]

### Tests Fixed
- [file:test name] — [what was wrong, what changed]

### Suite Status
[pass/fail, number of tests, any remaining failures]
```

## After Running

- Run full test suite to confirm no regressions
- If suite fails, fix before reporting
- Skip entirely if reviews found no test gaps and all tests pass
