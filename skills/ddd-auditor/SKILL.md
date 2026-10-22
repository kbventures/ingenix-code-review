---
name: ddd-auditor
description: Audit a codebase or schema for Domain-Driven Design alignment. Checks bounded contexts, aggregate roots, ubiquitous language, domain events, and whether business logic is leaking into the wrong layer.
argument-hint: [path/to/schema.dbml or src/ directory]
allowed-tools: Read, Grep, Glob, Bash
model: opus
---

# Domain-Driven Design Auditor

Audit a schema or codebase for DDD alignment. Surface boundary violations, misplaced logic, missing domain events, and language inconsistencies.

## Usage

```
/code-review-kit:ddd-auditor
/code-review-kit:ddd-auditor schema.dbml
/code-review-kit:ddd-auditor src/
/code-review-kit:ddd-auditor tasks/schema-v2.dbml
```

If no argument is given, look for `schema.dbml`, `schema.sql`, or `src/` in the working directory.

---

## What to Read First

Before producing any output:
1. Read the full schema or relevant source files
2. Identify all entities, value objects, and relationships
3. Form a mental model of what the domain actually does before judging the design

---

## Audit Dimensions

Run all 6 dimensions. For each finding state the location (table, file, function), the DDD violation, and the fix.

### 1. Bounded Contexts

A bounded context is a boundary within which a domain model is consistent and self-contained. Each context owns its data and doesn't share tables with other contexts.

Check for:
- Tables that serve two different business domains (e.g. `contacts` used by both lead capture and campaign engine)
- Cross-context foreign keys (a FK from one context's table into another context's table — should be replaced with an ID reference + event)
- Missing context boundaries — everything in one flat namespace when distinct subdomains exist
- Shared mutable state between contexts (two contexts writing to the same table)

For each bounded context you identify, name it and list which tables/entities belong to it.

### 2. Aggregate Roots

An aggregate is a cluster of objects treated as a single unit for data changes. The aggregate root is the only entry point — nothing outside should hold a direct reference to a non-root entity within the aggregate.

Check for:
- Tables that should be children of an aggregate root but have direct FKs from outside the aggregate (e.g. `campaign_steps` referenced directly by `email_sends` instead of going through `campaigns`)
- Aggregates that are too large (pulling in unrelated entities — a sign the boundary is wrong)
- Aggregates that are too small (every table is its own aggregate — no cluster, no invariants enforced)
- Missing invariant enforcement: what rules must always be true within this aggregate? Are they enforced?

### 3. Ubiquitous Language

The schema and code should use the same language as the business domain. Naming should reflect what the business calls things, not technical implementation details.

Check for:
- Table or column names that are technical rather than domain-meaningful (`state`, `data`, `flag`, `type` without domain context)
- Inconsistent naming for the same concept across tables (e.g. `lead` in one place, `contact` in another, `prospect` in a third)
- Names that require a developer to explain what they mean to a domain expert
- Abbreviations that obscure domain meaning (`lm_sub` instead of `lead_magnet_submission`)
- Verb/noun confusion — tables should be nouns (entities), not verbs or processes

### 4. Domain Events

Domain events capture the fact that something meaningful happened in the domain. They are the handoff mechanism between bounded contexts.

Check for:
- Missing event capture: are significant state changes recorded anywhere? (e.g. `ContactEnrolled`, `SubmissionReceived`, `EmailBounced`, `SequenceCompleted`)
- Events that should trigger cross-context reactions but have no mechanism to do so (polling, direct FK, or nothing)
- `email_events` / webhook tables — are these domain events or infrastructure events? Are they being used to drive domain logic?
- Status columns used as implicit event log (e.g. `status = 'enrolled'` instead of an enrollment event row)

### 5. Domain Logic Placement

Domain logic should live in the domain layer, not in the database schema (triggers, computed columns) or in API route handlers.

When auditing a schema only, flag:
- Business rules that cannot be expressed in the schema and must live somewhere — are they likely to end up in route handlers?
- Computed/derived columns that encode business logic in the DB
- Status transition rules with no enforcement mechanism at any layer

When auditing source code, flag:
- Business logic in API route handlers (`/api/...` files doing more than coordinate)
- Domain rules in repository/query files
- Missing domain service or use-case layer
- Framework singletons (ORM instances, request context) imported directly into domain logic

### 6. Entity vs Value Object

Entities have identity (an ID that persists over time). Value objects are defined by their attributes alone and have no identity.

Check for:
- Value objects modelled as entities with unnecessary surrogate PKs (e.g. a `Money` or `Address` table when the values should just be columns)
- Entities missing stable identity (using email, name, or slug as PK — these can change)
- Mutable value objects (if it has an `updated_at`, it's probably an entity, not a value object)

---

## Checklist (apply to every aggregate)

> Does this aggregate have one root? Is the root the only entry point from outside? Are all invariants enforced at the root? Can this aggregate be extracted into its own bounded context without major surgery?

---

## Output Format

Start with a **Bounded Context Map** — list each context you identified and its tables. Then group findings by dimension, ordered by severity.

```
## Bounded Context Map
- **[Context Name]**: table_a, table_b, table_c
- **[Context Name]**: table_d, table_e

## [Dimension Name]

### [SEVERITY] — location
**Violation:** What DDD principle is broken.
**Risk:** What goes wrong as the system grows.
**Fix:** Concrete recommended change.
```

Severity definitions:
- **Critical** — context boundary violated, data integrity or correctness at risk
- **High** — aggregate invariant unenforced, domain logic misplaced, silent coupling
- **Medium** — language inconsistency, missing event, design will cause pain at scale
- **Low** — naming or style issue, fix when convenient

End with a **Summary**:
- Bounded contexts identified
- Total findings by severity
- Top 3 highest-priority fixes

---

## Behavior Notes

- Do not invent domain knowledge. If the domain is unclear, state your assumption explicitly before flagging a finding.
- A finding is only valid if it describes a real risk, not a theoretical purity violation.
- Pragmatism over purity: flag violations that will cause real pain, not violations of DDD orthodoxy that have no practical consequence at this scale.
- Cross-context FK is a smell but not always wrong at early stage — flag it with context.
- If a `jsonb` column stores structured data that crosses context boundaries, flag it.
