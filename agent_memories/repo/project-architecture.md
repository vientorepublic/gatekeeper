# Project Architecture

- Kind: repository reference
- Status: current
- Last verified: 2026-10-23
- Scope: root, backend, frontend, external FlowAuth integration
- Evidence baseline: deployed root `fec44ad1c060ba810167ad5ddae432e2e98fe20b`, composition `release-20261023.1`; historical initial pins and local changes remain documented in [repository-workflow.md](repository-workflow.md).

## Repository topology

The root tracks orchestration and two `160000` gitlinks. Backend and frontend have independent Git histories, package manifests, and npm lockfiles. There is no root package/workspace, local common-types package, or third shared-code submodule in `.gitmodules`.

Both apps now have published `v1.0.0` Releases: backend main
`7c6fccede657ab7cdac25725a5726e829a6e199c`, frontend main
`ec3586823f5d205ee9d8d7b522e077b96721239b`. Root composition `release-20261023.1`
pins those exact main SHAs. The earlier 0.0.2 proposal was superseded by the
existing major bump for configuration/login/toolchain migration. Backend uses NestJS
12/Keyv 6; frontend uses SvelteKit 3/Vite 8. Both request `flowauth-oauth2-client`
`^4.3.4`; matching dependency ranges alone do not prove app contract compatibility.

## Backend responsibilities

- `gatekeeper-backend/src/main.ts`: preloads remote route maps, creates the Nest/Express app, installs CORS middleware, global DTO validation and problem-details filtering, and enables shutdown hooks.
- `gatekeeper-backend/src/app.module.ts`: config, global throttling, scheduling, database, cache, auth, gateway, health, and cron module composition.
- `gatekeeper-backend/src/modules/auth/`: OAuth2 authorize/callback/session/refresh, local user identity, JWT guard, and namespace/owner-scoped API key operations. API key service hashes generated keys, caches authentication, and tracks usage.
- `gatekeeper-backend/src/modules/gateway/`: registry configuration, public-route decisions, proxy streaming, and circuit state. Read the registry, middleware, utilities, and their tests together before changing routing.
- `gatekeeper-backend/src/config/route-map-loader.ts`, `route-map.config.ts`, and `gateway.config.ts`: remote loading, route normalization/validation, and environment configuration; direct `ROUTE_MAP` takes precedence over `ROUTE_MAP_URL` as documented in the backend README.
- `gatekeeper-backend/src/modules/health/` and `modules/cron/`: health endpoints, gateway/runtime metrics, and scheduled collection.
- `gatekeeper-backend/src/database/database.module.ts`: MariaDB configuration, explicit entity/migration registration, startup migrations, configurable synchronization. The initial migration is in `src/migrations/20260409000000-initial-auth-schema.migration.ts`.
- `gatekeeper-backend/src/cache/cache.module.ts`: cache wiring; consult current configuration for Redis versus memory behavior.

Gateway routes follow `/api/{namespace}/{version}/...`. Direct namespace targets preserve the version prefix; version-map targets strip the namespace/version prefix. Namespace-wide `public` and path/method-level `publicPaths` affect authentication and are security-sensitive contracts.

## Frontend responsibilities

- `gatekeeper-frontend/src/routes/+page.svelte`: login entry; `src/routes/dashboard/+page.svelte`: key-management dashboard.
- `gatekeeper-frontend/src/lib/auth/auth-client.ts`: writable auth store, backend authorization URL/callback exchange, persisted browser session, scheduled/single-flight refresh, and one retry after an API request returns 401. Browser APIs are guarded by SvelteKit's `browser` flag.
- `gatekeeper-frontend/src/lib/api/auth-api.ts`: namespace/route-guide requests and API key list/create/revoke functions. `http-client.ts` requires runtime decoders; `api-decoders.ts`, `api-types.ts`, and `validation.ts` separate schema validation from transport. Auth contracts live in `src/lib/auth/auth-types.ts`.
- `gatekeeper-frontend/src/lib/components/`: top navigation, common modals, and focused dashboard panels.
- `gatekeeper-frontend/src/routes/layout.css`: Tailwind/global stylesheet; `src/routes/+layout.svelte`: shared page head and layout.
- `gatekeeper-frontend/src/env.ts`: declares the dynamic public API base URL using SvelteKit 3's environment schema. `src/lib/auth/auth-client.ts` and the route-guide panel import it from `$app/env/public`.
- `gatekeeper-frontend/svelte-options.js`: adapter and compiler options passed through `vite.config.ts`; `svelte.config.js` was removed for SvelteKit 3. Internal imports now use `#lib` and explicit module extensions.

The auth helper calls backend endpoints directly. The frontend manifest's FlowAuth SDK dependency alone is not evidence that all login behavior is implemented directly in the browser SDK. Prefer the implementation over a simplified README description.

## Cross-app contracts

Coordinate backend DTOs/controller responses with frontend `AuthSessionResponse`, auth state, and `auth-api.ts` types. Sensitive surfaces include OAuth2 `state`, callback URL/parameters, session refresh/token expiry, namespace ownership, key material returned only at issuance, pagination metadata, and problem-details error fields.

Frontend responses and restored users are validated at runtime. Browser callbacks require a one-use matching sessionStorage nonce; session revisions prevent stale refresh/callback completion after logout. Persisted auth state still includes browser localStorage tokens; treat changes here as security-sensitive and never record token values in memory. See [the guideline audit](../02-guideline-compliance-audit/findings.md) for tested boundaries and limits.

## Infrastructure and deployment

- Dockerfiles use Node 24 Alpine, multistage builds, `npm ci`, non-root runners, and a hardened allocator build stage.
- Compose maps loopback ports: backend `10001:3000`, frontend `10002:5173`, database `10003:3306`, Redis `10004:6379`. Its external `gateway_shared_network` must exist for the documented topology.
- Compose loads each app's local `.env`; default database credentials in Compose are development configuration, not production secret guidance.
- `gatekeeper-frontend/svelte-options.js` selects Cloudflare when `ADAPTER=cloudflare`, otherwise Node. `npm run build` selects Cloudflare; Docker uses `npm run build:node`. Cloudflare output is `.svelte-kit/cloudflare` per `wrangler.jsonc` and README.
- Frontend `PUBLIC_*` settings are exposed to browser code. Keep server-only credentials in backend/private settings.

Root `.github/workflows/quality.yml` now defines PR/merge-group checks for the pinned
apps; `deploy-backend.yml` runs the same checks on root main push before a WireGuard/SSH
backend-only Compose rollout. The fifth deployment succeeded at 2026-10-23 17:46 JST,
with image/container/HTTP health verified. The primary server clone `/root/gatekeeper`
has operator gitlink changes and is preserved; deployment uses an exact-SHA clone in
`/root/.gatekeeper-releases`, existing env symlinks, and the existing Compose project.
Root fetch uses the short-lived CI token without recursive fetch; each private app
checkout uses its own read-only deploy key. Server-side backend fetch credentials are
temporary and removed before Docker. GitHub returned HTTP 403 requiring a plan
upgrade or public visibility for root rulesets/branch protection; merge enforcement
is not active. See [CI/deployment setup](../../docs/backend-ci-deployment.md) and
[implementation evidence](../04-backend-ci-deployment/change.md).

Frontend Pages build is separately failed/deferred, with sync PR #50 open; see
[Cloudflare follow-up](../05-cloudflare-build-follow-up/findings.md). A published source
release and local adapter build do not establish successful hosted frontend deployment.

## Maintenance

Update this note when repository topology, module boundaries, auth contracts, adapters, or deployment ownership changes. Check the current manifests for dependency versions; this note is a dated baseline, not a dependency inventory to keep manually synchronized on every patch.
