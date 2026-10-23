# Gatekeeper — Shared Agent Guidelines

These instructions apply to the root repository and work performed in its child repositories. Read this file before editing. Follow explicit user instructions and applicable, more specific `AGENTS.md` files; report conflicts instead of silently inventing exceptions.

## 1. Project and repository boundaries

Gatekeeper provides namespace-based API gateway routing, FlowAuth OAuth2 login, internal JWT sessions, and namespace-scoped API key management.

- The root is a Git meta repository for orchestration, documentation, shared agent memory, and exact application commit pointers. It has no `package.json`, npm workspace, or root Node.js package version.
- `gatekeeper-backend/` is a separate Git repository recorded as a submodule: NestJS 12, TypeScript, Express, TypeORM/MariaDB, Redis/Keyv 6 cache, scheduled metrics, and Jest.
- `gatekeeper-frontend/` is a separate Git repository recorded as a submodule: SvelteKit 3, Svelte 5, Vite 8, TypeScript, Tailwind CSS 4, and Cloudflare/Node adapters.
- Both apps consume the external npm package `flowauth-oauth2-client`. It is not a local shared-code submodule. Do not invent a `shared/` repository or pointer.
- Node.js 24 is used by the application Dockerfiles and documented frontend deployment; use 24.15+ for the NestJS development toolchain. TypeScript remains 6.x until the lint/test/Svelte tools support 7.x. Run npm commands in the affected app directory, using a consistent Node/npm toolchain.
- `docker-compose.yml` defines both apps, MariaDB, Redis, persistent volumes, and an external gateway network. `submodule_util.sh` changes submodule state; inspect it before use.

Primary source locations:

```text
gatekeeper-backend/src/
  main.ts, app.module.ts       Bootstrap, validation, filters, module wiring
  config/                     Environment configuration and route-map loading
  modules/auth/               OAuth2, sessions, JWT guard, users, API keys, DTOs
  modules/gateway/            Route registry, streaming proxy, circuit state
  modules/health/, modules/cron/  Metrics, health, scheduled collection
  database/, migrations/      TypeORM connection and schema migrations
  cache/, common/             Cache, types, filters, middleware, lifecycle
gatekeeper-backend/test/       Gateway integration tests and proxy benchmark
gatekeeper-frontend/src/
  routes/                     Login page, dashboard, layout, global stylesheet
  lib/auth/auth-client.ts      Auth store, callback, token refresh, API requests
  lib/api/                     HTTP parsing, runtime decoders, API contracts/requests
  lib/components/             Navigation, common modals, dashboard panels
agent_memories/                Shared, versioned context for all agents
```

Read each app's `README.md` and actual configuration before changing its behavior. The initial architecture evidence is in [project-architecture.md](agent_memories/repo/project-architecture.md).

## 2. Required session workflow

1. Read [the memory index](agent_memories/README.md), relevant `repo/` notes, and active topic notes before non-trivial work.
2. Inspect root and affected child Git status, branches, diffs, remotes, and pointers. Identify existing user changes before editing. Never reset, stash, commit, or overwrite unrelated work.
3. Check applicable nested instructions. A standalone app checkout does not automatically receive this root file or its memory: explicitly locate/read the parent meta checkout when available. If absent, report the context gap; do not claim shared memory was loaded.
4. Follow [the feature change workflow](docs/development-workflow.md) for additions, modifications, removals, and refactors: define observable acceptance criteria, trace affected contracts/consumers, implement in dependency order, and verify the final state. Use [the change template](agent_memories/templates/change-template.md) for non-trivial work; small local edits can record the same essentials in the task response.
5. Before committing or pushing, follow sections 4–6. Finish by reporting changed repositories, checks actually run, failures/omissions, and any unresolved pointer or release work.

Memory is repository content, not automatic live synchronization. Other agents receive updates through a shared worktree or normal Git synchronization. Read again after relevant updates; never assume another agent's private chat is shared memory.

## 3. TypeScript, framework, and comment conventions

### General TypeScript

- Existing ESLint, Prettier, and TypeScript configuration is authoritative for formatting and compilation. Do not weaken rules or change compiler/module settings to conceal errors.
- Use `const` by default, `let` for reassignment, strict equality, explicit control flow, and small functions with clear responsibilities. Avoid `var`, mutable global state, and unrelated abstractions.
- Use camelCase for variables/functions, PascalCase for classes/types/interfaces, and UPPER_SNAKE_CASE for true shared constants. Do not add `I` prefixes to interfaces. Preserve established filenames and public names.
- Prefer explicit types at exported APIs and domain boundaries, inferred types for obvious locals, `unknown` plus narrowing for untrusted data, and discriminated unions for state. Avoid new `any`, unsafe casts, non-null assertions, and ignored type errors unless a documented interop constraint requires them.
- Use `import`/`export` syntax and type-only imports where compatible. NestJS decorator-injected class tokens need runtime imports; do not erase them with `import type`. Do not replace NestJS imports with `require` merely because emitted code is CommonJS.
- Await or deliberately handle promises; handle errors with context and preserve their causes. Avoid empty catch blocks, fire-and-forget failures, and logging tokens or sensitive payloads.
- Validate external inputs at runtime. TypeScript types and generic `fetch` casts do not validate HTTP responses.

### Backend

- Preserve the current NodeNext module resolution, ES2023 target, decorator metadata, and `strictNullChecks`. Some other strict checks are currently disabled; new code should still be safely typed.
- Prettier: two-space indentation, single quotes, trailing commas. Follow `{feature}.module.ts`, `.service.ts`, `.controller.ts`, `.entity.ts`, DTO directories, and `.spec.ts` conventions.
- Keep controllers thin, behavior in injectable services, and persistence in repositories. Use NestJS DI, DTO validation, framework exceptions, and the shared problem-details filter.
- Add new schema changes as timestamped migrations and register them in `src/database/database.module.ts` as required by its explicit migration list. Do not rewrite applied migrations or enable production schema synchronization.
- Keep proxy handling bounded and streaming; preserve timeout, body-size, abort, circuit-breaker, CORS, metrics, and graceful-shutdown behavior.

### Frontend

- Prettier: tabs, single quotes, no trailing commas, width 100; use the configured Svelte/Tailwind plugins. Keep existing kebab-case component filenames.
- Preserve strict TypeScript and SvelteKit route filenames. Use Svelte 5 runes in components; existing `svelte/store` auth state remains valid. Prefer derived state over unnecessary effects.
- Use `#lib` subpath imports with explicit `.js`/`.svelte` extensions and shared API/auth helpers. SvelteKit options are in `svelte-options.js`, passed through `vite.config.ts`; TypeScript extends `$app/tsconfig`. Guard browser-only APIs from SSR. Keep secrets out of `PUBLIC_*` variables and client bundles.
- Keep semantic HTML, keyboard navigation, labels, focus behavior, and loading/error/empty states accessible. Preserve existing user-facing language.
- `npm run build` targets Cloudflare; `npm run build:node` targets Node/Docker. Verify the adapter relevant to the change, both when shared runtime/configuration changes.

### Comments and language

- **All source comments and docstrings must be English. The only non-English exception is a proper noun in its original spelling.** This covers TypeScript/JavaScript, JSDoc, Svelte/HTML, CSS, JSONC, YAML, shell, configuration examples, and generated source comments added by an agent.
- Quoting ordinary Korean text does not create an exception. Describe a UI label or fixture through its English identifier instead of copying non-English prose into a comment.
- Explain reasons, constraints, units, invariants, and surprising behavior. Avoid comments that restate code, stale commented-out code, decorative banners, and mandatory JSDoc on trivial functions.
- Use JSDoc for non-obvious exported contracts, side effects, failure modes, and security assumptions. `TODO`/`FIXME` must state the actionable issue and link an issue or memory when available.
- Identifiers, test titles (`describe`/`it`/`test`), commit subjects, and new technical memory notes are English. User-facing copy, fixtures, and documentation written for Korean readers can remain Korean; they are not source comments.

```typescript
// Refresh before expiry to allow for network latency and clock skew.
const refreshLeadTimeMs = 60_000;
```

## 4. Version policy

Each app owns its own `package.json` version. Version only the affected package; do not force backend/frontend versions to match. Compare with the latest integration-branch version and existing release tags before choosing a free version.

- **Major (`X.0.0`)**: incompatible public API, auth/token contract, route semantics, configuration, or supported-runtime changes requiring consumer action. Include a migration/rollout plan. A dependency major alone does not require an application major if application compatibility is preserved.
- **Minor (`x.Y.0`)**: backward-compatible features, endpoints, optional fields/configuration, and new supported capabilities.
- **Patch (`x.y.Z`)**: compatible bug/security fixes, dependency updates, performance work, internal refactors, and package-local maintenance/docs/tests with no new public capability.
- Reset lower components when bumping major/minor. Use the highest required level in a combined change. Although both apps initially declare `0.0.1`, apply this explicit compatibility policy even before 1.0; do not hide breaking changes in a patch.
- Every commit changing an app package must include an appropriate bump unless that logical change already contains an unreleased bump sufficient against the integration base. Reuse that bump during review fixes; rebase/reconcile if another release consumed it. Do not bump again merely to push the same commit.
- Root-only docs, memory, orchestration, and gitlink commits do not bump untouched apps. There is no root package version; do not create a dummy `package.json` for this purpose.
- A user deployment command includes the version/lockfile gates, commits/pushes, `feat/* -> dev -> main` PR merges, GitHub Release publication, and return-to-dev synchronization for its stated scope. Follow [the release workflow](docs/github-release-workflow.md); do not ask for separate routine authorization for these included steps. A feature implementation or version bump alone does not authorize publication/deployment.
- App tags/releases target the final verified `main` commit and match its package version. The root has no package version; a project-wide deployment also publishes a root composition release identifying exact app SHAs/versions. npm package publication remains a separate action for this project.

## 5. Mandatory package and lockfile gate

Before committing an affected app, complete this sequence **inside that app repository**:

1. Review pre-existing manifest/lock changes and select the correct application version. Update `package.json` manually or use `npm version <major|minor|patch> --no-git-tag-version` when appropriate; this must not create an implicit Git commit/tag.
2. Run **`npm i`** after the final package version/dependency changes. Review the complete `package.json` and `package-lock.json` diff; include intended resolution changes together. Do not hand-edit dependency resolutions, delete the lockfile, or substitute `--package-lock-only` for installation.
3. Record the lockfile checksum, then run **`npm ci`**. It must succeed with normal development dependencies. Confirm the checksum is unchanged, the manifest and lockfile root versions match, and the resolved dependency diff is intentional. `npm ci` replaces `node_modules`; coordinate if another process uses it.
4. Run the affected checks below against the clean installation. Review any formatter/linter mutations, then stage the manifest and lockfile with the implementation.
5. Inspect the staged diff and run `git diff --cached --check`. Commit only intended files. No lockfile changes remaining outside the commit may be required for it to install.

Before **each push**, verify the committed versions and lockfiles include the final changes and that the gate passed for that exact package state/toolchain. If a rebase, merge, dependency edit, or version edit changed it, repeat `npm i`, `npm ci`, and affected checks. An unchanged, already verified commit needs no artificial extra bump.

Do not use `--force`, `--legacy-peer-deps`, disabled lifecycle scripts, or weakened checks to disguise incompatibility. Record installation failures and stop the commit/push gate until resolved. If the environment prevents a required check, explicitly report it as blocked, never as passed.

## 6. Git, shared dependencies, and pointer order

### Preflight and ownership

- Inspect `git status --short --branch`, `git diff`, `git diff --cached`, and `git submodule status --recursive` at root; inspect status, HEAD, and remotes in every affected child.
- Compare `.gitmodules`, local `submodule.*` configuration, and `git ls-files --stage`. A `160000` entry is a gitlink. `.gitmodules` section names and `path` values are distinct; do not assume they match.
- A leading `-` in submodule status means uninitialized/unregistered state, `+` means a different checked-out commit, and `U` means conflicts. Inspect existing directories and work before initialization or repair. See [repository-workflow.md](agent_memories/repo/repository-workflow.md) for the initial registration mismatch.
- Start new work from an up-to-date local `dev` tracking `origin/dev`, then create `feat/<topic>` in each affected repository. The user's `feat/` convention overrides the default agent branch prefix. Preserve existing in-progress branches/dirty work; do not rename or switch them just to enforce a new convention. Merge through `feat/* -> dev -> main`; ordinary development can stop before promotion to main, while deployment includes both merges. Do not commit directly to shared `main`/`dev`, delete shared branches, force-push them, or reset existing work. Honor configured signing requirements without disabling them.
- Detached HEAD is normal for a pinned submodule checkout. Create a branch before new commits; do not move an intentional pin just to make all branch names equal.
- Use scoped Conventional Commits, e.g. `fix(auth): preserve refresh errors`, `docs(agents): add shared memory rules`, `chore(submodules): pin verified app revisions`.

### GitHub operations and branch lifecycle

- Use `gh` CLI for GitHub PRs, issues, Renovate dashboards, checks/Actions, remote repository metadata, and Releases. Use `gh api` for missing CLI surfaces. Local commits/branches/diffs, fetch/pull/push, and gitlink operations use `git`; do not replace GitHub operations with browser automation or direct HTTP calls. Verify `gh auth status`; use explicit `--repo OWNER/REPO` where supported and explicit `repos/OWNER/REPO/...` endpoints (or explicit GraphQL repository variables) for `gh api`.
- Use `gh pr create/view/checks/merge` for both promotion PRs. Inspect the complete `dev -> main` diff: it may contain other integrated work. Resolve out-of-scope changes before release rather than silently publishing them. Required reviews/checks and merge queues remain mandatory; do not use `--admin` or disable protections. A queued/auto-merge request is not a completed merge.
- Preserve ancestry for `dev -> main` and subsequent `main -> dev` synchronization with merge commits, or an equivalent policy that demonstrably preserves ancestry. Squash is allowed for feature-to-dev if repository policy permits. If repository settings prohibit the required promotion strategy, report that blocker rather than bypassing protection or repeatedly squash-merging shared branches.
- After publication, synchronize main back into dev through a `gh` PR when needed, verify the merge, then return affected local repositories to `dev`, fetch, and fast-forward from `origin/dev`. Refresh installed app dependencies when the returned package state differs. Never reset divergent branches or use a routine stash. Record remaining dirty state and exact root pins versus intentionally checked-out child dev SHAs.
- Missing remote `dev` must be established from verified `origin/main` during an authorized branch/publication operation, using `gh api` for the remote ref, only after inspecting existing histories. Missing `main`, unrelated histories, protected-branch failures, or unrelated dirty work require resolution; do not invent an integration branch or discard work.

### Required dependency-first sequence

1. **Shared library, when actually changed:** commit/test/version/release the library in its owning repository first. Confirm its immutable commit or npm version is remotely available. This repository currently consumes FlowAuth through npm; modifying that dependency here does not authorize publishing its upstream package.
2. **Consuming apps:** update dependency ranges and locks only after the upstream artifact exists. Implement contract changes, bump each affected app, and complete section 5. Commit separately in each owning app repository.
3. **Push children first:** push app feature branches to their own remotes and merge feature PRs into dev. For deployment, merge verified dev into main via `gh`, fetch and validate the final main tree, and publish each affected app's GitHub Release against that exact main SHA. A feature squash changes the commit ID: record final main SHAs, not discarded feature SHAs.
4. **Verify availability:** confirm each chosen child SHA exists on its intended remote branch/tag, not merely as a local object or disposable branch tip. For example, after fetching, use `git merge-base --is-ancestor <sha> origin/<integration-branch>` for branch reachability. Unrelated dirty child changes must remain untouched and must not be claimed as committed.
5. **Commit parent last:** at root, stage only intended gitlinks (`git add -- gatekeeper-backend` and/or `gatekeeper-frontend`), related docs, and memories. Inspect `git diff --cached --submodule=log` and staged `160000` SHAs. Commit only after all referenced child commits are available remotely. Root commits must never reference unpublished local commits.
6. **Push parent last:** push the root feature with `git push --recurse-submodules=check` after explicit remote verification, then merge root feature into dev. For deployment, promote root dev into main via `gh`, verify final gitlinks, and publish the root composition Release for a project-wide deployment. Verify the committed tree with `git ls-tree <final-main-sha> gatekeeper-backend gatekeeper-frontend`. A recursive push check supplements remote checks; it does not repair registration or publish dependencies for you.
7. **Return to development:** only after recording immutable release SHAs/URLs, complete main-to-dev synchronization and local refresh in children and root as described above. Root release pins remain the app main SHAs even if local child dev checkouts later differ.

For nested/shared-code submodules introduced later, apply the same order recursively: deepest dependency commit/push, consuming child pointer commit/push, then root pointer commit/push. For coordinated deployments, roll out a compatible backend before frontend consumers; use expand/migrate/contract for incompatible changes. Verify actual deployment triggers before claiming a merge deploys anything.

Never run `git submodule update --remote`, `submodule_util.sh update`, or `submodule_util.sh branch ...` as routine synchronization. The helper can advance/checkout/pull and stage pointers. After confirming registration and a safe working tree, use `git submodule update --init --recursive` to reproduce recorded pins; use `git submodule sync --recursive` only for understood URL/config changes. Neither is a repair strategy for unexplained dirty state.

## 7. Verification and security

Commands run in the relevant app after section 5:

```bash
# Backend
npm run lint
npx tsc --noEmit --incremental false
npm run build
npm test -- --runInBand
npm run test:e2e
```

Backend lint uses `--fix`; inspect its diff. Run `npm run bench:proxy` for proxy performance/streaming changes, recording comparable conditions. Integration tests exercise local upstream servers and mocked services; production MariaDB/Redis integration must be checked separately when relevant.

```bash
# Frontend
npm run lint
npm run check
npm test
npm run build
npm run build:node
```

Frontend `npm test` runs Vitest unit tests for response boundaries and authentication state; `vitest.config.ts` supplies isolated browser/environment fixtures. It is not a browser test suite. Validate relevant login, callback, refresh, API key issue/list/revoke, pagination, keyboard/focus, and error flows using a suitable local setup when changing them. Add regression tests for meaningful behavior changes, especially authorization and proxy edge cases. Update mocks when service contracts change.

From the root, run `node tools/check-agent-guidelines.mjs` to scan source comments and test titles; `--inventory` lists covered files. It requires the backend's installed TypeScript parser. The scanner catches CJK prose, while English wording and proper-noun exceptions still need human review.

Root-only documentation changes need link/path review and `git diff --check`; do not run npm installations or bump app versions merely to edit these documents. Compose changes need configuration validation with the required local env files/network available. Do not start, migrate, or tear down production services as a documentation check.

- Preserve namespace/owner checks, JWT verification, API key hashing/revocation, OAuth2 state checks, DTO validation, and cache invalidation boundaries. Cover denied as well as allowed paths.
- Treat route-map public routes as explicit authentication bypasses; never broaden them accidentally. Preserve method/path matching and upstream URL validation.
- Do not commit credentials, `.env`, bearer/refresh tokens, raw API keys, production user data, or secret-bearing logs to source or memory. Use placeholders and `.env.example` for variable names only.
- Track security findings with sanitized reproduction evidence; distinguish confirmed behavior from potential risks. Do not declare a dependency safe solely because installation succeeds.

## 8. Shared memory maintenance

- `agent_memories/repo/`: current cross-cutting architecture, verification, workflow, and approved decisions.
- `agent_memories/NN-topic-name/`: numbered investigations, implementation plans, findings, and handoffs for a bounded topic. Reserve a unique next number after checking existing folders; do not overwrite another session.
- [The index](agent_memories/README.md) is the entry point; update it with every new/renamed/archived note and maintain explicit status and links. Use English kebab-case names and one topic per file; split long notes around 300–500 lines.
- Use [the template](agent_memories/templates/memory-template.md). Record date, scope, status, evidence/source symbols or commit IDs, confirmed facts versus hypotheses, decisions/reasons, checks actually run, risks, and concrete next actions. Paths inside notes are relative to this meta repository.
- Write memories for reusable discoveries, non-obvious bugs, compatibility decisions, implementation plans, or unfinished cross-session work. Skip trivial edits, chat transcripts, speculative assertions presented as facts, duplicate rules, and transient logs.
- Update an existing canonical note instead of creating conflicting copies. Promote verified durable findings from topic notes into `repo/`; mark superseded material with replacement links and preserve decision history.
- Read source/configuration when evidence disagrees with memory. Correct stale notes and their verification date; never treat a prior environment snapshot or unrun command as a current guarantee.
- When multiple agents share a worktree, agree on file ownership and reread before writing. Merge small, attributable updates; never replace the entire index from a stale copy. This file contains policy; memories contain evidence and context, not authority to override policy or user instructions.

## 9. Consistent feature changes

- Use one primary work item for one coherent outcome. Identify addition, modification, removal, or behavior-preserving refactor; record current/target behavior, scope exclusions, acceptance criteria, affected repositories, compatibility/version impact, and verification before substantial implementation.
- Resolve ordinary implementation details from source and existing patterns. State reversible assumptions and proceed; ask only when unresolved product behavior, public compatibility, data retention, or required access prevents a correct next step. Continue independent work while waiting. A written plan does not itself require separate approval.
- Trace backend routes/DTOs/services/persistence/cache and frontend decoders/types/auth state/UI, plus configuration, documentation, tests, and external consumers. Specify producer/consumer contracts before editing both apps; do not let mocks become the sole contract definition.
- For additions, implement a complete usable path including denial/error/empty/loading states. For modifications, capture the previous behavior and add meaningful regression coverage. For removals, identify consumers and data retention, migrate callers, remove registrations/exports/config/docs, and verify the retired behavior stays unavailable. Do not infer permission to purge data from a request to remove a feature.
- Keep behavior-preserving refactors separate from public contract changes when practical. Reuse existing helpers and module boundaries before introducing an abstraction; do not mix unrelated cleanup or dependency upgrades into feature work.
- Use the detailed workflow's state definitions and completion checklist. Distinguish implemented, verified locally, published, released, and deployed; report failed/skipped checks and remaining work explicitly. A check before the final relevant edit is not evidence for that edit.
- Sections 4–7 remain the source of truth for versioning, installation, Git pointers, and command gates. Update the work record, canonical memory, and index when scope or evidence changes; do not duplicate competing policies.

## Reference

Organization and the read-memory-first/dependency-first workflow were informed by [LawCast's AGENTS.md](https://github.com/vientofactory/LawCast/blob/main/AGENTS.md). Gatekeeper's actual files determine its tools and topology; LawCast-specific scripts, branch assumptions, deployment triggers, and services do not apply here.
