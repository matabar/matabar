#!/usr/bin/env bash
# Find the open issue with exactly the given title and write `number=<n>` to
# $GITHUB_OUTPUT (empty when there is none). The drift workflow uses it to
# pick between creating, updating and closing; no published action looks an
# issue up by title.
#
# Env: TITLE      exact issue title
#      GH_TOKEN   token that can read issues
set -euo pipefail

: "${TITLE:?issue title}"

number="$(gh issue list --state open --limit 1000 --json number,title \
  --jq 'map(select(.title == env.TITLE)) | first | .number // empty')"
echo "number=${number}" >> "${GITHUB_OUTPUT:-/dev/stdout}"
echo "Open issue titled \"${TITLE}\": ${number:-none}"
