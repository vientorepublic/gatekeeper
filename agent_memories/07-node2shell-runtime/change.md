# Change: Node2Shell Runtime Baseline

- Kind: investigation / implementation handoff
- Status: resolved
- Stage: verified-local
- Outcome: completed
- Created / last verified: 2026-10-24
- Type: modification
- Scope: both application Dockerfiles, runtime selectors/documentation, root CI
- Baseline: root dev `94667c4`; backend dev `1e66b0c`; frontend dev `f9460c6`; all clean and equal to fetched origin/dev
- Branch lifecycle: `feat/node2shell-runtime` in all three repositories; local remediation only
- Related: [previous deployment](../04-backend-ci-deployment/change.md), [Pages verification](../05-cloudflare-build-follow-up/findings.md)

## Objective and boundaries

Determine whether CVE-2026-111497 reaches the current NestJS/SvelteKit apps and
prevent future Docker builds from reusing an older cached Node 24 image. Preserve
all HTTP, authentication, compression, streaming, and data contracts. Production
rollout, upstream package publication, exploit execution, database changes, and
unrelated dependency upgrades are outside this implementation.

## Acceptance criteria

- AC-1: Trace inbound Brotli and outbound fetch paths to actual installed code;
  distinguish vulnerable-runtime exposure from proven compromise.
- AC-2: Every Node Docker stage explicitly selects patched Node 24.22.1; app
  runtime selectors and CI agree; onboarding specifies the patched minimum.
- AC-3: Both patch versions install cleanly with stable locks and all required
  checks pass; document unverified deployed runtimes and container builds.

## Impact and compatibility

The flaw is in Node's bundled Brotli decoder, not an npm framework fix. App
versions become 1.0.1 as compatible security/build maintenance. No DTO, schema,
cache, authorization, response, UI, or external consumer contract changes. Existing
Node 24 installations should update to 24.22.1 or a newer patched 24.x release.
Cloudflare Pages build Node and its workerd request runtime are separate.

## Confirmed evidence

- [Node advisory](https://nodejs.org/en/blog/vulnerability/october-2026-security-releases):
  CVE-2026-111497 affects Node 22/24/26 Brotli decoding; fixed releases are
  22.23.4, 24.22.1, and 26.12.1.
- [Researcher report](https://www.imperva.com/blog/node2shell-from-brotli-data-to-remote-code-execution/):
  RCE demonstrated on official Node 24.22.0 Linux arm64; architecture-specific
  exploit results must not be generalized to every build.
- Local `node --version`: v24.22.1. Final install/check toolchain used npm 11.13.0 from an isolated temporary installation. Local runtime is patched.
- Backend lock: Express 5.3.0, body-parser 2.4.0. Nest's installed
  `registerParserMiddleware` uses express.json/urlencoded with inflation enabled;
  installed body-parser `lib/read.js` invokes createBrotliDecompress for br.
  `src/main.ts` uses default parsing (`rawBody: true` retains decoded bytes,
  rather than disabling inflation). Parsing can happen before route guards.
- Backend `GatewayProxyMiddleware.forwardToUpstream` consumes upstream fetch
  bodies, with automatic decompression; `preloadRouteMapFromUrl` consumes a
  configured remote JSON response. FlowAuth's Environment.getFetch uses native
  fetch for discovery/JWKS/token requests. Outbound exposure requires a malicious
  response source; operator URL configuration alone is not an SSRF finding.
- Frontend has no server load/action/endpoint or hooks files. Current app API and
  auth calls execute from onMount/browser flows. Installed adapter-node reads
  incoming request bytes without invoking Brotli decompression. No equivalent
  unauthenticated server decoder path was found in current frontend code.
  A future Node SSR external fetch could add exposure.
- Both Dockerfiles previously used floating `node:24-alpine`, which does not
  establish the version inside an already built/running image. hardened_malloc
  and non-root execution do not replace the decoder patch.
- Prior Pages evidence records Node 24.22.1 for the 2026-10-23 build. This is
  historical build evidence, not a current backend container runtime measurement.

## Implementation sequence

1. Review advisory, source, locks, Git state, and deployment evidence.
2. Pin all app Docker stages and .node-version to 24.22.1, update onboarding,
   select patch versions, and consume child selectors in root quality CI.
3. Run npm i, record locks, npm ci, and required checks in both apps.
4. Review final diffs and record evidence/remaining deployment verification.

## Deployment image corroboration

The latest successful [backend rollout](https://github.com/vientorepublic/gatekeeper/actions/runs/39940309707)
was read through gh on 2026-10-24. It deployed root `94667c4` and backend `1e66b0c`
on 2026-10-23, and reports the backend Healthy. Its base image digest is
`sha256:06d7adf3e0ef61a13f1d28682726366f97a15aa1888c934d3ecec86c33918b53`.
`docker buildx imagetools inspect node:24.22.1-alpine` resolves to that exact same
digest. This corroborates a patched runtime in the last recorded deployment image;
it does not inspect a currently running container or exclude subsequent operator
changes. No RCE or compromise was demonstrated in this project.

## Verification and publication

Final package/check toolchain: Node 24.22.1 / npm 11.13.0. An initial npm 12.2.0
install reported default allowScripts blocking. That run was not used as the final
gate: npm 11.13.0 was installed under /tmp and both npm i and npm ci were rerun
with ordinary lifecycle scripts and development dependencies enabled.

- Both npm i and npm ci: passed. Full lock diffs contain only the two root version
  fields per app; no dependency resolutions changed. Manifest/root lock/package
  versions all equal 1.0.1. SHA-256 before and after npm ci matched:
  - Backend: `6798fd1741e15755e2cf4c36b2613db81ebe3758f435acc544eae054a68442df`.
  - Frontend: `e21883156500738ea580ed7341a42c66e1454bea6e644f605312cb0ddd78b9d4`.
- Backend lint, tsc --noEmit --incremental false, build: passed; 71 unit and
  47 integration tests passed. No source mutations from lint.
- Frontend lint/check: passed, zero Svelte errors/warnings; 19 unit tests passed;
  Cloudflare and Node adapter builds passed.
- Official patched image manifest: available for Linux amd64, arm64/v8, s390x.
  All Docker node FROM versions match each app .node-version. The backend's
  dependency/builder/runner stages inherit the patched base.
- Root comment/test-title scanner: passed, 114 covered files. No source behavior
  changed; no proxy benchmark or authenticated browser flows were needed.
- Full Docker builds: not run because local Docker daemon is unavailable.
  Live container exec, production database/OAuth integration: not run.
- Root and child whitespace checks and local Markdown links: passed.
- GitHub workflow execution for these unpublished edits: not run. Root CI now
  consumes app .node-version; child files must be integrated before the root
  pointer/workflow commit, as required by the dependency-first workflow.

### Separate npm audit findings

Follow-up: the user subsequently authorized transitive dependency remediation.
[Topic 08](../08-transitive-audit-remediation/change.md) supersedes the unresolved
audit findings and final lock hashes below; both full/production audits now report
zero after scoped compatible patches. The following is the original investigation.

The current registry reports additional advisories despite unchanged resolutions.
These are not CVE-2026-111497. Audit is not a clean security result:

- Backend full audit: 4 high package findings; production audit: 3 high. They
  arise from [Multer GHSA-q7qp-rjg7-q26m](https://github.com/advisories/GHSA-q7qp-rjg7-q26m)
  and inherited Nest dependency findings. No FileInterceptor/FilesInterceptor,
  FileFieldsInterceptor, AnyFilesInterceptor, multer, or fileFilter usage exists
  under backend src; this audit did not establish a reachable upload exploit.
- Frontend full audit: 1 high and 3 moderate package findings, through
  adapter-cloudflare/wrangler/miniflare/undici. Production-only audit: zero.
  Undici reports [EventSource DoS](https://github.com/advisories/GHSA-4qv8-2p9j-2685),
  [SRI bypass](https://github.com/advisories/GHSA-f72v-6w45-q472), and
  [encoding-chain DoS](https://github.com/advisories/GHSA-xjj6-f33q-929c).
  A production-only npm audit omits bundled framework/build artifacts and does not
  prove the resulting Worker artifact free of all vulnerabilities.
- npm's suggested automatic fixes would downgrade framework/adapter major lines.
  No forced fix or unrelated dependency migration was applied. Track these
  separately after confirming compatible upstream fixes and relevant reachability.

### Completion and remaining operations

Local Node2Shell hardening and required source checks are complete. No commits,
pushes, PR merges, Releases, or deployments were performed. Versions are proposed
unreleased 1.0.1 on feat/node2shell-runtime in all three repositories. There were
no pre-existing changes. The root gitlinks still point to the original published
child dev SHAs; no unpublished child commit is referenced. Keep the feature
branches while changes remain uncommitted. Final read-only remote ancestry checks
in root/backend/frontend each returned `0 0` for origin/main...origin/dev, with
empty left/right logs and empty tree diffs. Local feature HEADs still equal the
fetched dev baseline; dirty implementation files are intentionally preserved.
The root staged gitlinks were not changed.

For publication: recheck version availability, commit/push/merge children first,
then update exact root dev gitlinks and publish root CI/memory changes. A requested
rollout must follow the release workflow. At that time verify live Node with
`docker exec gatekeeper-backend node --version`; independently check any Node
frontend container if deployed. Preserve pinned patched runtime during rollback.

Historical deployment/read-only corroboration is complete. No production services were changed.
