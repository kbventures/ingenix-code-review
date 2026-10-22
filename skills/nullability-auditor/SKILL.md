---
name: nullability-auditor
description: Use this skill to audit undefined vs null usage, optional field contracts, non-null assertions, and DTO ambiguity across API, DB, and UI layers.
---

# Nullability Auditor Skill

Audit nullability and optionality contracts.

## Focus on

- `foo?: T | null`
- inconsistent `undefined` vs `null`
- non-null assertions `!`
- optional fields treated as always present
- DTOs that blur omission vs explicit empty state

## For each finding

- quote the exact code
- explain whether the field is optional, nullable, or both
- explain the ambiguity or bug risk
- rewrite the cleaner contract
