---
name: architecture-rules
description: The 13 architecture rules the review skills check against. Load this when a review needs the rule list and the project's own CLAUDE.md has no "Architecture Rules" section.
---

# Architecture Rules

The review skills in this kit (`arch-review`, `full-review-weekly`, `modular-monolith-arch`) check code against these rules.

**Project rules win.** If the project's `CLAUDE.md` has an "Architecture Rules" section, use that list instead of this one. To adopt these rules in a project, copy the list below into its `CLAUDE.md`.

## The 13 Rules

1. **Store facts, not assumptions.** Persist observed data. Don't store derived or speculative state that can go stale.
2. **Prefer fewer states and simpler workflows.** Fewer states = fewer bugs. Collapse redundant states. Simplify transitions.
3. **Delete special cases when the general model covers them.** If the general path handles it, remove the special-case branch.
4. **Keep persistence, domain, and API shapes separate.** DB rows, domain models, and API DTOs must not be the same type. Map between them explicitly.
5. **Validate at every boundary.** Validate inputs at system edges (user input, external APIs, DB results). Don't trust data crossing a boundary.
6. **Type query results explicitly.** Give query results explicit row types, mappers, and JSON validation. No hidden casts or `any`.
7. **Routes only coordinate.** Routes/handlers accept input, call services, return responses. No business logic, no DB access, no side effects beyond coordination.
8. **Domain logic must not depend on framework singletons.** Services and domain code must not import framework-specific globals (`process.env`, SDK singletons). Inject dependencies.
9. **Use one path per feature.** One code path per feature. No parallel implementations, no feature flags that create permanent forks.
10. **Make risky behavior explicit and bounded.** Auth, tenancy, rate limits, retries, timeouts, and slow I/O must be explicit, bounded, and fail closed.
11. **Use one validation and error style everywhere.** One validation library, one error shape, one pattern. No mixing Zod + manual checks + ad-hoc try/catch conventions.
12. **Every UPDATE/DELETE carries an ownership predicate.** Every mutation includes the owner key (`user_id`, `tenant_id`, or equivalent) in its `WHERE` clause. Re-validate ownership at the point of write, not only earlier in the request.
13. **Read-then-write runs in a transaction with `FOR UPDATE`.** Any sequence that reads a row, decides, then writes must lock the row inside a transaction. No check-then-act outside a lock.
