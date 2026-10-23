# Submodule README Reorganization

- Kind: plan / implementation handoff
- Status: resolved
- Stage: published
- Outcome: completed
- Created / last verified: 2026-10-23
- Type: refactor (documentation only)
- Scope: backend/frontend READMEs and local detail documents; root memory index
- Baseline: existing unpublished changes on codex/dependency-security-refresh in root and both apps; backend HEAD 8a23d1831ee5d6c79bcf28c59e550eeddbe22ffd, frontend HEAD c70749cc1ea66367d3cc5a0f4b4d21196eb465a6
- Branch lifecycle: existing branch and dirty work preserved; no branch creation or publication requested
- Related: [architecture](../repo/project-architecture.md), [feature workflow](../../docs/development-workflow.md)

## Objective and boundaries

Publication update: both app documentation changes shipped with their v1.0.0 Releases;
the original local-only baseline below is historical. See [final publication evidence](../04-backend-ci-deployment/change.md).

Reorganize both submodule READMEs as onboarding/navigation entry points. Preserve useful configuration, routing, API, deployment, and benchmark information in owning app docs. Correct claims against current local source; retain unrelated dependency and implementation work. No runtime, environment example, package version, lockfile, or deployment changes are included.

## Acceptance criteria

- AC-1: Both READMEs expose the same main sequence: setup, environment, behavior, structure, verification, build/run, detail documents.
- AC-2: Long backend configuration/routing/API/operations details and frontend deployment details are linked from their READMEs, with valid repository-local paths and root anchors preserved.
- AC-3: Auth headers, OAuth ownership/callback, active environment settings, npm scripts, and adapter outputs match source/configuration.
- AC-4: Remove duplicate examples, synthetic metrics payloads, historical dependency-migration narration, and incidental package-install advice without losing relevant operational contracts.

## Findings and implementation

- Backend README mixed onboarding with exhaustive environment lists, four overlapping route examples, API inventory, auth flow, sample metrics, and benchmark instructions. Split into docs/configuration.md, routing.md, api.md, and operations.md.
- Frontend README described direct browser SDK/session exchange and treated unused PUBLIC_FLOWAUTH_* values as active configuration. Current auth-client.ts calls backend authorize/callback/refresh; only PUBLIC_GATEKEEPER_API_BASE_URL is declared in src/env.ts. Corrected the explanation without deleting environment examples in this documentation task.
- Distinguished management JWT/x-api-key from proxy Bearer API keys. Added omitted refresh/route-guide endpoints, rate-limit settings, and validation boundaries.
- Recorded OAUTH2_AUDIENCE as configured but not consumed by the proxy; OAUTH2_ISSUER is sent as a hint. Described health as a process response rather than infrastructure readiness.
- Frontend docs/deployment.md separates Cloudflare and Node output, repository-root selection, callback/CORS alignment, and verification. Kept the README Cloudflare Pages heading so the root README anchor remains valid.
- Removed one-off dependency override/advisory migration history from onboarding; owning manifests and the existing dependency-refresh memory retain that evidence. Removed the instruction to install Wrangler merely to preview.
- Existing unreleased 0.0.2 app bumps remain untouched. No installation is needed for this documentation-only editing pass; before any future app commit, apply the full AGENTS package gate.

## Verification evidence

- AC-1: shared seven-section README sequence verified programmatically. Backend entry point decreased from 341 to 91 lines; frontend changed from 83 to 87 lines with corrected setup/contracts and navigation.
- AC-2: 20 Markdown documents checked, including 83 local paths/anchors. The root Cloudflare Pages anchor remains valid. Single H1 outside code fences, final newlines, and whitespace passed.
- AC-3: 19 npm-run script references checked against owning manifests; 4 route-map JSON examples parsed successfully. AuthController/JwtAuthGuard/proxy middleware, gateway config, frontend auth-client/env/adapter scripts, Dockerfiles, and Compose were inspected against the narrative.
- AC-4: reviewed README diff and retained details in five app-owned reference files. Both apps passed Prettier checks for README and docs; both app git diff --check commands passed.
- Root guideline scanner passed: 114 files, 113 comments, 132 test titles, no CJK explanatory comments/titles. English wording remains subject to human review.
- Validation is documentation-focused; no app installation, new runtime tests/builds, live OAuth, hosted Pages setting check, or deployment was executed. Application code/manifests/locks were not changed by this task.

## Publication and completion

No commit, push, merge, Release, branch switch, or gitlink update is requested or performed. Local source/configuration is the evidence; hosted Pages settings were not queried. Before publication, complete the package gate against the final combined app state and follow child-before-root promotion order.
