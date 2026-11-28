# site

The static site served at `https://matabar.online`. It is a single hand-written page, `index.html`, with inline CSS and no build step.

## Edit

Change `apps/site/index.html` on a `feature/<name>` branch and open a pull request. Use the commit scope `site`. Open the file in a browser to preview it; nothing needs to be installed.

## Checks

The `site` project in `pr-checks` runs when a pull request touches `apps/site/`, `.github/`, or the node or lychee line of `.tool-versions`. See the root [README](../../README.md#pull-request-checks) for how paths map to projects and for the aggregate `ci` check.

Two jobs run, with read-only permissions and no cloud credentials:

- `site-html` validates the HTML with [html-validate](https://html-validate.org) (`html-validate:recommended`, config in `.github/site-checks/htmlvalidate.json`).
- `site-links` runs [lychee](https://lychee.cli.rs). Internal links and fragments are checked offline and strictly; a broken one fails the check. External links are checked in a separate advisory step with retries and a 20 s timeout (403 and 429 count as reachable). That step only warns, so a third-party outage cannot block a merge.

Node and lychee are pinned to exact versions in `.tool-versions` (lychee also by sha256 in `.github/actions/setup-lychee`). html-validate and its dependencies are pinned by `.github/site-checks/package-lock.json` and installed with `npm ci --ignore-scripts`; Dependabot bumps it through the `npm` ecosystem. Dependabot cannot track lychee or node in `.tool-versions`, so bump them by hand. A bump of those touches only the site jobs. Run them locally with `.github/scripts/check.sh site-html`, `site-links`, or `site-links-external`; the first two are also part of `mise run check`.

## Publish

The `pages` workflow (`.github/workflows/pages.yml`) publishes `apps/site/` to GitHub Pages on every push to `main` that changes `apps/site/**` or the workflow itself, and on manual dispatch from the Actions tab. It uploads the directory as the Pages artifact and deploys it in the `github-pages` environment. One deployment runs at a time; a newer push waits instead of cancelling a deployment that is publishing.

## Custom domain

The domain `matabar.online` is not configured in this directory. The Pages custom domain and HTTPS setting are managed by the GitHub unit, and the DNS records by the DNS unit, both under [`infra/`](../../infra/README.md) (see "GitHub repositories" and "DNS" there).
