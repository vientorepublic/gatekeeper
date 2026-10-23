# Cloudflare Pages Build Follow-up

- Kind: investigation / deployment verification
- Status: resolved
- Stage: deployed; frontend dev synchronization complete
- Created / last verified: 2026-10-23
- Scope: frontend hosted Pages build and main-to-dev synchronization
- Evidence baseline: frontend main `ec3586823f5d205ee9d8d7b522e077b96721239b`, v1.0.0
- Related: [backend deployment](../04-backend-ci-deployment/change.md)

## Scope and acceptance criteria

The user resumed this previously deferred follow-up after backend deployment.
Correct the hosted build environment, deploy the existing immutable v1.0.0 main
SHA, verify Pages and public responses, then merge PR #50 and restore local dev.
This is a hosting configuration correction. No API, UI, dependency, app version,
release tag, or root gitlink changes were necessary. Backend rollout and operator
data were outside scope. Existing production variables were preserved.

## Confirmed cause and correction

Authenticated Cloudflare logs for failed deployment
`36de4405-0620-4fa6-a500-2bed2beb9ee1` confirm `EBADENGINE`: Pages v3 selected
Node 22.16.0/npm 10.9.2, while SvelteKit 3.1.0 requires Node >=22.17. Build command
`npm run build`, root directory, and output `.svelte-kit/cloudflare` were correct.
The earlier GitHub check only said `Build failed`; its cause was unknown until
Cloudflare connector access became available in this follow-up.

Production and preview now store `NODE_VERSION=24.22.1` and
`NPM_VERSION=11.13.0` as encrypted bindings. The repository Wrangler configuration
is the source of truth for plain variables, so initial plain-text selectors did
not change the build toolchain. Both retry `046e0dcd-d948-48cb-b8c0-0dd0384b1caf`
and fresh deployment `17daefc9-b34d-4eca-a43f-a2a06dc10a18` still failed with the
old Node. The encrypted selectors corrected the next retry. The API returns secret values as empty strings; comparing those responses did not
prove value preservation. Re-submitting the masked values caused the first successful
build to use the default localhost API. This was caught by inspecting the public SSR
environment after deployment. The five existing PUBLIC_* settings were recovered
from the previous immutable successful deployment `393c1341-36d4-42ed-a503-cd47cc784f17`
and restored without printing their values. The public API is `https://api.viento.me`.
Never round-trip masked secret values as writable configuration.
An initial partial environment update was rejected by automatic approval review.
The subsequent full-map update retained names but initially mishandled masked values;
the public settings recovery above corrected this mistake.

The successful log confirms Node 24.22.1 installation. Its initial tool detector
still labels npm 10.9.2 before installing Node; do not infer an exact effective npm
version from the configured selector alone. The earlier local clean-install gate
used Node 24.22.1/npm 11.13.0; hosted build success is independently verified below.

References: [Pages build version overrides](https://developers.cloudflare.com/pages/configuration/build-image/),
[Wrangler source of truth](https://developers.cloudflare.com/pages/functions/wrangler-configuration/).

## Deployment and synchronization evidence

- First build-success deployment: `d5aa654b-fabe-4f89-805f-1bb40bb37b62`; superseded
  by the public configuration recovery deployment described below.
- Exact deployed commit: `ec3586823f5d205ee9d8d7b522e077b96721239b`.
- Clone, build, and deploy stages all succeeded; completed 2026-10-23 10:06:28 UTC.
- [Immutable deployment URL](https://d5aa654b.gatekeeper-frontend.pages.dev).
- [Production domain](https://gateway.viento.me): GET `/` and `/dashboard` returned
  HTTP 200; home response is HTML and includes 14 immutable asset references.
- GitHub PR #50 reported Cloudflare Pages and GitGuardian success, merge state CLEAN.
- [PR #50](https://github.com/vientorepublic/gatekeeper-frontend/pull/50) merged with
  ancestry preserved at 10:07:16 UTC, merge SHA
  `f9460c6d7bd2cb43f765e98dbbf035d710651e57`.
- Local frontend dev fast-forwarded to that exact origin/dev SHA, with a clean tree.
  Released main is an ancestor of dev; source/package tree did not change, so no
  install refresh or new application version/release was needed.
- Existing local lint/type/19-unit/both-adapter checks remain applicable to this
  unchanged source. The hosted deployment ran its normal dependency installation,
  prepare, build, Worker compilation, and asset publication successfully.

Authenticated login/callback/key-management flows were not exercised with a real
account. HTTP smoke and hosted build success do not establish those end-to-end
flows. Root release pins remain the original immutable app main SHAs; local app dev
checkouts intentionally differ due to ancestry synchronization.

## Public configuration recovery verification

The initial successful deployment was subsequently found to expose the localhost
fallback for the API. All five previously configured PUBLIC_* values were restored
from the public SSR environment of the prior successful immutable deployment.
Recovery [deployment `0c2005f6-3268-4089-ba62-f3457c5f262b`](https://0c2005f6.gatekeeper-frontend.pages.dev)
built and deployed successfully at 10:11:43 UTC against the same released main SHA.
Production home, dashboard, and three referenced JavaScript assets returned HTTP 200
using curl. Production SSR now declares the expected `https://api.viento.me` public
API. An earlier Python urllib asset request returned 403; curl checks succeeded.
This final deployment supersedes the first successful build and is the verified
production result. No authentication or API-key mutations were performed.
