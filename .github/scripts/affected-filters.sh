#!/usr/bin/env bash
# Print Terragrunt --filter expressions for units changed between a base
# revision and HEAD, including dependents. Prints ALL when a shared root
# file changed and every unit should run.
set -euo pipefail

base="${1:?base revision}"
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

if ! git rev-parse --verify --quiet "${base}^{commit}" >/dev/null; then
  echo "Base revision ${base} is not available. Fetch it before selecting units." >&2
  exit 1
fi

files="$(git diff --name-only "${base}...HEAD")"
shared='^(root\.hcl|live/terragrunt\.hcl|live/prod/env\.hcl|live/prod/gcp/provider\.hcl|live/prod/gcp/europe-west3/region\.hcl)$'
if printf '%s\n' "$files" | grep -Eq "$shared"; then
  echo ALL
  exit 0
fi

# Changed units and everything that depends on them.
echo "...[${base}...HEAD]"

mods="$(printf '%s\n' "$files" | awk -F/ '/^modules\/[^/]+\/[^/]+\// { print $1 "/" $2 "/" $3 }' | sort -u)"
while IFS= read -r mod; do
  [ -n "$mod" ] || continue
  while IFS= read -r unit; do
    [ -n "$unit" ] || continue
    dir="$(dirname "$unit")"
    rel="./${dir#"${repo_root}/"}"
    echo "...${rel}"
  done < <(grep -l -F -- "$mod" $(find "$repo_root/live" -name terragrunt.hcl -print) || true)
done <<< "$mods"
