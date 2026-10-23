# Repository and Pointer Workflow

- Kind: repository reference / workflow decision / initial environment observation
- Status: current; local registration mismatch resolved during publication
- Last verified: 2026-10-23
- Scope: Git topology, existing changes, dependency order

## Initial state and evidence

Read-only inspection found:

- Root on `main`, tracking `origin/main`; backend and frontend on `dev`, tracking their own `origin/dev`.
- Root gitlinks and child HEADs match backend `8a23d1831ee5d6c79bcf28c59e550eeddbe22ffd` and frontend `c70749cc1ea66367d3cc5a0f4b4d21196eb465a6`.
- Both apps already have modified `package.json` and `package-lock.json`. Manifest diffs change `flowauth-oauth2-client` from `^4.3.2` to `^4.3.4`. These changes predate this documentation task and must remain outside its commits unless the user explicitly includes them.
- `.gitmodules` uses section names `backend` and `frontend` with paths `gatekeeper-backend` and `gatekeeper-frontend`. Root local `.git/config` instead registers `submodule.gatekeeper-backend` and `submodule.gatekeeper-frontend`.
- `git submodule status --recursive` shows `-` on both paths despite populated child directories containing their own `.git` directories. This is evidence of missing registration under the declared names, not evidence that application sources are absent.

This is a dated local snapshot. Re-run status/config checks before acting; do not treat the initial dirty state as permanent. The current dev/feature/main policy below is an explicit later user decision, not an inference from that initial snapshot.

## Current branch and GitHub policy

The user explicitly requested GitHub operations through gh CLI, new feature work from updated dev, feat-to-dev-to-main promotion, GitHub Releases as part of deployment commands, and a return to updated local dev afterward. Root AGENTS.md sections 4–6 are authoritative; [the release runbook](../../docs/github-release-workflow.md) defines the steps.

- New branches use `feat/<topic>` from `origin/dev`; existing in-progress `codex/*` branches and unrelated local work are preserved.
- Use gh for GitHub metadata/PRs/issues/checks/Releases, git for local history and transport. Use explicit repository selection, including explicit repo endpoints for gh api.
- Feature PRs target dev. Deployment promotes verified dev to main through an ancestry-preserving PR merge, then publishes an app-version Release targeting the exact verified main SHA. Required checks/reviews cannot be bypassed.
- Whole-project deployment includes the root composition Release after child Releases and final root main gitlinks are verified. Root has no npm package/version. App-scoped deployment does not require unrelated app or root Releases.
- After release publication, classify remote ancestry and tree differences. Prefer a protection-compliant, non-forced dev ref fast-forward to verified main when dev is its ancestor; use a main-to-dev PR only when required by protection or divergence. If main is already included, do not repeat synchronization to clear an ahead badge. Follow AGENTS.md and the release runbook for exact checks. Root release pins remain main SHAs; local child dev SHAs can intentionally differ and must be reported rather than silently staged.
- Creating these instructions did not perform deployment, branch creation, PR merges, or release publication. Actual remote branch/protection settings must be checked at execution time.

## Handling the mismatch safely

Publication update (2026-10-23): after both child working trees were committed and
published, local `submodule.backend` and `submodule.frontend` URL/active settings
were added to match `.gitmodules`. Existing path-named settings and standalone child
Git directories were preserved. `git submodule status --recursive` now recognizes
both children. This local fix does not establish production server registration.

The documentation task does not repair local Git configuration. Before a future repair, inventory each child's uncommitted changes, local branches, remotes, and Git directory, and compare the root index's `160000` entries with `.gitmodules` and local configuration.

Choose the intended canonical names with evidence. Do not rename versioned sections or remove local directories merely to silence status output. After protecting existing work and confirming path/URL ownership, initialize missing registrations and synchronize URLs as appropriate. Recheck child HEADs and diffs. `git submodule sync` alone does not initialize missing registrations, and `--remote` advances pins rather than reproducing them.

## Publication order

The full gate is in root AGENTS.md sections 4–6. The dependency chain is:

```text
External library release, only if needed and separately authorized
  -> app dependency update + app version + npm i + npm ci + checks
  -> app feature commit/push -> feature-to-dev PR -> dev-to-main deployment PR
  -> final app main SHA verification -> app GitHub Release
  -> root gitlink/memory feature commit/push with --recurse-submodules=check
  -> root feature-to-dev PR -> dev-to-main deployment PR -> root composition Release
  -> ancestry-based main-to-dev synchronization -> local updated dev + dependency refresh
```

Today FlowAuth is an external npm dependency, so its package version is the shared dependency reference. A new backend/frontend version does not publish FlowAuth. A root commit cannot include uncommitted child files; it records only the child's HEAD.

For release pins, fetch and verify the final main SHA is reachable on the intended child remote. If a feature branch was squash-merged, the old feature SHA is not the main release SHA. Record final main in the root and target its app Release/tag at that same SHA. Normal development can stop at dev integration without a Release; app-scoped deployment publishes only its requested release scope.

Avoid pointer-only churn caused by switching child branches. Inspect staged gitlinks with `git diff --cached --submodule=log` and `git ls-files --stage`; after committing compare `git ls-tree HEAD gatekeeper-backend gatekeeper-frontend` with the intended child SHAs. A clean child status does not prove its commit was pushed.

## Helper script caveat

`submodule_util.sh update` invokes `git submodule update --init --recursive --remote`. Its message says reset, but its actual behavior is a remote-tracking submodule update; it is not a safe cleanup command.

`submodule_util.sh branch <name>` fetches, checks out, pulls each available branch, and stages application paths at root. Inspect its branch handling and resulting diffs before use. Never invoke it just to clear a status warning.

## History-only synchronization commits

Verified 2026-10-23: backend dev `1e66b0c` (PR #49) and frontend dev `f9460c6`
(PR #50) are each one commit ahead of main with identical trees. Each extra commit
is the main-to-dev PR merge itself, not an unpublished application change. Root dev
is six commits ahead at `c8098ec`, including real operations/memory changes; it must
not be classified as history-only. See [the investigation](../06-git-sync-guidelines/findings.md).
The updated lifecycle avoids creating the reverse merge when a permitted ref
fast-forward is sufficient. Existing published ancestry is retained.
