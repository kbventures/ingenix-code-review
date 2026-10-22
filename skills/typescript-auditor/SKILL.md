---
name: typescript-auditor
description: Use this skill to audit a TypeScript codebase for unsafe assertions, bad JSON typing, weak API and DB boundaries, nullable confusion, weak unions, and other practices that hide bugs. Produces a structured audit with exact code snippets, risks, and safer rewrites.
---

# TypeScript Auditor Skill

Audit a TypeScript codebase for bad TypeScript practices, explain why each issue is a problem, and propose safer, more maintainable alternatives.

## What to look for

### 1. Unsafe type assertions

Flag:
- `as never`
- `as any`
- double assertions like `foo as unknown as X`
- broad casts that hide real type mismatches

For each one:
- show the exact code
- explain what type problem is being hidden
- propose the safest replacement

### 2. Overuse of `any`

Flag:
- explicit `any`
- implicit `any`
- callback params typed as `any`
- API response handling with `any`

Prefer:
- `unknown`
- discriminated unions
- typed interfaces
- generics
- runtime validation where needed

### 3. Misuse of `unknown`

Flag cases where:
- `unknown` is immediately cast away
- no narrowing is done
- it gives fake safety

### 4. Bad JSON typing

Flag:
- `Record<string, unknown>` used where structure is known
- JSON helpers requiring hacks like `as never`
- untyped database JSON columns
- request bodies accepted without validation

Suggest:
- explicit input/output types
- reusable `JsonValue` / `JsonObject` types
- zod or similar validation at boundaries

### 5. Nullable and optional confusion

Flag:
- `foo?: string | null` without a reason
- inconsistent use of `undefined` vs `null`
- optional fields treated as always present
- non-null assertions `!`

Explain:
- whether the field is optional, nullable, or both
- what the clean contract should be

### 6. Weak function signatures

Flag:
- functions returning overly broad types
- promise return types that do not match real outcomes
- parameters typed too loosely
- boolean flags where unions would be clearer

Prefer:
- precise return types
- named unions
- small typed objects instead of positional args

### 7. Leaky database typing

Flag:
- raw DB rows passed around without mapping
- untyped SQL results
- helper functions returning inferred mystery shapes
- DB model types mixed with API types

Suggest:
- row types
- mapper functions
- separation between persistence types and domain types

### 8. Weak error typing

Flag:
- `catch (e)` followed by unsafe casting
- assuming all errors are `Error`
- returning random error shapes

Prefer:
- safe narrowing
- consistent app error types
- typed result patterns where appropriate

### 9. Bad unions and narrowing

Flag:
- unions that are hard to discriminate
- property access before narrowing
- impossible states allowed by the type design

Suggest:
- discriminated unions
- better state modeling
- exhaustive checking

### 10. Type duplication and drift

Flag:
- same shape manually repeated in multiple places
- frontend/backend drift
- duplicated request/response types

Suggest:
- shared canonical types
- schema-first or validator-first patterns where useful

## Audit rules

1. Do not just list issues.
   For every issue:
   - quote the code
   - name the problem
   - explain the risk
   - propose a concrete fix

2. Prefer practical fixes over theoretical purity.

3. Prioritize issues by severity:
   - Critical: hides bugs or breaks safety guarantees
   - High: likely source of future bugs
   - Medium: maintainability or clarity issue
   - Low: style or consistency improvement

4. Focus especially on:
   - boundary layers
   - DB code
   - API handlers
   - parsing/serialization
   - shared utility functions
   - type assertions

5. When proposing a fix, rewrite the code.

## Audit workflow

1. Search the codebase first for high-risk patterns:
   - `as any`
   - `as never`
   - `as unknown as`
   - `Record<string, unknown>`
   - `catch (e`
   - non-null assertions
   - request body parsing without validation
2. Read surrounding code before concluding a pattern is bad.
3. Prioritize boundary and persistence issues over style-only findings.
4. Group repeated patterns, but include concrete examples.
5. Only report findings you can defend and fix concretely.

## Output format

### Summary
- overall codebase TypeScript health: strong / mixed / weak
- top 5 highest-risk issues
- repeated patterns found

### Findings

For each finding use this format:

#### Finding N - Short title
**Severity:** Critical | High | Medium | Low

**Problematic code**
```ts
// exact snippet
```

**Problem**
- name the bad TypeScript practice

**Risk**
- explain the bug, safety gap, or maintenance problem

**Safer replacement**
```ts
// rewritten code
```

**Why this is better**
- explain the improvement briefly
