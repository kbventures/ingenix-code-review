---
name: db-mapper-auditor
description: Use this skill to audit query modules for blind row casting, SELECT *, weak row mappers, JSON column decoding problems, and mixing persistence types with domain types.
---

# DB Mapper Auditor Skill

Audit the DB/query layer for row-mapping and persistence typing issues.

## Focus on

- `as unknown as` on query results
- raw rows passed around as domain types
- `SELECT *`
- joined mystery shapes
- JSON columns decoded as generic bags
- DB/domain type mixing

## For each finding

- quote the exact code
- explain what row shape is being trusted blindly
- explain the drift risk
- rewrite with row types and mappers
