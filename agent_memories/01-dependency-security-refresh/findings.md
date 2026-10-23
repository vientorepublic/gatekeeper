# Dependency and Security Refresh

- Kind: investigation / implementation handoff
- Status: resolved; subsequently published in app v1.0.0 Releases
- Created: 2026-10-23
- Last verified: 2026-10-23
- Scope: both app manifests/lockfiles, Renovate configuration, framework migration compatibility
- Evidence baseline: backend HEAD `8a23d1831ee5d6c79bcf28c59e550eeddbe22ffd`, frontend HEAD `c70749cc1ea66367d3cc5a0f4b4d21196eb465a6`; existing uncommitted FlowAuth updates were retained and incorporated into the user-requested dependency work.
- Branch: `codex/dependency-security-refresh` in root and both children; no commits, pushes, merges, tags, or gitlink changes performed.

## Sources and scope

Publication update: the initial 0.0.2 proposal and local-only status below are historical.
Both apps shipped as 1.0.0 after the existing major bump and final install/check gates;
backend production deployment succeeded. See [publication evidence](../04-backend-ci-deployment/change.md)
for final hashes/SHAs and [frontend follow-up](../05-cloudflare-build-follow-up/findings.md)
for the separately deferred Pages failure. Earlier check results remain dated evidence.

Read the bodies of all 10 open Renovate PRs in each repository and both Dependency Dashboard issues through `gh pr list` / `gh issue list` with explicit `--repo`, JSON output, and a limit of 100. Each repository returned one issue, its open dashboard. Dashboard rate-limited updates were considered along with existing PRs. GitHub objects were read only.

- [Backend Dependency Dashboard](https://github.com/vientorepublic/gatekeeper-backend/issues/3)
- [Frontend Dependency Dashboard](https://github.com/vientorepublic/gatekeeper-frontend/issues/3)
- Backend PRs: #46 Jest; #45 NestJS 12 core/CLI/config/testing; #44 cache-manager integration; #43 TypeORM integration; #42 scheduler; #41 NestJS 11 updates superseded by 12; #40 TypeScript ESLint; #39 ESLint; #38 mysql2; #31 TypeScript 7 deferred.
- Frontend PRs: #47 Node 24 types; #46 ESLint compat; #45 globals; #44 TypeScript ESLint; #43 ESLint; #42 Svelte; #41 SvelteKit 2 updates superseded by 3; #34 TypeScript 7 deferred; #10 Vite 8; #8 Svelte Vite plugin 7.

These PR numbers describe reviewed proposals, not merged PRs. Remote dashboards/PRs remain open and will reconcile only after the resulting work is published through the normal workflow.

Official migration evidence:

- [NestJS 11 to 12 migration](https://github.com/nestjs/docs.nestjs.com/blob/master/content/migration.md)
- [SvelteKit 3 migration](https://github.com/sveltejs/kit/blob/main/documentation/docs/60-appendix/35-migrating-to-sveltekit-3.md)
- [SvelteKit 3.0 release](https://github.com/sveltejs/kit/releases/tag/%40sveltejs%2Fkit%403.0.0)
- npm registry `npm view <package>@latest version peerDependencies engines dependencies --json` for the relevant framework, compiler, cache, test, and vulnerable dependency packages.

## Audit findings and patches

Full local `npm audit --json`, including development dependencies, initially reported backend **3 moderate** and frontend **4 low + 2 moderate** package entries. These are affected package counts including propagated parent entries, not nine independent advisories.

Backend:

- `autocannon -> hyperid -> uuid` was reported through [GHSA-w5hq-g745-h8pq](https://github.com/advisories/GHSA-w5hq-g745-h8pq), affecting `uuid <11.1.1`.
- Autocannon's latest version still requested vulnerable hyperid 3.x. A scoped `overrides.autocannon.hyperid = "^4.0.0"` replaces it with the CommonJS-compatible hyperid release that uses Node crypto instead of the vulnerable uuid dependency.
- Do not accept audit's suggested downgrade of autocannon to 2.0.1 as a compatible security fix.

Frontend:

- `cookie 0.6.0` propagated through SvelteKit and both adapters, as reported by [GHSA-pxg6-pf52-xh8x](https://github.com/advisories/GHSA-pxg6-pf52-xh8x). Updating SvelteKit and adapters together resolves this through upstream cookie 2.x.
- Typography pinned `postcss-selector-parser 6.0.10`, reported by [GHSA-rj75-hqrm-r3gf](https://github.com/advisories/GHSA-rj75-hqrm-r3gf). A scoped `overrides["@tailwindcss/typography"]["postcss-selector-parser"] = "^7.1.7"` uses the patched parser; both CSS builds pass.
- Recheck and remove these overrides once upstream manifests adopt patched dependencies. Revalidate the autocannon ID behavior and typography CSS output when removing them.

After the final installation, full audit and `npm audit --omit=dev --json` both report **0 vulnerabilities in both applications**. This is the registry advisory result at the verification date, not a complete application security audit or a guarantee against future disclosures.

## Version and dependency decisions

Both app versions become `0.0.2`: application endpoints, token contracts, and intended UI behavior are preserved; framework major upgrades are internal compatibility work. The root has no package version.

- Backend: NestJS core/platform/testing 12.2.0; CLI/schematics 12.0.10; config/cache-manager integration 12.0.1; schedule/TypeORM integration 12.0.2; throttler 6.7.1; Keyv and Redis adapter 6.1.0; TypeORM 1.1.2; mysql2 3.24.6; Jest 30.5.2; ts-jest 29.4.15.
- Frontend: SvelteKit 3.1.0; Cloudflare adapter 8.0.1; Node adapter 6.0.0; Vite 8.3.5; Svelte Vite plugin 7.3.1; Svelte 5.57.2; svelte-check 4.7.7.
- Compatible lint/formatter/type packages and dashboard-listed same-major updates were also installed. Existing FlowAuth `^4.3.4` remains in both apps.
- TypeScript stays at 6.0.3: TypeScript ESLint requires `<6.1.0`, ts-jest requires `<7`, and SvelteKit/svelte-check currently require TypeScript 6-compatible ranges. TypeScript 7 PRs must remain deferred until the toolchain supports them.
- Node type definitions stay at 24.19.2 to match the documented Node 24 runtime. The latest Node 26 types are intentionally not adopted.
- Final `npm outdated --json` shows only those intentionally held TypeScript/Node major lines.
- Both Renovate configs use `baseBranchPatterns: ["dev"]` instead of the deprecated `baseBranches`, addressing the dashboard configuration migration notice without changing the target branch.

## Compatibility changes

Backend package test scripts now invoke Jest with `node --experimental-vm-modules`; native Node `require(esm)` alone did not make ESM-only NestJS 12 packages load inside Jest's VM. The application's NodeNext/CommonJS compilation remains unchanged.

Frontend:

- Move SvelteKit options from the removed `svelte.config.js` into `svelte-options.js`, passed through `vite.config.ts` and read by the ESLint parser.
- Replace `$lib` with native `#lib` subpath imports and explicit `.js`/`.svelte` extensions; replace `$app/environment` with `$app/env`.
- Extend `$app/tsconfig` with explicit includes/excludes.
- Declare the runtime public API URL in `src/env.ts` and import it from `$app/env/public`. The fallback remains `http://localhost:3000`. The old `$env/dynamic/public` import produced missing types and undefined-value build warnings after the framework upgrade, so a build exit code alone was insufficient validation.
- Type props on the destructuring assignment rather than using unsupported `$props<Type>()` generics; preserve handlers and defaults.
- `scripts/prepare.mjs` runs synchronization and propagates errors when SvelteKit is installed, and skips it only when a production install omits that development dependency. The previous blanket `|| echo ''` masked actual sync failures.
- Docker's dependency layer copies the helper, Vite/Svelte/TypeScript configuration, environment schema, and app template before `npm ci`. The production layer copies the helper before `npm ci --omit=dev`.

## Executed verification

Toolchain: Node **24.22.1**, npm **11.13.0**. Node was installed under `/tmp/gatekeeper-validation-runtime`, leaving the system default unchanged. Node 24.14.1 was insufficient for the updated Nest schematics development engine; the final install and checks use the newer runtime.

- Both apps: final `npm i` followed by `npm ci` succeeded. Manifest, lockfile, and lockfile root package versions are `0.0.2`.
- Backend lock SHA-256: `8ad7802b9580b2992b0dd172c4731a0c1346fdabf8ae2f34a71483e0fc9f98d8`.
- Frontend lock SHA-256: `83d262de4f2aebdf5285ec907576363d15199213b736a96dceefcb17d4eddfbc`.
- Each hash remained identical before/after `npm ci`.
- Backend: lint, `npx tsc --noEmit --incremental false`, build, **36 unit tests**, and **46 integration tests** passed using the package scripts.
- Frontend: lint and Svelte check passed with **0 errors and 0 warnings**; Cloudflare and Node builds passed without the earlier undefined-environment warnings.
- Actual isolated Redis smoke passed: cache set/get/delete/TTL, atomic rate counter, circuit state round-trip/delete, and module lifecycle. It used a temporary loopback Redis process with persistence disabled, then stopped it.
- Autocannon smoke passed: **20 unique substituted request IDs**, no request errors or non-2xx responses, using hyperid 4.
- Typography's actual Tailwind compiler emitted `prose`, `prose-lg`, `prose-invert`, and nested selector styles with parser 7, verifying the override beyond an unused-plugin build.
- Proxy benchmark smoke passed with `BENCH_DURATION_SECONDS=1 BENCH_CONNECTIONS=2 BENCH_PAYLOAD_BYTES=1024`: optimized/legacy GET and POST completed with zero errors/timeouts. This short run validates compatibility; it is not a performance claim.
- Node frontend HTTP smoke passed for `/` and `/dashboard`: 200 SSR, CSS assets, and a non-default runtime public API URL serialized into HTML. Unknown routes returned 404. The temporary server was stopped.
- Docker dependency-layer file layout: isolated `npm ci` passed with the exact configuration/template/helper copies used by the Dockerfile. Production-layer `npm ci --omit=dev` passed without SvelteKit installed. Both left lock checksums unchanged. A deliberately broken temporary Vite configuration correctly made `prepare` fail instead of swallowing the error.
- Backend `npm ls --all --json` found no dependency problems. Frontend has no invalid/missing peers; npm reports the framework-generated `node_modules/$app` directory as extraneous. That directory contains generated types and must not be removed to hide the diagnostic.
- Final root and child `git diff --check` passed. Local documentation links and unchanged root gitlink SHAs were reviewed.

## Limits and handoff

No full Docker image build, production MariaDB integration, hosted Cloudflare deployment, or live external FlowAuth login/browser session was executed. Existing root documentation work remains uncommitted. The initial submodule registration mismatch was not repaired by dependency work.

Before publishing: inspect the final child diffs, commit/push the children through their review workflow, then update root pointers to remotely reachable final child SHAs. Never advance root gitlinks to represent these still-uncommitted child working trees. Renovate PR merging/closing was not part of this task.
