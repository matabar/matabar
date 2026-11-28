#!/usr/bin/env bash
# Write the affected projects as a JSON array to $GITHUB_OUTPUT as `projects`
# (stdout when unset), for job-level decisions in workflows. Uses NX_BASE and
# NX_HEAD, which nrwl/nx-set-shas exports.
set -euo pipefail
projects=$(npx nx show projects --affected --json | tr -d '[:space:]')
echo "projects=${projects}" >> "${GITHUB_OUTPUT:-/dev/stdout}"
