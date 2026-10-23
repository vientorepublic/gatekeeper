# Git Synchronization Without Redundant Merge Commits

- Kind: investigation / workflow decision
- Status: resolved; publication requested
- Created / last verified: 2026-10-23
- Scope: root Git instructions and both application branch histories
- Related: [release runbook](../../docs/github-release-workflow.md), [repository workflow](../repo/repository-workflow.md)

## Objective and acceptance

Explain the content-empty dev commit shown on GitHub and update the Git lifecycle
to avoid unnecessary synchronization commits. Verify ancestry and content separately,
preserve existing changes and published history, and retain protection requirements.
This is a documentation change; no app version/install gate or deployment is needed.

## Verified findings

After fetching all three remotes, main-only/dev-only counts were root `0/6`, backend
`0/1`, frontend `0/1`. Both app trees are identical between main and dev:

- Backend main `7c6fccede657ab7cdac25725a5726e829a6e199c`; dev
  `1e66b0c55c58a656c94ad3a5697e55252712f075` is PR #49's main-to-dev merge.
  Shared tree: `4ccfe875241b0e9020e0d0bc37dd801c38d27900`.
- Frontend main `ec3586823f5d205ee9d8d7b522e077b96721239b`; dev
  `f9460c6d7bd2cb43f765e98dbbf035d710651e57` is PR #50's main-to-dev merge.
  Shared tree: `bffe134dfa6f49aa1cb7ff6dcf3c030d7c0c5f8e`.
- Root dev `c8098ec06c2da6c4522c2c47806fe8bdb5a63efa` contains real documentation
  changes in eight files (186 insertions, 14 deletions) relative to main. Its six
  extra commits cannot all be treated as redundant history.

The previous policy required a reverse synchronization PR. GitHub merge commits
add a new dev tip even when its content exactly matches main. The GitHub badge
counts reachability differences, not file changes. Repeating opposite-direction
merges cannot converge the tips without creating more merge history.

## Decision and verification

Updated AGENTS.md, the release runbook, and canonical workflow notes to classify
identical tips, main already included, dev behind main, and divergent histories.
Prefer a non-forced remote dev fast-forward to verified main only where protections
permit it; otherwise retain the required PR and explain any history-only commit.
Never reset/force-push or deploy solely to clear a badge. Report remote commit
counts and tree diff independently from local tracking status.

Read both app merge parents/subjects, compared full tree IDs and empty app diffs,
and inspected root's non-empty diff. Documentation links and whitespace were
checked locally. The initial instruction-edit request stopped with local changes.
The subsequent explicit user request includes committing/pushing every remaining root
file and the currently checked-out child pointers to make the workspace clean.

The root feature records backend `1e66b0c55c58a656c94ad3a5697e55252712f075` and
frontend `f9460c6d7bd2cb43f765e98dbbf035d710651e57`, both verified reachable from
origin/dev and identical in content to their released main trees. This user-requested
development composition supersedes the usual instruction to leave dev checkout
pointer differences unstaged. Published main/tag/release pins remain unchanged.
No application source, package version, installation, PR merge, release, or deployment
is part of this follow-up. The publication branch is feat/git-sync-guidelines.
