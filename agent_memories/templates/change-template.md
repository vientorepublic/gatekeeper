# Change: Descriptive Outcome

- Kind: plan / implementation handoff
- Status: draft | active | blocked | resolved | superseded
- Stage: scoping | ready | implementing | verifying | verified-local | published | released | deployed
- Outcome: pending | completed | cancelled
- Created / last verified: YYYY-MM-DD
- Type: addition | modification | removal | refactor
- Scope: repositories and components
- Baseline: branch/HEAD, integration base, existing changes to preserve
- Branch lifecycle: current origin/dev baseline, feat/<topic>, promotion scope
- Related: issue, existing topic, or canonical notes

Use [the feature workflow](../../docs/development-workflow.md). Choose one value per field; remove unused prompts. Keep paths relative to the meta root. Stages describe implementation progress; Status describes the record. A local-only request can finish at verified-local with Status resolved. Record blocked checks honestly; do not promote a blocked verification to verified-local.

## Objective and boundaries

- User/problem and current behavior:
- Target behavior:
- Included / excluded scope:
- Reversible assumptions / decisions requiring clarification:

## Acceptance criteria

Use concrete conditions and observable results. Include relevant denial/error paths.

- AC-1: Given ..., when ..., then ...
- AC-2: Given ..., when ..., then ...

## Impact and compatibility

- Backend entry points, DTOs, services, persistence/migrations, cache/lifecycle:
- Frontend routes, API helpers/decoders/types, state, UI/accessibility:
- Consumers and search evidence, including unknown external consumers:
- Before/after HTTP, auth, configuration, storage, and data contracts:
- Data retention and migration / recovery plan, or reason not applicable:
- Version level per affected app and rationale (AGENTS.md section 4):
- Mixed-version behavior and rollout/removal order, or reason not applicable:

## Implementation sequence

1. Contract and regression/reproduction evidence.
2. Provider/data changes, if applicable.
3. Consumer/UI changes, if applicable.
4. Tests, obsolete references, documentation, and final review.

For removals, identify retained shared code/data and evidence that retired entry points are unavailable. For refactors, state the behavior that must remain unchanged and the measurable structural improvement.

## Verification evidence

For each criterion, record: criterion ID; check; working directory/environment; result (`pass`, `fail`, `blocked`, `not-run`, `not-applicable`); evidence; limitations. Describe the source/package state tested and any relevant edits after the check. Do not include credentials or raw key material.

- AC-1:
- AC-2:
- Required app commands / install-lockfile gate:
- Integration/browser/dependency checks or justified exclusions:
- Final diff, documentation links, and language checks:

## Publication and completion

- Current outcome and unmet criteria / blocked checks:
- Quality impact and supporting evidence:
- App versions; committed/pushed/merged SHAs, only when actually available:
- GitHub operations via gh; feature-to-dev and dev-to-main PR URLs/checks/merge SHAs:
- Release tag/version/verified main SHA/URL per requested repository:
- Root gitlink state; deployment environment/commit, only if verified:
- Main-to-dev synchronization PRs and local dev == origin/dev confirmation:
- Returned-dev dependency installation state; expected child-dev/root-pin differences:
- Canonical notes and index updated:
- Remaining work with repository/files, next action, and resume condition:
