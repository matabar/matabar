#!/usr/bin/env bash
# Run `terragrunt run --all` for CI and do the two things Terragrunt cannot:
# set a `changes` output and render the log as Markdown for the PR comment and
# the drift issue.
#
# Everything else is Terragrunt's own configuration, passed by the workflow as
# environment variables: TG_FILTER (unit selection), TG_NON_INTERACTIVE,
# TG_NO_COLOR, TF_INPUT, TF_CLI_ARGS_plan.
#
# Why a log grep for `changes`: the run report has per-unit results but no
# "plan has changes" field, and -detailed-exitcode cannot be used because the
# aggregate exit code is 2 even when another unit failed with 1, which would
# hide the failure. Without it the exit code means failure only.
set -euo pipefail

mode="${MODE:?plan or apply}"
repo_root="$(git rev-parse --show-toplevel)"
out="$repo_root/.github/ci-out"
log="$out/plan.txt"
mkdir -p "$out"
: > "$log"

# GitHub rejects comment bodies over 65536 characters: cut the log at 60000
# bytes. Runs on every exit so a failed run is reported too.
render_markdown() {
  {
    printf '## Terragrunt %s\n\nRun: %s/%s/actions/runs/%s\n\n```\n' \
      "$mode" "${GITHUB_SERVER_URL:-}" "${GITHUB_REPOSITORY:-}" "${GITHUB_RUN_ID:-}"
    head -c 60000 "$log"
    printf '\n```\n'
  } > "$out/plan.md"
}
trap render_markdown EXIT

cd "$repo_root/infra"
echo "Terragrunt filter: ${TG_FILTER:-<all units>}" | tee -a "$log"

terragrunt run --all -- "$mode" 2>&1 | tee -a "$log"

# Not reached when terragrunt fails: pipefail and set -e exit with its code.
changes=false
if [ "$mode" = plan ] && grep -Eq 'Plan: .*\b[1-9][0-9]* to (import|add|change|destroy)' "$log"; then
  changes=true
fi
echo "changes=${changes}" >> "${GITHUB_OUTPUT:-/dev/null}"
