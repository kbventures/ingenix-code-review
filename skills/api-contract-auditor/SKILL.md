---
name: api-contract-auditor
description: Use this skill to audit API request and response contracts for schema validation gaps, weak request typing, inconsistent error shapes, and unnecessary public response fields.
---

# API Contract Auditor Skill

Audit route handlers for weak request and response contracts.

## Focus on

- `request.json()` with no schema parse
- partial manual validation
- inconsistent success and error response shapes
- public responses exposing internal IDs or metadata
- broad action routes without discriminated unions
- error behavior tied to string matching

## For each finding

- quote the exact code
- explain the contract weakness
- explain the runtime risk
- rewrite the safer request or response contract

## Output format

### Summary
- API contract health
- top risky routes
- repeated patterns

### Findings

#### Finding N - Short title
**Severity:** Critical | High | Medium | Low

**Problematic code**
```ts
// exact snippet
```

**Problem**
- what contract is weak or missing

**Risk**
- what bug, leak, or integration break this can cause

**Safer replacement**
```ts
// rewritten code
```
