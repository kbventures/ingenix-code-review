---
name: db-schema-auditor
description: Audit a relational database schema for structural risks, missing constraints, normalization issues, and business-rule gaps. Accepts a .dbml file path, raw SQL, or asks the user to point at the schema.
argument-hint: [path/to/schema.dbml or schema source]
allowed-tools: Read, Grep, Glob, Bash
model: opus
---

# Relational Database Schema Auditor

Audit a database schema and surface every structural risk worth fixing.

## Usage

```
/code-review-kit:db-schema-auditor
/code-review-kit:db-schema-auditor schema.dbml
/code-review-kit:db-schema-auditor path/to/schema.sql
```

If no argument is given, locate the schema file automatically (look for `schema.dbml`, `schema.sql`, or `migrations/` in the working directory).

---

## Audit Dimensions

Run all 7 dimensions. For each finding, state the table/column, the risk, and the recommended fix.

### 1. Tables
- Unclear purpose — can you describe the table in one sentence?
- Mixed responsibilities — does it store more than one kind of thing?
- Missing entity boundaries — are two distinct entities collapsed into one table?
- Naming conventions (Hernandez): table names should be singular (`contact` not `contacts`), consistent abbreviations used throughout, no ambiguous or generic names. Flag any table that violates these.

### 2. Columns
- Vague names (`data`, `info`, `value`, `misc`, `extra`)
- Wrong data types (e.g. storing money as float, storing IDs as int when uuid is used elsewhere)
- Nullable fields that should be NOT NULL (required by business logic but not enforced)
- Duplicated or derived data (columns that can be computed from other columns or tables)
- Missing field specification: for every column, can you state its purpose, allowed values, and the business rule it enforces? Flag any column where this is ambiguous from the name and type alone.

### 3. Keys
- Missing primary keys
- Weak natural keys (names, emails, slugs used as PKs)
- Unstable identifiers (PKs that can change)
- Missing unique constraints on columns that are functionally unique

### 4. Relationships
- Missing foreign keys (columns named `*_id` with no FK defined)
- Wrong cardinality (one-to-many modelled as one-to-one, etc.)
- Many-to-many relationships without a junction table
- Orphan-record risk (no FK + no ON DELETE rule = dangling rows)

### 5. Normalization
- Repeating groups (arrays or JSON storing structured repeated data that should be rows)
- Duplicated facts (same fact stored in two places)
- Transitive dependencies (column A → column B → column C, B and C should be their own table)
- Update/delete/insert anomalies (changing one fact requires touching many rows)

### 6. Business Rules
- Rules enforced only in application code, not by DB constraints
- Status/type columns that are free-text strings but should be enums or reference tables
- Invalid state transitions not guarded by constraints or triggers
- Missing CHECK constraints on bounded values (percentages, counts, amounts)

### 7. Query / Use-Case Fit
- Schema cannot support common reads/writes without full-table scans
- Over-normalized: simple reads require many joins
- Under-normalized: updates require touching many rows
- Missing indexes for obvious high-frequency access paths (FK columns, status+date filters, etc.)

---

## Checklist (apply to every table)

> Can every table explain **one thing**, every row represent **one instance** of that thing, every column describe **only** that thing, and every relationship enforce the **real business rule**?

---

## Output Format

Group findings by dimension. Within each dimension, order by severity: **Critical → High → Medium → Low**.

```
## [Dimension Name]

### [SEVERITY] — table_name.column_name (or table_name)
**Risk:** What can go wrong.
**Fix:** Concrete recommended change.
```

Severity definitions:
- **Critical** — data loss, corruption, or integrity violation possible
- **High** — business rule unenforced, silent bugs likely
- **Medium** — design smell, will cause pain at scale
- **Low** — naming or style issue, fix when convenient

End with a **Summary** section:
- Total finding count by severity
- Top 3 highest-priority fixes

---

## Schema Header (always run last)

After the audit, generate or update the bounded-context header comment at the top of the schema file.

The header must contain two sections:

**1. Bounded Contexts** — list every context and the tables it owns:
```
// Bounded Contexts:
//   - Identity & Tenancy: tenants
//   - Contact Management: contacts, import_jobs
//   - ...
```

**2. Key Decisions** — one line per non-obvious, hard-to-reverse design decision. Only include decisions a future reader would wonder about. Skip obvious things:
```
// Key decisions:
//   - Multi-tenant, all data isolated by tenant_id
//   - auth_user_id is external auth provider ID — no local users table
//   - ...
```

If the schema file already has a header:
- Update the bounded contexts list to match the current tables
- Add any new key decisions surfaced by this audit
- Remove any decisions that are no longer accurate
- Do not touch decisions already documented unless they are wrong

If no header exists, create one from scratch.

Write the updated header directly to the schema file.

---

## Behavior Notes

- Read the full schema before producing any output.
- If the schema references migrations, read the latest ones to check for recent structural changes.
- Do not flag findings that are already enforced (e.g. do not flag a missing FK if the FK is defined further down in the file).
- Prefer concrete examples over abstract descriptions in every finding.
- If a JSONB column stores structured data that is always queried by key, flag it as a normalization candidate.
- `schema_migrations` and other migration-tracking tables: skip, they are infrastructure.
