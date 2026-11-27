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
shared='^infra/(root\.hcl|live/terragrunt\.hcl|live/prod/env\.hcl|live/prod/gcp/provider\.hcl|live/prod/gcp/europe-west3/region\.hcl)$'
if printf '%s\n' "$files" | grep -Eq "$shared"; then
  echo ALL
  exit 0
fi

# Changed units and everything that depends on them, as plain path filters
# relative to infra/, where Terragrunt runs.
# A git-range filter ([base...HEAD]) makes Terragrunt evaluate the unit in a
# separate worktree as well, so one unit could plan or apply twice in
# parallel and race for the state lock.
{
  # Units whose own directory changed (terragrunt.hcl or files beside it).
  printf '%s\n' "$files" | while IFS= read -r file; do
    case "$file" in infra/live/*) ;; *) continue ;; esac
    dir="$(dirname "$file")"
    while [ "$dir" != "." ] && [ "$dir" != "infra/live" ]; do
      if [ -f "$repo_root/$dir/terragrunt.hcl" ]; then
        echo "...$(printf './%s' "${dir#infra/}")"
        break
      fi
      dir="$(dirname "$dir")"
    done
  done

  # Units that source a changed module.
  mods="$(printf '%s\n' "$files" | grep -oE '^infra/modules/[^/]+/[^/]+/' | sed 's#/$##' | sort -u || true)"
  while IFS= read -r mod; do
    [ -n "$mod" ] || continue
    while IFS= read -r unit; do
      [ -n "$unit" ] || continue
      dir="$(dirname "$unit")"
      echo "...${dir/#"${repo_root}/infra"/.}"
    done < <(grep -l -F -- "$mod" $(find "$repo_root/infra/live" -name terragrunt.hcl -print) || true)
  done <<< "$mods"
} | sort -u
