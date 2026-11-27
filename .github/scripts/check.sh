#!/usr/bin/env bash
# Run the pull request checks locally: fmt, validate, tflint, trivy.
# The commands mirror .github/workflows/pr-checks.yml. Change both together.
#
# Usage: check.sh [fmt|validate|tflint|trivy|all]   (default: all)
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$root"

want() { awk -v key="$1" '$1 == key { print $2 }' .tool-versions; }

# Fail early and clearly when a tool is missing; warn when it is not the pinned version.
need() {
  local tool=$1 pin=$2 have
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: '$tool' is not installed. Run 'mise install' (reads .tool-versions) or install $pin $(want "$pin")." >&2
    exit 127
  fi
  have=$("$tool" --version 2>&1 | head -n1 || true)
  case "$have" in
    *"$(want "$pin")"*) ;;
    *) echo "WARN: $tool is not the pinned $(want "$pin") (found: $have). CI uses the pinned version." >&2 ;;
  esac
}

fmt() {
  need tofu opentofu
  need terragrunt terragrunt
  tofu fmt -check -recursive infra
  (cd infra && terragrunt hcl format --check)
}

validate() {
  need terragrunt terragrunt
  need tofu opentofu
  (
    cd infra
    terragrunt run --all --non-interactive -- init -backend=false -input=false -lockfile=readonly
    terragrunt run --all --non-interactive -- validate -no-color
  )
}

tflint_check() {
  need tflint tflint
  (
    cd infra
    tflint --init
    tflint --recursive --config "$root/infra/.tflint.hcl"
  )
}

trivy_check() {
  need trivy trivy
  trivy config --config infra/trivy.yaml .
}

run() {
  echo "==> $1"
  "$2"
}

case "${1:-all}" in
  fmt) run fmt fmt ;;
  validate) run validate validate ;;
  tflint) run tflint tflint_check ;;
  trivy) run trivy trivy_check ;;
  all)
    # Check every tool up front so a missing one fails before any slow step.
    need tofu opentofu; need terragrunt terragrunt; need tflint tflint; need trivy trivy
    failed=""
    # Re-run this script per step: set -e is ignored inside a function called
    # from an "||" list, which would hide early failures.
    for step in fmt validate tflint trivy; do
      "${BASH_SOURCE[0]}" "$step" || failed="$failed $step"
    done
    if [ -n "$failed" ]; then
      echo "FAILED:$failed" >&2
      exit 1
    fi
    echo "All checks passed."
    ;;
  *) echo "Usage: $0 [fmt|validate|tflint|trivy|all]" >&2; exit 2 ;;
esac
