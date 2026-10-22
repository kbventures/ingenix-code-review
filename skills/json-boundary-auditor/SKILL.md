---
name: json-boundary-auditor
description: Use this skill to audit JSON boundaries including request.json(), JSON.parse(), sql.json(...), generic object-bag typing, and missing runtime validation.
---

# JSON Boundary Auditor Skill

Audit JSON as it crosses trust boundaries.

## Focus on

- `request.json()`
- `JSON.parse(...)`
- `sql.json(...)`
- `Record<string, unknown>`
- AI JSON output
- JSON columns with generic typing

## For each finding

- quote the exact code
- explain what boundary is weak
- explain the risk of malformed or hostile data
- rewrite with schema parsing or typed JSON helpers
