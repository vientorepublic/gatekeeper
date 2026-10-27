# Change: Main-only Cloudflare Pages Actions

- Kind: implementation handoff
- Status: resolved
- Stage: deployed
- Outcome: completed application migration; released child pointer recorded in this metadata change
- Created / last verified: 2026-10-28
- Type: modification
- Scope: gatekeeper-frontend workflow, deployment settings and metadata documentation
- Baseline: frontend dev at the published 1.0.1 state; no existing frontend modifications
- Branch lifecycle: feat/pages-actions-production-only -> dev -> main

## Objective and boundaries

Native Git integration creates skipped deployment rows even when previews are disabled. Replace it with main-only GitHub Actions uploads to the existing Pages project. Preserve domains, encrypted production bindings, app behavior and backend code.

## Acceptance criteria

- AC-1: Main pushes automatically check, test, build and upload the exact release SHA as a production deployment.
- AC-2: Non-main pushes create no Cloudflare deployment record, including skipped rows.
- AC-3: The deployment credential is Pages Write only and restricted by a main-only production environment.
- AC-4: The production API base remains the verified public value, and existing encrypted runtime secrets remain unchanged.

## Impact and implementation

The package maintenance version is 1.0.2. Wrangler 4.152.0 was already resolved transitively and is now pinned directly. The workflow pins Node 24.22.1 and npm 11.13.0, uses npm ci, runs lint/check/unit tests/build, and invokes Wrangler with an explicit production branch and commit SHA. Only deployment receives the Cloudflare credential. Public build-time settings are repository Variables; credentials are production environment Secrets.

Prepare the workflow and credentials before disconnecting the native Git source. Publish through feature-to-dev and ancestry-preserving dev-to-main PRs, verify Actions production deployment, then probe a temporary non-main push. Update the root pointer only after the child release is remotely available.

## Verification evidence

Local install/lockfile gate passed: npm install then npm ci retained the lockfile checksum. Lint/check passed, 19 unit tests passed, and Cloudflare/Node adapter builds passed. Final workflow formatting, actionlint 1.7.12, publication and hosted deployment checks passed. The final install/ci gate and checks used the existing production npm 11.13.0 toolchain; resolved dependency versions were unchanged.

The user explicitly confirmed creation and storage of two Pages Write credentials. Gatekeeper uses its own token in the main-only production environment Secret. Authentication was verified; temporary private files and clipboard values were removed. Native Git was disconnected via the Pages source DELETE endpoint after Actions readiness. Domains and all existing encrypted runtime binding keys were verified unchanged. No token values are stored in this record.

## Publication and completion

- Feature [PR 54](https://github.com/vientorepublic/gatekeeper-frontend/pull/54) merged into dev; [promotion PR 55](https://github.com/vientorepublic/gatekeeper-frontend/pull/55) merged into main with ancestry preserved.
- [v1.0.2](https://github.com/vientorepublic/gatekeeper-frontend/releases/tag/v1.0.2) points to exact frontend main/dev `0933ce306effd70d76c25c1e3a3c002de99b8e8c`.
- Actual main-push [run 40572412930](https://github.com/vientorepublic/gatekeeper-frontend/actions/runs/40572412930) succeeded. Independent post-disconnection [run 40572780596](https://github.com/vientorepublic/gatekeeper-frontend/actions/runs/40572780596) also succeeded.
- Current production deployment `8dd163fd-f84a-4b6a-bbfa-43a14bbce0c8` is an Actions upload (`ad_hoc`) on main at the exact release SHA.
- Actual dev restoration and disposable `renovate/pages-actions-record-check-20261028` pushes occurred after Git source disconnection. The complete deployment ID set was identical before and after the probe (13 records); zero non-main or skipped probe records and no probe Actions runs were found. The temporary branch was deleted afterward.
- Production frontend returned 200 and retained `https://api.viento.me` as its public API base. No real-user OAuth or key mutations were performed.
- Main/dev are 0/0 with identical trees; local frontend dev equals origin/dev and is clean. Its root gitlink update accompanies this record.
- The parent dev branch also contains an existing, already-integrated documentation-only follow-up for topic 10. Its main promotion includes that verification record without changing its content or publishing unrelated application work.
