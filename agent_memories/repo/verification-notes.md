# Verification Notes

- Kind: repository reference
- Status: current
- Last verified: 2026-10-23
- Scope: actual package scripts and evidence limits

## Package gate

App changes require an appropriate application version bump followed by `npm i`, then `npm ci`, then affected quality checks in that app. Compare lockfile checksums before/after `npm ci`; verify `package.json.version`, `package-lock.json.version`, and `package-lock.json.packages[""].version` agree. Commit the intended manifest and lockfile together.

Use Node 24 consistently with the Dockerfiles; use 24.15+ for the NestJS development toolchain. No root npm package exists. Root documentation changes do not require app installations or bumps. Never describe a listed command as executed unless it actually ran against the relevant state.

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
