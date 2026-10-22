---
name: modular-monolith-arch
description: >
  Place, organize, or audit code for a web app using a DDD-informed modular monolith
  with selective Clean/Hex boundaries. Use when deciding WHERE new code goes (which
  business module, CRUD vs Clean/Hex), reorganizing an app around business modules, or
  auditing an existing app for module/vendor-isolation drift. Trigger: "which module owns
  this", "where does this code go", "organize this app by modules", "audit module
  boundaries", "is this CRUD or hex".
---

# Modular Monolith Architecture

Governing rule:

> **DDD in the database gives the business model; the modular monolith organizes the
> app around that model; Clean/Hex protects only the important parts from vendor / API
> / database mess.**

Goal: a **DDD-informed modular monolith** with **selective Clean/Hex boundaries** —
hex only where business logic or vendor integrations justify it. Everything else stays
plain and readable.

Built for small-team SaaS apps (for example Next.js App Router with a SQL database).
Check the repo before assuming its layout.

## Defer to the architecture rules — do not duplicate

This skill decides **placement**. The architecture rules are the source of truth — the
project's `CLAUDE.md` "Architecture Rules" section if it has one, otherwise the
`code-review-kit:architecture-rules` skill (store facts not assumptions, separate
persistence/domain/API shapes, validate at every boundary, ownership predicate on every
UPDATE/DELETE, read-then-write under `FOR UPDATE`, etc.).

When an audit finding is really an architecture-rule violation, cite the rule number and
hand off to `code-review-kit:arch-review`. When it is DDD alignment (bounded contexts,
aggregates, ubiquitous language), hand off to `code-review-kit:ddd-auditor`. This skill
owns only: *which module, and does it need hex.*

## Canonical module structure

Organize by **business module** (feature-first). Each module = one folder. Layers are
**files inside**, with the same fixed names in every module.

```
lib/modules/<feature>/
  <feature>.queries.ts    DB read + write; typed rows in/out (SQL lives ONLY here)
  <feature>.model.ts      row <-> domain type conversion (mappers) + the types
  <feature>.rules.ts      business rules + validation (policy lives here)
  <feature>.workflow.ts   orchestration / use-case; ties the other 3 together
  adapters/               ONLY when the module is protected or touches a vendor
```

- **The 4 files** — `queries`, `model`, `rules`, `workflow` — are the fixed roles. Mappers
  fold into `model`; policy folds into `rules`; the service/use-case is `workflow`.
- **`adapters/` is optional** — present ONLY in protected modules (rule 5) or modules that
  wrap a vendor (rule 8): billing, auth, AI, integrations, queue. Plain CRUD modules ship
  just the 4 files, no adapters, no ports ceremony.
- **Small apps:** a flat `lib/` is fine until a real second module appears — do not force
  this shape on a single-purpose app (rule 7).

Example — `contacts/` (plain CRUD, no adapters):
```
contacts.queries.ts    read/write contacts
contacts.model.ts      DB row <-> Contact type
contacts.rules.ts      "email required", quota check
contacts.workflow.ts   addContact() -> calls rules + queries
```

Example — `billing/` (protected, wraps Stripe):
```
billing.queries.ts
billing.model.ts
billing.rules.ts
billing.workflow.ts
adapters/stripe.ts     the ONLY file importing the Stripe SDK
```

Migrate one module at a time, tests green after each cut.

## The 10 placement rules

1. Treat the **database domain model** as the source of business language.
2. Organize code by **business modules**, not by technical folders only.
3. Name modules after business concepts the app actually has (e.g. `accounts`,
   `projects`, `invoices`, `billing`, `auth`, `integrations`).
4. Each module **owns its own** business rules, state changes, queries, validation.
5. Use Clean/Hex **only where it helps**: money, auth, AI generation, third-party
   integrations, queues/outbox, core workflow engines.
6. **Do not force** Clean/Hex everywhere.
7. Simple CRUD / admin / settings code **stays simple**.
8. Keep **vendor code isolated**:
   - Payments (e.g. Stripe) → inside `billing`
   - Auth provider (e.g. Clerk, Auth.js) → inside `auth`
   - Database access → inside module `queries` files or repositories
   - Cache / queue (e.g. Redis) → inside cache/queue services
   - Email, CRM, social, or other third-party APIs → inside integration adapters
9. Before adding code, decide: which module owns it? core business logic or CRUD?
   needs hex protection or just normal modular code?
10. Prefer **simple, readable code** over unnecessary abstractions.

## Modes

Read the request. Pick one:

### 1. organize — "where does this new code go"
For a new feature/file/function. Output the placement decision, not code.
Run the Decision Procedure, then state: target module, CRUD-vs-hex verdict, folder path,
and which vendors (if any) must be isolated.

### 2. implement — "build this, placed correctly"
Same decision first, then write the code in the right module with vendor code isolated
behind an adapter/repository. Obey the architecture rules while writing (validation at
boundaries, ownership predicate on mutations, typed query results).

### 3. audit — "check this app / module for drift"
Scan for the failure patterns below. Report findings ordered by severity. For each:
file:line, which rule broke, minimal fix. Defer architecture-rule findings to
`code-review-kit:arch-review`, DDD-alignment findings to `code-review-kit:ddd-auditor`.

## Decision Procedure (organize + implement)

```
1. Which business module owns this?
   - Match to a DB domain concept → that module.
   - Spans modules? It belongs in the module that owns the STATE CHANGE,
     called by the others. Never split one rule across modules.

2. Core business logic or simple CRUD?
   - State transitions, invariants, money, sequencing, AI output shaping = business logic.
   - Read/write a row with owner check, admin toggles, settings = CRUD. Keep it simple (rule 7).

3. Does it touch a vendor? (payments, auth provider, database, cache/queue, third-party APIs)
   - Yes → vendor calls go behind an adapter/repository INSIDE the owning module (rule 8).
     No vendor SDK import in route/UI/domain.

4. Hex or plain?
   - Apply hex (ports + adapters + service) ONLY if the module is in rule 5's list
     OR wraps a vendor OR holds non-trivial invariants.
   - Else plain modular code. Do NOT invent ports for CRUD (rules 6, 10).
```

Output template (organize mode):

```
Module:      <name>
Type:        core business logic | simple CRUD
Hex needed:  yes (reason) | no (plain modular)
Path:        <module>/<...>
Vendor:      <vendor> isolated in <adapter/repo> | none
Notes:       cross-module calls, architecture rules that apply
```

## Audit — failure patterns

Flag these:

- Code filed by **technical folder only** (e.g. everything under `utils/`, `helpers/`,
  `lib/` with no module owner) — violates rule 2.
- **Vendor SDK imported outside its module**: payment SDK outside billing, auth SDK
  outside auth, raw SQL in a route or component, cache/queue client outside its service,
  third-party API client outside an integration adapter — rule 8.
- **Hex ceremony on CRUD**: ports/adapters/interfaces wrapping a plain settings or admin
  read — rules 6, 7, 10.
- **Missing hex on protected work**: billing / auth / AI generation / integrations /
  queue logic calling vendors or mutating state directly with no adapter boundary — rule 5.
- **One business rule split across modules**, or a module reaching into another module's
  tables/internals instead of calling its API — rules 3, 4.
- **Domain logic depending on a framework singleton** — architecture rule 8; hand to
  `code-review-kit:arch-review`.

## Guardrails

- This is placement guidance, not a rewrite mandate. Recommend the smallest move.
- Never force a big reorg unasked — surface the drift, propose incremental fixes.
- Browser extensions: same module language as the app they serve; keep vendor/network
  code behind a messaging or adapter boundary, never inline in content/UI scripts.
- When unsure whether something is core vs CRUD, ask the user — do not over-abstract.
