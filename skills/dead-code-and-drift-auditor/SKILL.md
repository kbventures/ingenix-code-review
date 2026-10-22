---
name: dead-code-and-drift-auditor
description: Use this skill to find stale compatibility layers, unused exports, duplicated types, abandoned shims, and old/new code-path drift after refactors.
---

# Dead Code And Drift Auditor Skill

Audit the codebase for stale code and structural drift.

## Focus on

- compatibility layers with no remaining need
- duplicated types and helpers
- unused exports
- temporary shims that stayed
- old and new patterns living side by side

## For each finding

- quote the exact code
- explain why it is stale or drifting
- explain the maintenance risk
- propose the cleanup
