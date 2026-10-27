# Public Repository CI Access

- Kind: implementation handoff
- Status: resolved
- Stage: deployed
- Outcome: completed; main deployed and composition release published
- Created / last verified: 2026-10-25
- Type: removal
- Scope: root workflows, deployment helper, regression tests, and operational documentation
- Baseline: clean root dev `ce18cf8`; clean backend `3658bd1` and frontend `3bb100f`
- Branch lifecycle: `feat/public-ci-checkout` from fetched origin/dev; feature PR #22 merged into dev; user then authorized dev-to-main PR, passing CI, deployment, release, and dev synchronization
- Related: [original deployment](../04-backend-ci-deployment/change.md), [setup guide](../../docs/backend-ci-deployment.md)

## Objective and boundaries

The user made all three repositories public and requested removal of the CI private
repository access credentials and related workflow configuration, followed by commit
and push. Remove app read-key requirements and server-side GitHub token/key forwarding.
Retain WireGuard/server SSH credentials, pinned application revisions, deployment
ordering, stale-run rejection, isolation, health checks, and cleanup behavior.
GitHub stored secrets and app deploy keys are outside the workflow-source cleanup;
this change does not delete them or revoke user credentials.

## Acceptance criteria

- AC-1: Quality and its reusable caller require no private app read-key secrets.
- AC-2: Server Git fetch/submodule update use public HTTPS without injected GitHub
  credentials, SSH URL rewriting, or temporary app-key files.
- AC-3: Existing rollout failure boundaries remain covered; documentation describes
  public access and preserves server SSH/WireGuard prerequisites.

## Impact and implementation

Only root orchestration files change. App APIs, UI, runtime configuration, package
versions, locks, and gitlinks are unchanged; app installations/version bumps are not
applicable. Historical deployment notes retain the evidence of prior private access;
this note and the updated setup guide describe the current implementation.

Removed reusable secrets/read-key matrix entries, checkout SSH key, forwarded GitHub
token/backend key, GitHub SSH host-key lookup, and script credential branches.
Replaced two credential-specific tests with one public-fetch regression test.
The standard Actions checkout token and `contents: read` remain managed by Actions;
`persist-credentials: false` remains on every checkout.

## Verification evidence

- AC-1: actionlint passed for both final workflows.
- AC-2: gh confirmed PUBLIC visibility for root/backend/frontend; three actual
  `GIT_TERMINAL_PROMPT=0 git -c credential.helper= ls-remote` calls succeeded against
  HTTPS origin/dev refs, matching the baseline SHAs above.
- AC-2/AC-3: `bash -n tools/ci/deploy-backend.sh` passed; Python unittest discovery
  passed all 13 deployment tests, including public Git command shape, isolated real
  local clone/index preservation, stale SHA, dirty checkout, and rollout failures.
- Root guideline scanner passed (114 files, 113 comments, 132 test titles before
  adding this note); diff whitespace and local documentation links checked.
- No app source changes: npm gates and app builds/tests not applicable.
- Feature PR #22 and promotion PR #23 passed hosted app checks, deployment script
  checks, PR quality gate, and GitGuardian. Main deployment also passed all checks.

## Publication and hosted deployment

Implementation `ffb7e7e` and integration record `cac1fde` merged through
[PR #22](https://github.com/vientorepublic/gatekeeper/pull/22) into dev `76835b8`.
[Promotion PR #23](https://github.com/vientorepublic/gatekeeper/pull/23) passed CI
and merged with ancestry preserved into main
`16c72f99654959bd63de89595cd35693303b3bc0`. The complete promotion diff also
included the existing topic 09 deployment verification docs. App source, locks,
versions, and gitlinks did not change; existing app v1.0.1 releases were reused.

[Backend deployment run](https://github.com/vientorepublic/gatekeeper/actions/runs/40167706007)
succeeded. Logs show public Git fetch/submodule checkout, successful image build,
backend container Healthy at 2026-10-25 06:07:07 UTC (15:07:07 JST), host health
probe, exact root/backend SHA confirmation, and tunnel/credential cleanup.

[Composition release-20261025.1](https://github.com/vientorepublic/gatekeeper/releases/tag/release-20261025.1)
is published, non-draft/non-prerelease. Its lightweight tag resolves to exact
root main `16c72f99654959bd63de89595cd35693303b3bc0`, containing:

- Backend v1.0.1: `3658bd1c15f992ed9e0422d54f139635bfc5f22a`.
- Frontend v1.0.1: `3bb100fe01f55eb1c5a74850e74ddacf4812abd0`.

Post-rollout curl checks passed public health 200 with status ok, unauthenticated
namespace denial 401, frontend home 200, and preflight allowing the production
frontend origin. An initial Python urllib health request returned 403; curl passed
without infrastructure changes. The reason for this request-dependent difference
was not established. No real-account OAuth/key mutation was performed, and health
does not prove full database/upstream readiness. Frontend was not redeployed.

## Development restoration

After checking current refs, ancestry, successful checks, and absence of branch
protection/rulesets, origin/dev was fast-forwarded with force=false to exact verified
main `16c72f9`. Root main/dev were 0/0 with identical trees before this record.
Both child main/dev remain equal to their release pins and local clean dev; no
package state changed, so dependency reinstallation is not applicable.

Feature refs for PR #22 were safely deleted after integration. Shared main/dev
are retained. This documentation follow-up goes through a separate feature PR to
dev; it records observed results without another deployment or release. Its dev-only
content is real verification documentation, not missing application release work.
