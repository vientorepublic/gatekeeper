# Public Repository CI Access

- Kind: implementation handoff
- Status: resolved
- Stage: verified-local
- Outcome: completed locally; commit and push requested
- Created / last verified: 2026-10-25
- Type: removal
- Scope: root workflows, deployment helper, regression tests, and operational documentation
- Baseline: clean root dev `ce18cf8`; clean backend `3658bd1` and frontend `3bb100f`
- Branch lifecycle: `feat/public-ci-checkout` from fetched origin/dev; push only, no promotion or deployment requested
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
- Hosted Actions and production deployment not run; no PR/main promotion requested.

## Publication and remaining work

Commit and push the verified root feature branch with submodule remote checking.
No child commits or pointer updates are required. Before this feature, origin/main
versus origin/dev was 0/2 with real verification-documentation changes; this task
must not promote that existing work to main or attempt release synchronization.
