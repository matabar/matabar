# site

The static site served at `https://matabar.online`. It is a single hand-written page, `index.html`, with inline CSS and no build step.

## Edit

Change `apps/site/index.html` on a `feature/<name>` branch and open a pull request. Use the commit scope `site`. Open the file in a browser to preview it; nothing needs to be installed.

## Checks

The `site` project in `pr-checks` runs when a pull request touches `apps/site/`, `.github/`, or `.tool-versions`. See the root [README](../../README.md#pull-request-checks) for how paths map to projects and for the aggregate `ci` check.

## Publish

The `pages` workflow (`.github/workflows/pages.yml`) publishes `apps/site/` to GitHub Pages on every push to `main` that changes `apps/site/**` or the workflow itself, and on manual dispatch from the Actions tab. It uploads the directory as the Pages artifact and deploys it in the `github-pages` environment. One deployment runs at a time; a newer push waits instead of cancelling a deployment that is publishing.

## Custom domain

The domain `matabar.online` is not configured in this directory. The Pages custom domain and HTTPS setting are managed by the GitHub unit, and the DNS records by the DNS unit, both under [`infra/`](../../infra/README.md) (see "GitHub repositories" and "DNS" there).
