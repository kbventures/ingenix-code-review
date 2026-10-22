---
name: full-review-weekly
description: Weekend full-codebase review. Tool checks, whole-file code + arch pass per slice, verify pass, security / scale / boundary specialists, follow-up on last run, error tally with new-rule advice. Saves every phase to disk and resumes after a crash or token-out. Use when user asks for "weekly review", "weekend review", or "full-review-weekly".
---

# Full Review Weekly

Goal: keep code correct, standard, secure, scalable. Whole files, not diff.

Works on any TypeScript/JavaScript web app. Works for root layout (`app/`, `lib/`) and src layout (`src/app`, `src/lib`). `slices.sh` finds folders itself; first stderr line shows layout. Below, `{APP}` / `{LIB}` = the app and lib folder for this repo.

## Save + resume (read first)

Run can die mid-way (token-out, crash). Nothing found may be lost.

- Run dir: `code-review/weekly-{DATE}/`. DATE = start day, kept on resume.
- `PROGRESS.md` in run dir = checklist. One line per phase and per slice.
- Every subagent writes its own file to run dir **before** it returns.
- Main thread ticks `[ ]` → `[x]` only after `test -s <file>` passes.
- Main thread never holds findings. Only paths + counts.

On start:
1. `ls -d code-review/weekly-* | sort | tail -1`
2. Latest run has `PROGRESS.md` with any `[ ]` → **resume**: same dir, skip `[x]` lines, start at first `[ ]`. Tell user "resuming weekly-{DATE} at {line}".
3. Else → new run.

Line half-done (file missing or empty) → redo that line only.

## Finding format (all passes)

One line per finding:

```
severity | category | file:line | issue | fix
```

- severity: `critical` / `important` / `minor`
- category (fixed list, no new names): `correctness`, `security`, `ownership`, `locking`, `validation`, `error-handling`, `type-safety`, `nullability`, `boundary-leak`, `module-borders`, `query-safety`, `scale`, `migration-safety`, `dead-code`, `test-gap`, `simplification`
- No raw code dumps. Return to main thread: `<file path> | crit n | imp n | minor n`.

## Phase 0 — preflight + tool checks

1. `git status --short`. Dirty → ask user: commit, stash, or go on.
2. New run: `mkdir -p code-review/weekly-{DATE}`.
3. Build slices: `bash {this skill's base directory}/slices.sh > code-review/weekly-{DATE}/slices.tsv`
   - Stderr shows count per slice + `UNCOVERED` files. Uncovered list not empty → add those files to slice file as slice `extra-1` (tab-separated) and note in SUMMARY.
4. Write `PROGRESS.md`:

```
- [ ] tool-checks
- [ ] slice {name} code     (one pair per slice in slices.tsv)
- [ ] slice {name} arch
- [ ] verify
- [ ] security
- [ ] ownership-locking
- [ ] scale
- [ ] schema
- [ ] modules
- [ ] arch-fit
- [ ] boundaries
- [ ] types-tests-dead
- [ ] followup
- [ ] summary
- [ ] tally
```

5. Tool checks. Run each, keep going on fail:
   - `npm run --if-present lint`
   - `npm run --if-present typecheck` — no such script → `npx tsc --noEmit`
   - `npm run --if-present test`
   - `npm run --if-present db:migrations:check`
   - `npm audit --omit=dev`
   - Script missing → write "not set up" for it (counts as `minor | test-gap`).
   - Never run DB wipe / reset / restore or `test:ci`.
6. Write `tool-checks.md`: per command pass/fail, error count, first 20 error lines. Each tool failure = `critical | correctness` (lint → `important`, audit high/critical → `critical | security`). Tick.

## Phase 1 — slices (whole files)

For each slice in `slices.tsv`, in order. Two Agent subagents (general-purpose), one after the other. Do **not** use diff-scoped skills (`pr-review`, `bug-review`, `arch-review`).

Code pass prompt:

```
Full-file review, NOT diff. Slice {name}. Files (read every one):
{paths from slices.tsv for this slice}

Skip paths in .claudeignore.
Look for: bugs, wrong logic, edge cases, broken behavior, unsafe input, missing
auth checks, leaked secrets, unbounded loops/queries, silent catch, weak types.
Cross-file deps: read for context, do not review.

Write findings to code-review/weekly-{DATE}/{name}.code.md, one per line:
severity | category | file:line | issue | fix
Categories (only these): {category list}
Write the file BEFORE you reply. Empty slice → write "none".
Reply only: <path> | crit n | imp n | minor n
```

Arch pass prompt: same files, plus:

```
Rules: the "Architecture Rules" section of the project CLAUDE.md, else load the code-review-kit:architecture-rules skill.
Check every file against ALL 13 rules. Name the rule in the issue: "R12: ...".
Rule 12: every UPDATE/DELETE has a user_id ownership predicate.
Rule 13: read-then-write runs in a transaction with FOR UPDATE.
If docs/system-map/frontend-map.md exists, check UI files against its Pattern section.
Write to code-review/weekly-{DATE}/{name}.arch.md.
```

Subagent error / timeout → write `{name}.code.md` with `ERROR: {reason}`, tick, go on.

## Phase 2 — verify

One subagent. Reads every `critical` and `important` line from all `*.code.md`, `*.arch.md`, `tool-checks.md`. For each: open the code, decide `CONFIRMED` or `FALSE` (one-line reason).

Write `verified.md`: same line format + `| CONFIRMED` or `| FALSE: reason`. Large list → write in chunks of 40, append as it goes, so a crash keeps what is done.

Only `CONFIRMED` lines count in summary and tally. Minor lines count as-is.

## Phase 3 — specialists

Each = one general-purpose subagent. Tell it to load the named skill with the Skill tool, scope = whole codebase, write to the given file in run dir (overrides the skill's own output path), finding format above. Run max 3 at once. Tick each when its file exists.

| Line | Skill / agent | File |
|---|---|---|
| security | `code-review-kit:security-checklist`, then a second subagent acting as security reviewer on `{APP}/api`, auth + security code in `{LIB}`, `proxy.ts` / `middleware.ts` | `security.md` |
| ownership-locking | no skill. grep every UPDATE / DELETE / upsert in `{LIB}` + `{APP}/api` (+ `src/modules`, `src/db` if there); check R12 (user_id predicate) + R13 (FOR UPDATE in tx on read-then-write) | `ownership-locking.md` |
| scale | `sql-audit` if this repo has it, else do the checks inline — slow queries, missing indexes, N+1, unbounded SELECT, missing LIMIT | `scale.md` |
| schema | `code-review-kit:db-schema-auditor schema.dbml` (no `schema.dbml` → write "skipped", tick) | `schema-audit.md` |
| modules | `code-review-kit:modular-monolith-arch` audit — cross-module imports in the modules folder (layout line), vendor code outside adapters. No modules folder → check feature folders for cross-imports | `modules.md` |
| arch-fit | no skill; see "arch-fit" below. Uses `code-review-kit:modular-monolith-arch` ladder, points god files to `code-review-kit:refactor-slicer` | `arch-fit.md` |
| boundaries | `code-review-kit:api-contract-auditor`, `code-review-kit:json-boundary-auditor`, `code-review-kit:nullability-auditor`, `code-review-kit:db-mapper-auditor`, `code-review-kit:error-contract-auditor` — one subagent each, one section each | `boundaries.md` |
| types-tests-dead | `code-review-kit:typescript-auditor`, `code-review-kit:test-gap-auditor` (tests in `tests/` or `*.test.ts`), `code-review-kit:dead-code-and-drift-auditor` — one subagent each | `types-tests-dead.md` |

Multi-subagent lines: each subagent appends its own `## {skill}` section. Tick only when all sections exist.

Specialist `critical`/`important` lines: run Phase 2 verify on them too, append to `verified.md`.

### arch-fit

Goal: say what shape the app has, and what shape each part should have. Advice, not just rule checks.

1. Declared pattern? Look in `CLAUDE.md`, `docs/system-map/`, `docs/adr/`, README. Found → name it + where. Then only check drift from it (god files still checked).
2. Current shape. Read folder tree of `{APP}`, `{LIB}`, `src/modules` if there. Name it: `crud`, `layered`, `vertical-slice`, `modular-monolith`, `clean-hex`, `ddd`, `mixed`, or `none`. Give 2–3 folder paths as proof.
3. God files. Any source file (skip tests, migrations, generated) that hits 2+ of:
   - 400+ lines
   - 15+ exports
   - mixes 2+ of: UI render, DB query, outside API / SDK call, business rules
   One line each: `important | simplification | file:1 | god file: {lines} lines, mixes {what} | split with code-review-kit:refactor-slicer`.
4. No declared pattern → recommend per business area (billing, auth, AI, settings, admin, …). Pick the simplest shape that fits, from this ladder:
   `crud` → `layered` → `vertical-slice` → `modular-monolith` → `clean-hex` → `ddd` → `event-driven / cqrs` → `microservices`
   - Default for small-team SaaS: modular monolith, `crud` for plain data screens, `clean-hex` only where outside vendors or money live (billing, auth, AI, email, sync).
   - `ddd` only when business rules are many and change often.
   - `event-driven / cqrs` only with real queue / high-write load.
   - `microservices`: never for one team unless the user asks.
5. Write `arch-fit.md`:

```
## Declared pattern
{name + file, or "none"}
## Current shape
{shape} — proof: {paths}
## God files
{finding lines, or "none"}
## Recommendation
| Area | Today | Recommend | Why (one line) |
## First 3 moves
{smallest safe steps, in order}
```

God-file lines go through Phase 2 verify. Recommendation table is advice: not verified, not tallied.

## Phase 4 — follow-up

Previous run = latest `code-review/weekly-*` before this one. None → write "first run" and tick.

Subagent reads previous `verified.md` CONFIRMED lines. Each: check code now → `FIXED` or `OPEN`. Write `followup.md`: fixed count, open list (oldest first). Open 2+ runs in a row → bump to `critical`.

## Phase 5 — summary

Write `SUMMARY.md`:

```markdown
# Weekly Review — {DATE}

Slices: {n} | Files: {n} | Tool checks: {pass}/{total}
Confirmed: crit {n} | imp {n} | minor {n} | false alarms {n}
Last run: fixed {n} | still open {n}

## Critical
{confirmed critical, grouped by category}

## Important
{confirmed important, grouped by category}

## Tool checks
## Security
## Ownership + locking
## Scale
## Schema
## Module borders
## Architecture fit
## Boundaries
## Types, tests, dead code
## Follow-up
{one short block each, from the phase files}

## Next actions
{top 5 fixes, critical first}

## Files
{link every file in run dir}
```

## Phase 6 — tally + rule advice

Cumulative file: `code-review/pattern-analysis.md`. Missing → create:

```markdown
# Pattern Analysis (cumulative)

| Category | Runs seen | Slices this run | Trend |
|---|---|---|---|

## Suggested new rules
## Suggested new checker skills
## Changelog
```

Subagent:
1. Count unit = **slices affected** (a specialist file = 1 slice). CONFIRMED + minor only.
2. Update table: runs seen +1 if category appears, slices this run, trend vs last run (up / down / same).
3. Rule advice, re-derived from scratch each run:
   - 2–3 slices → suggest a coding-standard or arch-rule edit. Give exact rule wording + target file (the project `CLAUDE.md` "Architecture Rules" section, or `docs/system-map/frontend-map.md`).
   - 4+ slices → suggest a new checker skill, or tighten the existing one that should have caught it (name it).
   - Already covered by a rule but still 4+ → say the rule is not working; suggest a lint rule or test that enforces it.
   - Dropped below 2 → remove suggestion.
4. Changelog line: date, top 3 categories, suggestions added / removed.
5. Write `pattern-delta.md`: what went up / down, new suggestions, removed ones, top 2 to act on.

Never edit rules or skills here. Suggest only. User decides.

## Phase 7 — report

Tell user, short:
- confirmed counts by severity + false alarms
- top 3 critical
- top 2 categories + any rule / skill suggestion
- architecture fit: current shape, god file count, top recommendation
- fixed vs open from last run
- path to `SUMMARY.md`, `pattern-delta.md`, `code-review/pattern-analysis.md`

## Notes

- Slices sequential (2 subagents each). Specialists max 3 at once.
- Slice list comes from `slices.sh` every run. Folders change → script still covers them; `UNCOVERED` shows gaps.
- Old migrations (all but newest 25) skipped on purpose: already applied everywhere.
- One copy only: this file. Do not copy it into each project (rule 9, one path per feature).
- Report files are committed with the next normal commit, not by this skill.
