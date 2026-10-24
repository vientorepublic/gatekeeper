# Verification Notes

- Kind: repository reference
- Status: current
- Last verified: 2026-10-24
- Scope: actual package scripts and evidence limits

## Package gate

App changes require an appropriate application version bump followed by `npm i`, then `npm ci`, then affected quality checks in that app. Compare lockfile checksums before/after `npm ci`; verify `package.json.version`, `package-lock.json.version`, and `package-lock.json.packages[""].version` agree. Commit the intended manifest and lockfile together.

Use Node 24 consistently with the Dockerfiles; use 24.22.1+ for the Node 24 toolchain and Brotli security baseline. No root npm package exists. Root documentation changes do not require app installations or bumps. Never describe a listed command as executed unless it actually ran against the relevant state.

## Backend checks

Run from `gatekeeper-backend/`:

```bash
npm run lint
npx tsc --noEmit --incremental false
npm run build
npm test -- --runInBand
npm run test:e2e
```

- `lint` runs ESLint with `--fix`; review mutations and do not fold unrelated formatting into a change.
- Jest unit specs live under `src/`; integration tests use `test/jest-e2e.json` and `test/gateway.e2e-spec.ts`. NestJS 12 ESM packages require Jest's VM module support; the package test scripts include `--experimental-vm-modules`.
- The inspected integration suite uses Nest testing modules, mocked auth/cache services, and local HTTP upstreams. It does not establish production MariaDB/Redis behavior.
- Route rewriting, authorization rejection, payload limits, timeouts/circuit behavior, metrics, and input validation deserve targeted regression coverage when changed.
- `npm run bench:proxy` compares optimized streaming and a benchmark-local buffered implementation. Run for proxy performance changes and record duration, connections, payload size, thresholds, runtime, and results.
- Backend `tsconfig.json` excludes `test/`; type checking application sources alone does not verify the integration suite.

## Frontend checks

Run from `gatekeeper-frontend/`:

```bash
npm run lint
npm run check
npm test
npm run build
npm run build:node
```

- `lint` combines Prettier check and ESLint; it does not auto-fix like backend lint.
- `check` explicitly runs SvelteKit sync before Svelte checking. The `prepare` helper propagates sync failures when SvelteKit is installed and skips sync when production dependencies intentionally omit SvelteKit. Docker dependency stages copy the helper and Vite/Svelte/TypeScript/environment configuration before installing.
- Build the relevant adapter for a focused change; verify both adapters for shared runtime/config changes.
- `npm test` runs Vitest with isolated environment fixtures in `vitest.config.ts`; response validation and auth-state regressions are covered. This is not a browser suite; browser interaction checks are separate.
- Auth/session changes need login/callback, refresh, retry/expiry/logout, and SSR/browser boundary checks. Key-management changes need namespace selection, issue/list/revoke, pagination, and failure states.

## Initial documentation pass

The initial architecture pass inspected source/configuration, Git topology, manifest diffs, scripts, and the supplied LawCast guideline reference. It did not execute app installations, lint, compilation, tests, benchmarks, browser flows, migrations, or deployments. Existing manifest/lockfile changes were left untouched.

Documentation validation passed: `git diff --check` for tracked changes; a local Python check for all seven documentation files verified 14 local Markdown links, one H1 per file outside code fences, final newlines, and absence of trailing whitespace, including new untracked files. Documented npm script names were checked against both manifests. No Git configuration, app versions, or gitlink SHAs were changed by this task.

For documentation-only changes, check links to local files, structure/path accuracy, and whitespace. Revalidate this note when scripts change; it is not proof that current dependency versions install or build successfully.

## Subsequent dependency refresh

See [the dependency refresh findings](../01-dependency-security-refresh/findings.md) for the tested dependency versions, audit results, lockfile checksums, migration changes, and validation limits. The initial documentation-pass omissions above are historical and do not describe that later validation run.

## Guideline remediation verification

See [the guideline audit](../02-guideline-compliance-audit/findings.md) for source-wide inspection, 71 backend unit / 47 integration / 19 frontend tests, both adapter builds, clean-install/audit checks, isolated Redis and synthetic browser verification. Run `node tools/check-agent-guidelines.mjs` from the root for comment/test-title checks; `--inventory` lists covered files. The language scan is an aid, not a complete English-language proof.

## Published 1.0.0 and backend deployment

Both app final release gates were rerun with Node 24.22.1/npm 11.13.0 and normal
lifecycle scripts: npm i, stable-lock npm ci, all required app checks, 137 combined
tests, both adapters, full/production audits reporting zero vulnerabilities. Root
hosted Ubuntu/Node 24 checks also passed on every promotion's exact head. Final hashes:

- Backend: `aac45dd2d5321dc05e8670d0b3cc55421fe12780eabaac684ff814437deed042`.
- Frontend: `95ed75a18e403730e5af34971bd2c2ebc25ef259ec8d765b278ea3226f79546d`.

The successful main deployment additionally verified fourteen script regression tests,
private fetch scopes, isolated release checkout, Docker image build, backend container
Healthy, host HTTP probe, and tunnel/credential cleanup. See [topic 04](../04-backend-ci-deployment/change.md)
for immutable SHAs/run/release URLs and limitations. Production OAuth/upstream end-to-
end behavior and frontend hosted Pages success are not established by these checks.

## Node2Shell runtime baseline

See [topic 07](../07-node2shell-runtime/change.md) for CVE-2026-111497 exposure
tracing, local Docker/.node-version/CI hardening, stable-lock clean installs,
137 passing tests, and both frontend adapter builds. The last recorded backend
rollout image digest matches the official Node 24.22.1 image. This is historical
deployment corroboration, not a live container inspection. The subsequent [transitive audit remediation](../08-transitive-audit-remediation/change.md)
patches Multer and tooling Undici with narrow overrides; both current full and
production audits report zero. The 137 app tests, both adapter builds and targeted
Multer/Undici/Miniflare smoke passed for that final package state. Audit results
are dated registry evidence and must be refreshed after dependency changes.

## Security 1.0.1 deployed verification

[Topic 09](../09-security-release-validation/change.md) records actual local built-app
execution with isolated MariaDB/Redis, fixture OAuth and Brotli upstreams, browser
key lifecycle validation, all hosted root CI checks, successful backend container
replacement/health and Pages production deployment for exact app main SHAs. App
v1.0.1 and root release-20261024.1 are published. Public backend health/auth/CORS
and frontend SSR/assets/public API configuration passed. Real-account production
OAuth/key workflows remain unverified. Post-release verification docs advance dev
without modifying or republishing the immutable release composition.
