# Guideline Compliance and Code Quality Audit

- Kind: investigation / implementation handoff
- Status: resolved; subsequently published in app v1.0.0 Releases
- Created / last verified: 2026-10-23
- Scope: both app repositories and the root guideline checker
- Baseline: unpublished dependency refresh on `codex/dependency-security-refresh`; backend HEAD `8a23d1831ee5d6c79bcf28c59e550eeddbe22ffd`, frontend HEAD `c70749cc1ea66367d3cc5a0f4b4d21196eb465a6`.
- Related: [dependency refresh](../01-dependency-security-refresh/findings.md), [architecture](../repo/project-architecture.md), [verification](../repo/verification-notes.md).

## Scope and method

Publication update: the unpublished/0.0.2 snapshot below is historical. Both final
1.0.0 changesets were revalidated and published, and backend deployment succeeded;
see [publication evidence](../04-backend-ci-deployment/change.md). Hosted frontend
Pages and its ancestry sync remain [deferred](../05-cloudflare-build-follow-up/findings.md).

The inventory covers **109 app source/configuration/documentation files**, excluding dependencies, Git internals, generated/build output, lockfile contents, and incremental compiler artifacts. Run `node tools/check-agent-guidelines.mjs --inventory` for the current file list. Flow review covered auth/session/key management, routing/public paths/proxy streaming, cache/state/lifecycle, input/error handling, components/accessibility, configuration, and test fixtures.

The language scan inspected **113 comments and 132 test-title occurrences**. No CJK explanatory comments or test titles were found. Existing Korean UI copy remains unchanged. The scanner detects those scripts; English wording and proper-noun exceptions still require human review.

Earlier edits were retained. Both apps reuse the existing unreleased `0.0.2` patch bump against integration version `0.0.1` for these review fixes in the same unpublished changeset. No commit, push, merge, tag, or gitlink update was performed.

## Confirmed findings and patches

### HTTP, browser storage, and OAuth boundaries

- Frontend generic response casts and unchecked localStorage users were replaced by required runtime decoders. `src/lib/api/http-client.ts` parses JSON/errors once; `validation.ts`, `api-decoders.ts`, `api-types.ts`, and `src/lib/auth/auth-types.ts` separate validation, contracts, and authentication transport.
- Validate nested API key data, pagination, token/user fields, revocation booleans, error payloads, and HTTP(S) authorization URLs. A false revocation result no longer produces a success notice. Blocked browser storage is handled without unhandled failures.
- Store the authorization nonce in sessionStorage and require the same browser's matching nonce before callback exchange. Consume it once; remove OAuth-sensitive query parameters from history on success and failure while preserving unrelated parameters.
- Session revisions prevent refresh/callback results from overwriting newer sessions or reauthenticating after logout. Older refresh cleanup cannot clear a newer single-flight operation.
- Dashboard request IDs reject stale namespace/page responses. Namespace changes clear old key material and confirmations; issue/revoke completions check their captured namespace/user.
- Valid existing gateway sessions remain usable. An OAuth login started before the browser-nonce patch must be restarted because no browser nonce was stored.

### Routing and streaming proxy

- Route normalization is extracted into `src/config/route-map.config.ts`. Reject malformed/empty/mixed public-method allowlists, public flags/path containers, empty paths, and non-object maps. Only omitted `methods` means unrestricted methods; operators using `methods: []` must omit it or supply a valid allowlist.
- Use `Object.fromEntries` and own-property route lookup to preserve prototype-like names safely. Validate structured route entries and cached public-path rules; malformed cached routes fall back to configuration.
- Reject dot/encoded traversal, malformed escapes, and backslashes before public-path matching; verify resolved URLs retain the upstream origin.
- Strip hop-by-hop and Connection-nominated headers. Remove stale content lengths and compression headers when fetch decoded the response body.
- Arm abort timers after synchronous body validation; count rate limits once and payload-limit errors at the outer request boundary. Buffered bodies use a typed byte copy; streamed bodies use the Node Web stream adapter.

### Cache, SDK, configuration, and cleanup

- `ProxyStateService` uses the real Redis client type and supported `close()` API. Redis circuit JSON is validated; in-memory circuit state honors Redis-equivalent TTLs and does not expose mutable stored references.
- Shutdown attempts database and every cache cleanup even when another resource fails, preserving failures in aggregate.
- Replace the database configuration assertion with `getOrThrow`. Handle bootstrap rejection and close the app after post-creation startup failure.
- Remote route-map fetches have a bounded timeout and avoid logging credential/query-bearing URLs. SDK token/userinfo/state-cache shapes are checked; error causes are retained while raw SDK messages are excluded from logs. Usage-timestamp failures produce sanitized warnings.

### Accessibility and conventions

- Modal focus is contained with Tab/Shift+Tab and restored after removal. A designated completion notice receives focus when successful revocation disables its original trigger.
- Confirmation dialogs use unique Svelte instance IDs. The key-label input now has a label and backend-aligned length limit. Profile menus support keyboard entry/exit and focus restoration.
- Confirmation dialogs remain mounted during asynchronous work, then close after completion. Error/notice regions use alert/status roles.
- Backend `no-explicit-any`, `no-floating-promises`, and `no-unsafe-argument` are enforced as errors. Remove unused code, decorative comment separators, and duplicate metrics initialization.

## Quality assessment and retained patterns

HTTP parsing is now one shared implementation instead of two duplicated blocks; every success path requires an explicit decoder. API domain types and schemas no longer depend on authentication transport. Existing type re-exports preserve callers. The environment factory shrank from 234 to 106 lines by moving route normalization into a focused, directly tested module. Additional validation and tests intentionally increase total code.

Framework-hydrated TypeORM/DTO definite-assignment fields remain. Partial DI fixtures use explicit test-boundary casts. The remaining Node/DOM stream-body cast and SDK custom-scope enum cast document concrete interoperability constraints. Existing Svelte stores remain valid. Applied migrations, endpoint names, intended payload contracts, UI language, and NodeNext compilation are preserved.

## Executed verification

Toolchain: Node 24.22.1 / npm 11.13.0. Both apps passed `npm i` followed by `npm ci`, with matching `0.0.2` manifest/root-lock versions and unchanged lock checksums:

- Backend SHA-256: `8ad7802b9580b2992b0dd172c4731a0c1346fdabf8ae2f34a71483e0fc9f98d8`.
- Frontend SHA-256: `729115494817da458d7e1508087730deba95d2a5141f95814363d5c7d3a894b7`.
- Backend: lint, type check, build, **71 unit + 47 integration tests** passed.
- Frontend: lint, type check (0 errors / 0 warnings), **19 Vitest tests**, Cloudflare build, and Node build passed.
- Combined tests: **137**, up from the dependency refresh's 82 backend tests and no frontend unit suite.
- Full and production-only npm audits: **0 vulnerabilities in both apps**, including Vitest.
- Real isolated Redis: cache set/get/delete/TTL, atomic counter, circuit state, and lifecycle passed.
- Proxy benchmark compatibility smoke: 1-second runs, 2 connections, 1024-byte payload; optimized/legacy GET and POST completed with zero errors/timeouts. These short runs do not establish production performance gains.
- Browser checks used a local mock API with synthetic accounts/keys. Authorize/callback, dashboard entry, key issue/revoke, delayed namespace responses, unique dialog labels, Tab/Shift+Tab containment, profile keyboard entry, and Escape restoration were exercised. After revocation disabled its trigger, the final browser check confirmed focus on the completion notice (`role=status`, `data-dialog-return-focus`). The synthetic dashboard screenshot was saved outside the repository.

## Limits and handoff

This is tested source/guideline remediation, not a proof that all possible defects are absent. Hosted Cloudflare, production MariaDB, real external OAuth sessions, and a full container image build were not exercised. The local submodule registration-name mismatch remains an environment issue; pointers were not moved to represent uncommitted work.

Before publication, inspect combined child diffs and follow the dependency/child/root commit order. Frontend `npm test` is now implemented; browser checks remain a separate manual workflow.
