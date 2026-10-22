---
name: bug-review
description: Dispatch a fresh subagent to review code changes for bugs, regressions, test gaps, and broken behavior. Adapted from the superpowers requesting-code-review skill (MIT).
---

# Bug Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context — never your session's history.

## When to Use

- After completing a feature or task
- Before merging to main
- When stuck (fresh perspective)
- After fixing a complex bug

## How It Works

1. Determine the git range to review:
   - For branch work: `BASE_SHA=$(git merge-base HEAD main)` and `HEAD_SHA=$(git rev-parse HEAD)`
   - For recent work: `BASE_SHA=$(git rev-parse HEAD~N)` where N = number of commits
   - If no commits yet (only staged/unstaged changes): use `git diff --staged` and `git diff` instead

2. Dispatch a code reviewer subagent using the Agent tool with this prompt:

```
You are a Senior Code Reviewer. Review completed work against requirements and identify issues before they cascade.

## What Was Implemented

{DESCRIPTION}

## Requirements

{PLAN_OR_REQUIREMENTS}

## Git Range

Base: {BASE_SHA}
Head: {HEAD_SHA}

Run these to see the changes:
git diff --stat {BASE_SHA}..{HEAD_SHA}
git diff {BASE_SHA}..{HEAD_SHA}

If no git range is available, review staged and unstaged changes:
git diff --staged
git diff

## What to Check

**Correctness:**
- Does the implementation match requirements?
- Are there bugs, off-by-ones, race conditions?
- Edge cases handled?

**Code quality:**
- Clean separation of concerns?
- Proper error handling?
- Type safety where applicable?
- DRY without premature abstraction?

**Testing:**
- Tests verify real behavior, not mocks?
- Edge cases covered?
- Integration tests where they matter?
- All tests passing?

**Production readiness:**
- Migration strategy if schema changed?
- Backward compatibility considered?
- No obvious security issues?

## Calibration

Categorize issues by actual severity. Not everything is Critical.
Acknowledge what was done well before listing issues.
Flag deviations from requirements specifically.

## Output Format

### Strengths
[What's well done — be specific with file:line references]

### Issues

#### Critical (Must Fix)
[Bugs, security issues, data loss risks, broken functionality]

#### Important (Should Fix)
[Missing features, poor error handling, test gaps]

#### Minor (Nice to Have)
[Code style, optimization opportunities]

For each issue:
- File:line reference
- What's wrong
- Why it matters
- How to fix (if not obvious)

For every **Critical or Important bug**, add a `regression:` line immediately after:
- Suggest the test file (e.g. `tests/unit/foo.test.ts`)
- Propose a test name describing the broken behavior
- State the specific assertion that would catch it
- Example: `regression: tests/unit/foo.test.ts — "calculateTotal treats negative qty as zero" → expect(calculateTotal(-1, 10)).toBe(0)`

### Assessment

**Ready to merge?** [Yes | No | With fixes]
**Reasoning:** [1-2 sentence technical assessment]
```

3. Act on feedback:
   - Fix Critical issues immediately
   - Fix Important issues before proceeding
   - Note Minor issues for later
   - Push back if reviewer is wrong (with reasoning)

## Output

Save the review to `code-review/{DATE}/code-review.md`.
