#!/usr/bin/env bash
# Run the pull request checks locally: fmt, validate, tflint, trivy (infra) and
# site-html, site-links (apps/site).
# This script is the single definition of each check: the jobs in
# .github/workflows/pr-checks.yml run it as `.github/scripts/check.sh <step>`.
# Change a check here, not in the workflow. In CI (CI=true) a tool that is not the
# pinned version is an error; locally it is a warning.
#
# Usage: check.sh [fmt|validate|tflint|trivy|site-html|site-links|site-links-external|all]   (default: all)
# site-links-external is advisory (network) and not part of all.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$root"

want() { awk -v key="$1" '$1 == key { print $2 }' .tool-versions; }

# Fail early and clearly when a tool is missing; when it is not the pinned version, warn locally and fail in CI.
need() {
  local tool=$1 pin=$2 have
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: '$tool' is not installed. Run 'mise install' (reads .tool-versions) or install $pin $(want "$pin")." >&2
    exit 127
  fi
  have=$("$tool" --version 2>&1 | head -n1 || true)
  case "$have" in
    *"$(want "$pin")"*) ;;
    *)
      if [ "${CI:-}" = "true" ]; then
        echo "ERROR: $tool is not the pinned $(want "$pin") (found: $have)." >&2
        exit 1
      fi
      echo "WARN: $tool is not the pinned $(want "$pin") (found: $have). CI uses the pinned version." >&2
      ;;
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

# apps/site checks. Tool versions: .tool-versions (node, lychee) and
# .github/site-checks/package-lock.json (html-validate).
# html-validate comes from the committed lockfile in .github/site-checks
# (npm ci), so its transitive dependencies are pinned too. Lifecycle scripts are off.
site_html() {
  need node node
  npm ci --ignore-scripts --no-audit --no-fund --prefix .github/site-checks
  .github/site-checks/node_modules/.bin/html-validate --config .github/site-checks/htmlvalidate.json apps/site
}

# Internal links and fragments are checked strictly and offline.
site_links() {
  need lychee lychee
  lychee --offline --include-fragments --no-progress --root-dir "$root/apps/site" 'apps/site/**/*.html'
}

# External links need the network and can flake, so this is advisory: retries,
# generous timeout, and rate limits or bot blocks (403, 429) count as reachable.
site_links_external() {
  need lychee lychee
  lychee --max-retries 3 --retry-wait-time 5 --timeout 20 --accept '200..=299,403,429' \
    --no-progress --root-dir "$root/apps/site" 'apps/site/**/*.html'
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
  site-html) run site-html site_html ;;
  site-links) run site-links site_links ;;
  site-links-external) run site-links-external site_links_external ;;
  all)
    # Check every tool up front so a missing one fails before any slow step.
    need tofu opentofu; need terragrunt terragrunt; need tflint tflint; need trivy trivy
    need node node; need lychee lychee
    failed=""
    # Re-run this script per step: set -e is ignored inside a function called
    # from an "||" list, which would hide early failures.
    for step in fmt validate tflint trivy site-html site-links; do
      "${BASH_SOURCE[0]}" "$step" || failed="$failed $step"
    done
    if [ -n "$failed" ]; then
      echo "FAILED:$failed" >&2
      exit 1
    fi
    echo "All checks passed."
    ;;
  *) echo "Usage: $0 [fmt|validate|tflint|trivy|site-html|site-links|site-links-external|all]" >&2; exit 2 ;;
esac
