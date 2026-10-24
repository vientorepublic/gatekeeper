# Change: Security Release Local and Hosted Validation

- Kind: implementation / deployment handoff
- Status: active
- Stage: verifying
- Outcome: pending
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
