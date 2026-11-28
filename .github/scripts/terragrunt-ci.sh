#!/usr/bin/env bash
# Run an affected or full Terragrunt plan/apply. Exits 0 when OpenTofu
# reports no changes or a successful plan with changes (exit 2).
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

# Terragrunt runs from infra/, where root.hcl and live/ are. Filters are
# relative to infra/.
mode="${MODE:?}"
affected="${AFFECTED:-true}"
lock="${LOCK:-false}"
skip_github="${SKIP_GITHUB:-false}"

if [ "${GITHUB_EVENT_NAME:-}" = "pull_request" ]; then
  base="${PR_BASE_SHA:?}"
else
  # On push this is github.event.before. Diffing against origin/main would
  # compare main with itself after a merge and select nothing.
  base="${BASE_REVISION:-}"
fi

# A new branch (all-zero before), a missing revision, or no base at all
# cannot be diffed, so run every unit.
if [ "$affected" = "true" ]; then
  if [ -z "$base" ] || [ -z "${base//0/}" ] \
    || ! git rev-parse --verify --quiet "${base}^{commit}" >/dev/null; then
    echo "No usable base revision (${base:-empty}); running every unit."
    affected=false
  fi
fi

filters=()
if [ "$affected" = "true" ]; then
  while IFS= read -r line; do
    if [ "$line" = "ALL" ]; then
      filters=()
      break
    fi
    filters+=(--filter "$line")
  done < <("$repo_root/.github/scripts/affected-filters.sh" "$base")
fi

if [ "$skip_github" = "true" ]; then
  echo "No GitHub App key or GH_ADMIN_TOKEN. The GitHub unit will be left out of this run."
  filters+=(--filter '!./live/prod/github/**')
fi

lock_args=()
if [ "$lock" != "true" ]; then
  lock_args+=(-lock=false)
fi

mkdir -p .github/ci-out
log=.github/ci-out/plan.txt
markdown=.github/ci-out/plan.md
: > "$log"

# Render the log as Markdown for the pull request comment and the drift issue,
# on every exit so a failed run is reported too. GitHub rejects bodies over
# 65536 characters, so the log is cut at 60000 bytes.
render_markdown() {
  local max=60000
  {
    printf '## Terragrunt %s\n\nRun: %s/%s/actions/runs/%s\n\n```\n' \
      "$mode" "${GITHUB_SERVER_URL:-}" "${GITHUB_REPOSITORY:-}" "${GITHUB_RUN_ID:-}"
    if [ "$(wc -c < "$log")" -gt "$max" ]; then
      head -c "$max" "$log"
      printf '\n\n… truncated …'
    else
      cat "$log"
    fi
    printf '\n```\n'
  } > "$markdown"
}
trap render_markdown EXIT

echo "Terragrunt filters: ${filters[*]:-<all units>}" | tee -a "$log"

run_tg() {
  local command="$1"
  shift
  set +e
  (
    cd "$repo_root/infra"
    terragrunt run --all --non-interactive "${filters[@]}" -- \
      "$command" -input=false -no-color "${lock_args[@]}" "$@"
  ) 2>&1 | tee -a "$log"
  local code="${PIPESTATUS[0]}"
  set -e
  if [ "$code" -eq 0 ] || { [ "$command" = "plan" ] && [ "$code" -eq 2 ]; }; then
    return 0
  fi
  echo "terragrunt ${command} failed with exit ${code}" | tee -a "$log"
  return "$code"
}

case "$mode" in
  plan)
    run_tg plan -detailed-exitcode
    ;;
  apply)
    run_tg apply
    ;;
  plan-apply)
    run_tg plan -detailed-exitcode
    run_tg apply
    ;;
  *)
    echo "Unknown mode: ${mode}" >&2
    exit 1
    ;;
esac

if grep -Eq 'Plan: .*\b[1-9][0-9]* to (import|add|change|destroy)' "$log"; then
  echo "changes=true" >> "${GITHUB_OUTPUT:-/dev/null}"
else
  echo "changes=false" >> "${GITHUB_OUTPUT:-/dev/null}"
fi
