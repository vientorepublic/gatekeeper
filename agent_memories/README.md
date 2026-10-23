# Shared Agent Memory Index

Last reviewed: 2026-10-23

Read the root [AGENTS.md](../AGENTS.md) and this index at the beginning of each non-trivial task. These notes are versioned shared context. They do not synchronize private agent chats or standalone application clones.

## Canonical repository notes

- [Project architecture](repo/project-architecture.md) — current; source-based map of app boundaries, request flows, infrastructure, and contracts. Read for architecture or cross-app changes.
- [Repository workflow](repo/repository-workflow.md) — current; dependency/pointer order, initial dirty state, and submodule registration mismatch. Read before Git/package operations.
- [Verification notes](repo/verification-notes.md) — current; real scripts, relevant checks, and limits of the initial documentation pass. Read before implementation validation.
- [Feature change workflow](../docs/development-workflow.md) — current; scope, acceptance criteria, addition/modification/removal sequences, state transitions, and completion gates. Use [the change template](templates/change-template.md) for non-trivial implementation records. AGENTS.md remains authoritative.
- [GitHub and release workflow](../docs/github-release-workflow.md) — current; gh-only GitHub operations, dev-based feature branches, feat-to-dev-to-main promotion, deployment-triggered Releases, and return-to-dev refresh.

## Topic investigations and plans

- [01 — Dependency and security refresh](01-dependency-security-refresh/findings.md) — historical local evidence; both app changesets subsequently published as v1.0.0; see topic 04 for final SHAs and current rollout.
- [02 — Guideline compliance and code quality](02-guideline-compliance-audit/findings.md) — resolved locally; source-wide inspection, boundary/state/proxy fixes, accessibility, and 137 passing regression tests.

- [03 — Submodule README reorganization](03-readme-reorganization/change.md) — resolved locally; aligned onboarding structure, app-owned reference documents, and corrected source-backed auth/configuration instructions.

- [04 — Backend CI and WireGuard deployment](04-backend-ci-deployment/change.md) — resolved/deployed; both app v1.0.0 Releases and root composition release published, fifth backend rollout verified Healthy, scoped CI keys and isolated server releases configured, root/backend dev synchronization complete.
- [05 — Cloudflare Pages build follow-up](05-cloudflare-build-follow-up/findings.md) — resolved/deployed; Pages Node mismatch corrected without source changes, production HTTP smoke passed, PR #50 merged, and frontend dev synchronized.

- [06 — Git synchronization guidelines](06-git-sync-guidelines/findings.md) — resolved; identified history-only reverse merge commits and defined protection-compliant fast-forward synchronization; follow-up publication includes development pointers, merged-feature cleanup policy, and origin/dev as the default pointer source.

Add new topics as `07-descriptive-topic/`, `08-another-topic/`, and so on. Classify note content as an investigation, plan, decision, or handoff; track `draft`, `active`, `blocked`, `resolved`, or `superseded` explicitly. A proposed plan is not an accepted architectural decision.

## Writing and sharing

1. Search this index and existing notes before adding a file; update the canonical source where possible.
2. Start from [memory-template.md](templates/memory-template.md). Keep repository paths relative to the meta root and include source symbols or commit IDs when relevant.
3. Add a descriptive index link, status, and reading scope. Update the note's verification date only after reviewing its evidence.
4. Record commands with actual results; separate suggested verification from executed verification. Redact sensitive information.
5. Commit shared memory in the root repository with related work. For app work, make the app commit available first and record its final SHA in the memory/root pointer change.
6. On completion, promote durable knowledge to `repo/`, mark plans/handoffs resolved or superseded, and link replacements. Avoid copying the same rules into several documents.

All agents use this same index. Notes are advisory context; the root instructions and current source remain authoritative. See AGENTS.md section 8 for full rules.
