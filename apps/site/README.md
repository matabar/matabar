# site

The static site served at `https://matabar.online`. It is a single hand-written page, `index.html`, with inline CSS and no build step.

## Edit

Change `apps/site/index.html` on a `feature/<name>` branch and open a pull request. Use the commit scope `site`. Open the file in a browser to preview it; nothing needs to be installed.

## Checks

The `site` project is affected by changes under `apps/site/`, the shared CI and tooling files, the root `.tool-versions` (node), and the root `package.json` and lockfile. See the root [README](../../README.md#nx-and-pull-request-checks) for affected detection and the aggregate `ci` check.

Its Nx targets (`apps/site/project.json`) run in jobs with read-only permissions and no cloud credentials:

- `html` (job `html`) validates the HTML with [html-validate](https://html-validate.org) (`html-validate:recommended`, config in `apps/site/.htmlvalidate.json`).
- `links` (job `links`) runs [lychee](https://lychee.cli.rs). Internal links and fragments are checked offline and strictly; a broken one fails the check.
- `links-external` checks external links with retries and a 20 s timeout (403 and 429 count as reachable). It is advisory: a `continue-on-error` step in the `links` job, so it shows as failed but never fails the job, and an outage of a third-party site cannot block a merge.

Lychee is pinned in `apps/site/.tool-versions` and node in the root `.tool-versions` (installed in CI by `jdx/mise-action` with `working_directory: apps/site`). Bumping lychee affects only `site`; bumping node affects both projects. html-validate and Nx are pinned with their dependencies by the root `package-lock.json`, installed with `npm ci --ignore-scripts`; Dependabot bumps them through the `npm` ecosystem. Dependabot cannot track lychee or node, so bump them by hand. Run the checks locally with `npx nx run site:html`, `site:links` or `site:links-external`; `html` and `links` are also part of `mise run check`.

## Publish

The `pages` workflow (`.github/workflows/pages.yml`) publishes `apps/site/` to GitHub Pages on every push to `main` that changes `apps/site/**` or the workflow itself, and on manual dispatch from the Actions tab. It uploads the directory as the Pages artifact and deploys it in the `github-pages` environment. One deployment runs at a time; a newer push waits instead of cancelling a deployment that is publishing.

## Custom domain

The domain `matabar.online` is not configured in this directory. The Pages custom domain and HTTPS setting are managed by the GitHub unit, and the DNS records by the DNS unit, both under [`infra/`](../../infra/README.md) (see "GitHub repositories" and "DNS" there).
