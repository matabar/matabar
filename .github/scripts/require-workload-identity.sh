#!/usr/bin/env bash
# Fail early with a pointer to the repository variables when the Workload
# Identity settings are empty, instead of an opaque auth error later.
#
# Env: PROVIDER         Workload Identity provider resource name
#      SERVICE_ACCOUNT  service account email
set -euo pipefail

if [ -z "${PROVIDER:-}" ] || [ -z "${SERVICE_ACCOUNT:-}" ]; then
  echo "Set the WIF_PLAN_* or WIF_APPLY_* repository variables from the github-wif outputs."
  exit 1
fi
