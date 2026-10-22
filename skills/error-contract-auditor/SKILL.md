---
name: error-contract-auditor
description: Use this skill to audit catch blocks, error typing, status mapping, and inconsistent error response shapes across routes and services.
---

# Error Contract Auditor Skill

Audit how the app models and returns errors.

## Focus on

- `catch` blocks
- message-string-based control flow
- inconsistent API error payloads
- weak app error typing
- swallowed or overexposed errors

## For each finding

- quote the exact code
- explain the contract weakness
- explain the behavior risk
- rewrite the safer error path
