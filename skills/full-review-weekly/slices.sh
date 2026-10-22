#!/usr/bin/env bash
# Build review slices for full-review-weekly. Works for root layout (app/, lib/)
# and src layout (src/app, src/lib).
# Out: one line per file, "slice<TAB>path", max CAP files per slice.
# Stderr: layout found, count per slice, then any code file no slice covers.
# Run from repo root: bash <skill dir>/slices.sh > code-review/weekly-DATE/slices.tsv
set -euo pipefail
shopt -s nullglob
CAP=25

code() {
  find "$@" -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.sql' \) \
    -not -name '*.d.ts' -not -path '*/node_modules/*' -not -path '*/.next/*' 2>/dev/null | sort
}

# Pack units (dir or file) into slices of <= CAP files. Unit kept whole when it fits.
pack() {
  local name=$1; shift
  local n=1 buf=() files=()
  flush() {
    [ ${#buf[@]} -eq 0 ] && return
    for f in "${buf[@]}"; do printf '%s-%d\t%s\n' "$name" "$n" "$f"; done
    n=$((n + 1)); buf=()
  }
  for unit in "$@"; do
    [ -e "$unit" ] || continue
    mapfile -t files < <(code "$unit")
    [ ${#files[@]} -eq 0 ] && continue
    if [ $((${#buf[@]} + ${#files[@]})) -gt $CAP ]; then flush; fi
    for f in "${files[@]}"; do
      buf+=("$f")
      if [ ${#buf[@]} -ge $CAP ]; then flush; fi
    done
  done
  flush
}

first() { for d in "$@"; do [ -d "$d" ] && { echo "${d%/}"; return; }; done; echo ""; }
# Drop listed entries (exact match) from stdin.
without() { grep -vxF -f <(printf '%s\n' "$@") || true; }

if [ -d src ]; then B=src; else B=.; fi
pre() { [ "$B" = . ] && echo "$1" || echo "$B/$1"; }
APP=$(pre app); LIB=$(pre lib); COMP=$(pre components); HOOKS=$(pre hooks); TYPES=$(pre types)
MIG=$(first db/migrations migrations supabase/migrations)
MODS=$(first "$LIB/modules" "$(pre modules)")
echo "layout: base=$B migrations=${MIG:-none} modules=${MODS:-none}" >&2

ADMIN=("$APP/admin" "$APP/(admin)" "$APP/api/admin" "$LIB/admin" "$COMP/admin")

out=$(mktemp)
trap 'rm -f "$out"' EXIT
{
  # Newest migrations only. Older ones already ran everywhere.
  mig=()
  if [ -n "$MIG" ]; then mapfile -t mig < <(ls "$MIG"/*.sql 2>/dev/null | sort | tail -n $CAP); fi
  pack migrations "${mig[@]}"

  mapfile -t shared < <(ls -d "$LIB"/*.ts "$LIB"/*/ "$TYPES" "$(pre proxy.ts)" "$(pre middleware.ts)" \
    "$(pre instrumentation)"*.ts sentry.*.ts 2>/dev/null | sed 's|/$||' | without "$MODS" "$LIB/admin")
  pack shared-lib "${shared[@]}"

  if [ -n "$MODS" ]; then pack modules "$MODS"/*/ "$MODS"/*.ts; fi

  mapfile -t api < <(ls -d "$APP"/api/*/ "$APP"/api/*.ts 2>/dev/null | sed 's|/$||' | without "$APP/api/admin")
  pack api "${api[@]}"

  pack admin "${ADMIN[@]}"

  mapfile -t pages < <(ls -d "$APP"/*/ "$APP"/*.ts "$APP"/*.tsx 2>/dev/null | sed 's|/$||' \
    | without "$APP/api" "$APP/admin" "$APP/(admin)")
  pack pages "${pages[@]}"

  mapfile -t comps < <(ls -d "$COMP"/*/ "$COMP"/*.ts "$COMP"/*.tsx "$HOOKS" 2>/dev/null | sed 's|/$||' \
    | without "$COMP/admin")
  pack components "${comps[@]}"

  # src layout: any other top folder (workers, config, db, ...).
  if [ "$B" = src ]; then
    mapfile -t other < <(ls -d src/*/ | sed 's|/$||' | without "$APP" "$LIB" "$COMP" "$HOOKS" "$TYPES" "$MODS")
    pack other "${other[@]}"
  fi
} > "$out"

cat "$out"
cut -f1 "$out" | uniq -c | awk '{printf "%-16s %s files\n", $2, $1}' >&2

# Coverage check: every code file must sit in a slice (old migrations skipped on purpose).
if [ "$B" = src ]; then scope=(src); else scope=(app lib components hooks types); fi
uncovered=$(comm -23 <(code "${scope[@]}" | sed 's|^\./||' | sort) <(cut -f2 "$out" | sed 's|^\./||' | sort))
if [ -n "$MIG" ]; then
  echo "old migrations skipped on purpose: $(( $(ls "$MIG"/*.sql 2>/dev/null | wc -l) - ${#mig[@]} ))" >&2
fi
if [ -n "$uncovered" ]; then
  echo "UNCOVERED (add to a slice):" >&2
  echo "$uncovered" >&2
fi
