# Change: Security Release Local and Hosted Validation

- Kind: implementation / deployment handoff
- Status: resolved
- Stage: deployed
- Outcome: completed
- Created / last verified: 2026-10-24
- Type: modification
- Scope: backend/frontend 1.0.1 security release, root composition and hosted verification
- Baseline: root 94667c4, backend 1e66b0c, frontend f9460c6
- Branch lifecycle: existing feat/node2shell-runtime in all repositories; user authorized release/deployment after local execution checks
- Related: [runtime hardening](../07-node2shell-runtime/change.md), [audit fixes](../08-transitive-audit-remediation/change.md)

## Objective and acceptance criteria

- AC-1: Run the actual built apps locally against isolated disposable services;
  verify success/denial paths and browser UI before publication.
- AC-2: Publish verified app 1.0.1 trees through feature -> dev -> main PRs,
  publish exact-SHA app Releases, and pin these in the root composition.
- AC-3: Root CI/backend automatic deployment succeeds; Pages production deploys
  the final frontend main SHA; verify public HTTP/assets/configuration.
- AC-4: Record immutable releases and restore clean updated dev in all repos,
  classifying ancestry/tree differences and safely cleaning merged features.

No API/schema migration is introduced. Backend rollout uses the existing CI
WireGuard/SSH isolated-release workflow; database/Redis are not rollout targets.
Pages project gatekeeper-frontend is Git-linked to frontend main; its build command
and output remain npm run build and .svelte-kit/cloudflare. Existing masked secrets
must never be round-tripped. Private GitHub protection API reports plan limitation
403; verify available checks and merge state without admin bypass.

## Local execution evidence

- Node 24.22.1, npm 11.13.0; prior final package gates and 137 tests from topic 08
  remain valid for unchanged app state. Locks remain backend df46fcd3...,
  frontend 0a844dd5.... Versions 1.0.1 are free against fetched dev/main and tags.
- Docker unavailable. Isolated Homebrew MariaDB and Redis run in temporary
  directories/ports; no operator .env or existing database was used.
- Actual backend dist/main runs in production mode, applies its registered migration
  to the empty test DB, and uses the isolated Redis. Actual frontend build/index.js
  points to the local backend. OAuth provider and Brotli upstream are local fixtures.
- Actual HTTP integration script passed: process health; missing-auth denial;
  invalid OAuth state denial; PKCE S256 authorization and callback; namespace list;
  Brotli-compressed JSON key issuance; key listing/pagination; authenticated proxy
  consumption of Brotli upstream; unknown namespace denial; refresh; key revocation
  and cached authentication rejection; home/dashboard SSR and unknown-route 404.
- In-app browser completed fixture OAuth redirect/callback into the dashboard;
  issued a temporary key, confirmed its row, revoked it, and reloaded to confirm
  persisted Revoked/disabled control state. No production user/key was changed.
- Browser Harness doctor could not connect to a local daemon; in-app browser
  provided actual browser validation instead. Synthetic-provider success is not
  evidence of real production FlowAuth user login.

## Publication and hosted results

App feature commits: backend ffb8670da6fb5268355a511325332063ad872201;
frontend 13e03461f776a3ae5c425d6f9ee14c0ef7d39ad2. Feature PRs
[backend #50](https://github.com/vientorepublic/gatekeeper-backend/pull/50) and
[frontend #51](https://github.com/vientorepublic/gatekeeper-frontend/pull/51) merged
into dev with identical verified package trees. Promotion PRs
[backend #51](https://github.com/vientorepublic/gatekeeper-backend/pull/51) and
[frontend #52](https://github.com/vientorepublic/gatekeeper-frontend/pull/52) merged
with ancestry preserved. GitGuardian passed on each; these children do not have a
separate application-test workflow. Local check evidence and root hosted CI are
recorded separately.

Final app main trees match local validated trees exactly:
- Backend: 3658bd1c15f992ed9e0422d54f139635bfc5f22a.
- Frontend: 3bb100fe01f55eb1c5a74850e74ddacf4812abd0.

Root integration, final hosted verification and synchronization are pending.
Preserve immutable release trees; record actual release/deployment outcomes only
once observed. Pages production d3ecc1e7-ecc1-41c2-b082-2dc0eb14d7c0 has started
building the expected frontend main SHA.

Both app v1.0.1 Releases are published and their lightweight tags resolve to the
exact main SHAs above:
[backend release](https://github.com/vientorepublic/gatekeeper-backend/releases/tag/v1.0.1),
[frontend release](https://github.com/vientorepublic/gatekeeper-frontend/releases/tag/v1.0.1).
Pages production d3ecc1e7-ecc1-41c2-b082-2dc0eb14d7c0 completed all stages
successfully at 2026-10-24 09:48:00 UTC with frontend main 3bb100fe.... Public
HTTP verification is pending. Root deployment script's 14 regression tests and
Bash syntax/language scans passed. Root CI/deployment remain pending.

## Final hosted verification and release

Root feature [PR #19](https://github.com/vientorepublic/gatekeeper/pull/19) and
promotion [PR #20](https://github.com/vientorepublic/gatekeeper/pull/20) passed
hosted backend/frontend checks, deployment-script checks, PR quality gate and
GitGuardian, then merged with ancestry preserved. No admin/protection bypass.
Final root main: `c4d8300e0cd9015ef4381acce5e28b73afde1cb5`; git ls-tree confirms
exact backend `3658bd1c15f992ed9e0422d54f139635bfc5f22a` and frontend
`3bb100fe01f55eb1c5a74850e74ddacf4812abd0` release pins.

[Automatic backend deployment](https://github.com/vientorepublic/gatekeeper/actions/runs/40083668285)
completed successfully at 2026-10-24 09:56:32 UTC (18:56:32 JST). Hosted quality
jobs and WireGuard deployment all succeeded. Logs confirm:
- `node:24.22.1-alpine` digest
  `sha256:06d7adf3e0ef61a13f1d28682726366f97a15aa1888c934d3ecec86c33918b53`.
- Image built, backend recreated/started, then Healthy at 09:56:29 UTC.
- Host HTTP probe passed and Deployed meta/backend output matches release SHAs.
- Tunnel/ephemeral credential cleanup step succeeded.

Post-rollout public checks against https://api.viento.me passed: health 200 with
status ok, unauthenticated namespaces 401, authorize response with URL/state,
and CORS preflight permitting https://gateway.viento.me. No production user/key
mutation or real-account callback/refresh was performed.

[Pages production deployment](https://d3ecc1e7.gatekeeper-frontend.pages.dev)
`d3ecc1e7-ecc1-41c2-b082-2dc0eb14d7c0` succeeded at 09:48:00 UTC (18:48:00 JST)
for frontend `3bb100fe...`; canonical production deployment points to that exact
ID. Authenticated build logs confirm Node 24.22.1. Both immutable deployment and
https://gateway.viento.me home/dashboard SSR returned 200, with expected public
API configuration and three referenced assets per page verified HTTP 200.
Existing Pages variables/secrets/build settings were not modified.

[Composition Release release-20261024.1](https://github.com/vientorepublic/gatekeeper/releases/tag/release-20261024.1)
is published, non-draft/non-prerelease; lightweight tag resolves to exact root main
`c4d8300e...`. Both app v1.0.1 release tags were independently verified as exact
main SHAs. Published release trees are immutable.

## Development restoration and limits

After publishing immutable release references, both apps and root dev refs were
fast-forwarded to their verified main SHAs with force=false after immediately
rechecking refs/ancestry. Before this documentation follow-up, origin/main and
origin/dev were identical in all repos (0/0, empty logs/tree diffs). Local apps
returned clean to dev; package/lock state matches the final installation, so no
additional dependency installation was necessary. Merged feature refs were safely
removed locally with -d and remotely via gh after PR/tip/worktree checks.

This root-only follow-up records observed results on dev, without another main
promotion or deployment. Its eventual dev-only commits are real verification docs,
not missing application release work. Child dev SHAs equal release pins, so root
needs no pointer-only restoration commit. Local final state and diff are checked
again at task completion. No installed app package changed after its final checks.

Temporary local apps, OAuth/upstream fixtures, MariaDB and Redis were stopped.
Local MariaDB 13.0.2 / Redis 8.10.2 differ from the production Compose versions;
local validation is not an exact production-container reproduction. A real user
OAuth flow and production key lifecycle were not exercised. Health does not
establish complete database/upstream readiness. Current container Node was
corroborated through the built image/deployment log, not direct docker exec.
