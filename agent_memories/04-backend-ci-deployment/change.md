# Backend CI and WireGuard Deployment

- Kind: implementation handoff
- Status: active
- Stage: verifying
- Outcome: pending
- Created / last verified: 2026-10-23
- Type: addition
- Scope: both existing app changesets, dependency-first PR/release publication, root workflows/pins and backend deployment
- Baseline: root `e25fa5a`, backend `8a23d18`, frontend `c70749c`; all on existing `codex/dependency-security-refresh` with substantial pre-existing uncommitted changes
- Branch lifecycle: preserve existing feature branches; user subsequently authorized child-first commits/pushes, PRs, merges, and deployment failure remediation
- Related: [setup guide](../../docs/backend-ci-deployment.md), [architecture](../repo/project-architecture.md)

## Objective and boundaries

Follow-up authorization: validate and publish all existing app work, promote each
through dev/main PRs and Releases, publish root pointers/workflows through PRs, then
observe backend deployment and fix/retry concrete failures. Return all local checkouts
to updated dev after recording immutable release SHAs. Initial local-only evidence below
is historical; execution results will be appended as work completes.

Current acceptance also requires both app final package/lock install gates and checks,
child main Releases before root pins, merged root PRs, actual rollout evidence, and
main-to-dev synchronization. Plan/visibility changes remain excluded.

Add root-main-triggered backend deployment through WireGuard using `VULTR_WIREGUARD`
and `VULTR_SSH_SECRET`, connecting as root to `10.20.0.1` and deploying from
`/root/Gatekeeper`. Add PR lint/build/test checks and a stable merge gate.
Root owns Compose and exact app pins, so root events deploy the pinned backend rather
than fetching an independent backend branch. Child PR workflows, runtime changes,
publication, server provisioning, billing changes, and visibility changes are excluded.

## Acceptance criteria

- AC-1: Root main push passes quality checks before using deployment secrets; deploys
  the exact current main SHA and backend pin, builds before replacement, waits for
  container health and checks HTTP health. Errors produce a failed deployment.
- AC-2: All root PRs and merge groups run both app checks; failure, cancellation, or
  skipped prerequisites fail `PR quality gate`. Branch protection requires this check.
- AC-3: Local server edits/divergent history are preserved, stale deployments skip,
  deployment is serialized, SSH host verification remains enabled, temporary secrets
  and WireGuard are cleaned on completion/failure/cancellation.

## Impact and compatibility

Only root files changed. App APIs, persistence, frontend UI, package versions, lockfiles,
gitlinks, and unrelated dirty work remain unchanged. No root package or app bump is
needed. `quality.yml` checks backend lint/types/build/unit/integration tests and frontend
lint/types/unit/Cloudflare and Node builds. Backend lint mutations fail CI.

Three GitHub secrets are required: the two requested deployment secrets plus
`SUBMODULE_READ_TOKEN`, because gh confirmed all three repositories are private.
The read token needs Contents read on the three repositories and is used only for
checkout, without persistent Git credentials. Fork/Dependabot contexts without it
fail closed. `VULTR_SSH_KNOWN_HOSTS` is an additional repository variable holding the
verified public SSH host key, not a secret. Deploy credentials are not passed to PR jobs.

Server prerequisites: clean main checkout, fetch access, correct submodule registration,
Compose environment files/network, running DB/Redis, Linux flock/curl/Docker/Compose.
Only backend is rebuilt/replaced. No automatic database rollback or readiness guarantee;
startup migrations remain the application's existing behavior.

## Implementation sequence

1. Inspected root/child status, branches/remotes/diffs, gitlinks/registration, READMEs,
   Compose, Dockerfile, scripts, memory and development workflow.
2. Added reusable/root-PR quality workflow and main deployment caller, with explicit
   failure aggregation and merge queue events.
3. Added remote deployment script and mock regression tests; documented prerequisites,
   secrets, protection setup, and operational limits.
4. Validated syntax and rollout failure boundaries; checked GitHub capability using gh.

## Verification evidence

- AC-1/AC-3 local logic: `bash -n tools/ci/deploy-backend.sh` passed.
- `python3 -m unittest discover -s tools/ci -p 'test_*.py' -v`: 7 tests passed,
  including success ordering, malformed SHA, superseded pushes, dirty root/backend,
  wrong branch, divergent history, failed build, unhealthy container and HTTP failure.
  Uses mock commands; does not connect to production.
- `/private/tmp/gatekeeper-ci-bin/actionlint .github/workflows/quality.yml .github/workflows/deploy-backend.yml`
  passed with actionlint 1.7.7. Shellcheck is not installed, so its optional integration
  was not run. Bash parser and regression checks were run separately.
- Root `node tools/check-agent-guidelines.mjs`: passed, 114 files / 113 comments /
  132 test titles scanned. `git diff --check` passed for tracked changes.
- App checks/install gates not rerun: no app files or package states changed in this
  task, and no commits are being made. Hosted clean-install checks are defined but
  have not run. Existing gitlinks still point to pre-refresh commits, whose frontend
  lacks the new test script. Publish verified app work and update pins before CI rollout.
- `gh auth status` succeeded with network access. The initial sandbox network failure
  misleadingly reported invalid authentication; it was not an actual invalid token.
- `gh repo view ... --json visibility` confirmed PRIVATE for root/backend/frontend.
- `gh api repos/vientorepublic/gatekeeper/rulesets` and
  `gh api repos/vientorepublic/gatekeeper/branches/main/protection` both returned
  HTTP 403: `Upgrade to GitHub Pro or make this repository public to enable this feature.`
  Actual merge blocking cannot be activated under the current capability.

## Publication and completion

### Follow-up publication evidence

Both app final gates passed with Node 24.22.1/npm 11.13.0 and normal lifecycle scripts.
The initial npm 12 attempt blocked dependency scripts by default; it was superseded
by a complete npm 11 `npm i`/`npm ci`/checks run and is not the release gate evidence.
Both manifests/root locks are 1.0.0, reusing the existing unreleased major bump because
route configuration validation, browser login state and development tooling require
consumer/operator action. Prior notes' 0.0.2 proposal is superseded for this release.

- Backend lock SHA-256: `aac45dd2d5321dc05e8670d0b3cc55421fe12780eabaac684ff814437deed042`.
- Frontend lock SHA-256: `95ed75a18e403730e5af34971bd2c2ebc25ef259ec8d765b278ea3226f79546d`.
- Both lock checksums unchanged by npm ci; lint/type/build/test gates passed.
  Backend 71 unit/47 integration; frontend 19 unit and both adapters; full/production
  audits zero vulnerabilities. Backend proxy smoke: 2s, 2 connections, 1024 bytes,
  GET/POST legacy/optimized all zero errors/timeouts; not a performance guarantee.
- Signed backend feature commit `dc6ed15d24a6508bdb6271e0ed0ad0bb73820dd4`,
  [feature PR #47](https://github.com/vientorepublic/gatekeeper-backend/pull/47),
  [main promotion #48](https://github.com/vientorepublic/gatekeeper-backend/pull/48),
  final main `7c6fccede657ab7cdac25725a5726e829a6e199c`,
  [v1.0.0 Release](https://github.com/vientorepublic/gatekeeper-backend/releases/tag/v1.0.0).
- Signed frontend feature commit `41a2a92f0ed78e925df50a2410fe7c00f09a4f06`,
  [feature PR #48](https://github.com/vientorepublic/gatekeeper-frontend/pull/48),
  [main promotion #49](https://github.com/vientorepublic/gatekeeper-frontend/pull/49),
  final main `ec3586823f5d205ee9d8d7b522e077b96721239b`,
  [v1.0.0 Release](https://github.com/vientorepublic/gatekeeper-frontend/releases/tag/v1.0.0).
- All four PRs merged with merge commits after GitGuardian checks succeeded. No app
  lint/build/test Actions existed; those checks were executed locally, not claimed
  as hosted CI. Final dev/main trees exactly match the tested feature trees.
- Both immutable tags resolve to the exact final main SHAs and both SHAs are reachable
  from origin/main. Root stages those SHAs after child release publication.
- Root dev was absent; created via gh refs API at verified origin/main `e25fa5a426c6efa271cea6265a5cde19c2414dfd`.
- Root local registration now includes declared names `backend`/`frontend`; existing
  path-named local settings were retained. No directories were reset or reinitialized.
- Existing trusted local SSH known_hosts supplied the ed25519 key for 10.20.0.1;
  registered its public value as `VULTR_SSH_KNOWN_HOSTS`. No private key was read.
  Root metadata confirms both deployment secrets exist. `SUBMODULE_READ_TOKEN`
  remains a user configuration prerequisite; requested without asking for raw tokens.

Root PRs, deployment observation, composition Release and return-to-dev synchronization
are still in progress. The following initial handoff paragraph describes the earlier
local-only state and is retained as historical evidence.

Workflow/script implementation and local logic checks are complete. AC-2 remote
enforcement and actual Actions/WireGuard/SSH/Compose execution remain unverified.
No secrets were read or changed; no remote configuration was mutated. No commit, push,
release, pointer update, server connection, or production deployment was performed.

Next: configure the documented secrets/host key, publish the verified child work and
root pins through the required dependency-first flow, enable a plan supporting private
branch protection (or explicitly change visibility), then require `PR quality gate`
for main/dev and verify a failing PR cannot merge. Finally verify an authorized main
deployment and record its immutable root/backend SHAs and production health separately.
