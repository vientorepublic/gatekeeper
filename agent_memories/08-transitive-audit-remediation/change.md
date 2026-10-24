# Change: Patch Transitive Audit Findings

- Kind: investigation / implementation handoff
- Status: resolved
- Stage: verified-local
- Outcome: completed
- Created / last verified: 2026-10-24
- Type: modification
- Scope: both app manifests and lockfiles
- Baseline: root `94667c4`, backend `1e66b0c`, frontend `f9460c6`
- Branch lifecycle: preserve existing feat/node2shell-runtime branches and all uncommitted topic 07 changes
- Related: [Node2Shell runtime baseline](../07-node2shell-runtime/change.md)

## Objective and boundaries

Resolve the remaining npm audit findings by tracing the real dependency graph,
checking upstream compatible fixes, and applying the smallest compatible updates.
Preserve Node2Shell runtime hardening, HTTP/auth/UI contracts and existing work.
No publication, deployment, framework major migration, or upstream package release.

## Acceptance criteria

- AC-1: Confirm advisory versions and dependency paths; distinguish installed
  vulnerable packages from exploitable application paths.
- AC-2: Resolve both full and production npm audits without downgrading frameworks
  or disabling installation checks. Preserve existing unrelated lock resolutions.
- AC-3: npm i and stable-lock npm ci with normal scripts pass, all required app
  checks pass, and relevant transitive APIs remain usable.

## Dependency analysis and compatibility

- Backend: Nest platform-express 12.2.0 (latest) pins multer 2.4.0 exactly.
  Nest core/testing inherit audit findings from that adapter; there are not four
  independent root causes. Multer 2.5.0 fixes GHSA-q7qp-rjg7-q26m
  (CVE-2026-113872), with the same busboy/type-is/append-field dependencies and
  Node >=10.16. No upload interceptor or custom async fileFilter occurs in src.
  Confirmed package exposure; no current reachable upload exploit established.
- Frontend: adapter-cloudflare 8.0.1 (latest) has peer wrangler ^4.118.0; installed
  wrangler 4.152.0 (latest) pins miniflare 5.20261019.2-beta, which pins undici
  7.29.1. Miniflare uses exported Undici HTTP/Fetch/dispatcher APIs. Undici 7.30.1
  fixes the EventSource memory DoS, mixed-case SRI bypass, and excessive encoding
  chain DoS advisories and supports Node >=20.18.1, compatible with Node 24.22.1.
  This is build/preview tooling, not an npm production dependency. Zero production
  audit alone does not assess bundled output or the Node built-in Undici copy.
- Native Node fetch is separate: process.versions.undici is recorded during final
  checks; npm overrides cannot change the runtime's embedded implementation.

## Decision and implementation sequence

Use narrow overrides while upstream parent releases retain vulnerable exact pins:
platform-express -> multer@2.4.0 -> 2.5.0 and
miniflare@5.20261019.2-beta -> undici 7.30.1. The Multer selector matches only the vulnerable pinned version, and the
Miniflare selector matches only the current parent release; revisit/remove on parent upgrades. Do not
install unrelated Undici 8 or downgrade Nest/SvelteKit/Cloudflare adapters as npm
suggests. Reuse the unreleased 1.0.1 patch bumps from topic 07; no additional bump.

Run npm i, inspect complete lock changes, stable-lock npm ci, full/production
audits, dependency-tree checks, required app checks and targeted local API smoke.
No app source behavior, DTO/schema/cache or frontend state changes are expected.

## Sources

- [Multer advisory](https://github.com/advisories/GHSA-q7qp-rjg7-q26m)
- [Multer 2.5.0 release](https://github.com/expressjs/multer/releases/tag/v2.5.0)
- [Undici 7.30.1 release](https://github.com/nodejs/undici/releases/tag/v7.30.1)
- [EventSource advisory](https://github.com/advisories/GHSA-4qv8-2p9j-2685)
- [SRI advisory](https://github.com/advisories/GHSA-f72v-6w45-q472)
- [Encoding-chain advisory](https://github.com/advisories/GHSA-xjj6-f33q-929c)
- npm explain and npm view metadata read on 2026-10-24; installed parent sources.

## Verification and publication

Initial backend npm i rejected an exact version selector on a direct dependency
with EOVERRIDE. Corrected it to an unversioned parent with exact child selector,
preserving npm direct-dependency rules. Final verification below supersedes this initial failed attempt.

### Final install and audit evidence

Toolchain: Node 24.22.1, npm 11.13.0; normal lifecycle scripts and development
dependencies enabled. Each app npm i and npm ci passed. SHA-256 lock checksums
were unchanged across clean installation:

- Backend: `df46fcd3fb606ce912460aaaecfa9a60c678a2f0a1e05c2818b1a2debd45759b`.
- Frontend: `0a844dd58509a07d508ea6a50a6b4d10649d249ed783c9a740dcd0576470389b`.

Both full npm audit and npm audit --omit=dev exited 0 with all severities zero
in both apps: backend 4 full / 3 production package findings -> 0;
frontend 4 full / 0 production findings -> 0. Full manifests/lock diffs reviewed:
only Multer 2.4.0 -> 2.5.0 and Undici 7.29.1 -> 7.30.1 resolutions/integrities
changed, plus the existing 1.0.0 -> 1.0.1 app root fields from topic 07.
Manifest and both lock version fields agree. Existing overrides are preserved.

npm ls --all --json exited 0 in both apps. Backend has no problems; frontend's
only diagnostic is the known framework-generated node_modules/$app extraneous
entry. No invalid/missing dependency or peer problem was reported. Local embedded
Node Undici is also 7.30.1, independently of the frontend npm override.

### Required and targeted checks

- Backend lint, tsc --noEmit --incremental false, build: passed; 71 unit and
  47 integration tests passed. Lint did not mutate app source.
- Frontend lint, check: passed, zero Svelte errors/warnings; 19 unit tests passed;
  Cloudflare and Node builds passed.
- Local temporary smoke script, exit 0:
  - Multer async filter accepted an in-memory file, rejected an oversized file
    with LIMIT_FILE_SIZE/413, and accepted a subsequent request.
  - Undici MockAgent: mixed-case SHA256 integrity accepted the expected content
    and rejected changed content with integrity mismatch.
  - Undici local HTTP server: more than five content encodings with a truncated
    body rejected fetch without terminating the process.
  - Miniflare workerd started and dispatchFetch returned the expected HTTP 200
    body using the patched Undici dependency; resources were disposed.
- The temporary smoke script initially used legacy Miniflare constructor options
  copied from its bundled README, producing validation errors. Installed v5
  declarations expose convertV4MiniflareOptions; using that supported converter
  resolved the harness error and the final complete smoke passed. No product code
  was changed to accommodate the test.
- EventSource memory exhaustion and the precise Multer abort race were not
  reproduced. Advisory patch versions, dependency resolution, API smoke and app
  checks support remediation; these checks do not prove absence of all defects.
- Root source-comment scanner, whitespace and local documentation links: passed.
- No proxy implementation changed; proxy benchmark is not applicable. No real
  OAuth session or production database/service mutation was needed.

### Publication and maintenance

Implemented and verified locally. No commits, pushes, Releases or deployments.
Root gitlinks remain at the published baseline. Final origin/main...origin/dev
checks returned 0/0 with empty left/right logs and tree diffs in all repositories.
Temporary Miniflare root cache was removed after smoke verification. All prior Docker/.node-version/CI/
docs changes are preserved. Topic 07's earlier lock hashes and audit findings are
historical; this final package state supersedes them. Both app versions remain
unreleased 1.0.1 on the existing feat/node2shell-runtime branches.

When parent packages incorporate safe pins, remove the scoped overrides after
reviewing their new dependency contracts, rerun npm i/stable-lock npm ci and all
checks, and reconfirm full/production audit results. Publication still requires
child-first integration followed by root dev gitlink updates. Production rollout
and current container inspection remain outside this local remediation.
