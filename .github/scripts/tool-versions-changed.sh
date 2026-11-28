#!/usr/bin/env bash
# Exit 0 when .tool-versions changed for a tool that the given project uses
# between a base revision and HEAD, exit 1 when it did not. Compares lines, not
# the file, so bumping a site tool does not count as an infra change.
#
# Usage: tool-versions-changed.sh <base-revision> <infra|site> [output]
# With `output` it always exits 0 and writes `<project>=true|false` to
# $GITHUB_OUTPUT (stdout when unset), for use as a workflow step.
# A tool missing from the lists below counts for both projects, so a new pin is
# never silently ignored. Add the tool to its project here when you add the pin.
set -euo pipefail

base="${1:?base revision}"
project="${2:?infra or site}"
mode="${3:-exit}"
cd "$(git rev-parse --show-toplevel)"

case "$project" in
  infra) own=" opentofu terragrunt tflint trivy "; other=" node lychee " ;;
  site) own=" node lychee "; other=" opentofu terragrunt tflint trivy " ;;
  *) echo "Unknown project: $project" >&2; exit 2 ;;
esac

# Tool names on added or removed lines; comments and blank lines are skipped.
tools="$(git diff -U0 "${base}...HEAD" -- .tool-versions |
  awk '/^[+-]/ && !/^(\+\+\+|---)/ { key = substr($1, 2); if (key == "") key = $2; if (key != "" && key !~ /^#/) print key }' |
  sort -u)"

changed=false
for tool in $tools; do
  case "$other" in *" $tool "*) continue ;; esac
  changed=true
  break
done

if [ "$mode" = "output" ]; then
  echo "${project}=${changed}" >> "${GITHUB_OUTPUT:-/dev/stdout}"
  exit 0
fi
[ "$changed" = true ]
