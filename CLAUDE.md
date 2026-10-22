# Project engineering rules

This file is the canonical project-level programming rule set for `flutter_nexusft` (the NexusFT Flutter mobile client). Tool-specific instruction files must import or reference this file and must not redefine a competing rule set.

## Instruction precedence and portability

- Follow the active environment's system, developer, and user-level instructions before repository instructions. If they conflict, use the higher-priority instruction and report any material project-rule conflict rather than silently weakening either rule.
- This file is the single portable project-rule authority for Claude Code, Codex, Cursor, CI, and future agents. `AGENTS.md` imports it; scoped rules may add narrower detail only when consistent with it.
- Do not make project behavior depend on a tool-specific personal path, private user configuration, agent skill, or local credential. Treat environment-provided capabilities as supplementary; the repository's engineering, documentation, and verification rules must remain understandable and enforceable without them.
- This repository shares the product model and `PlatformApi` contract vocabulary with the Web project `dex_v2_fe`. The Web repository's own rule set governs that repository; this file governs this one. Cross-project statements belong in `docs/project-rules.md`'s mapping table, not inline in code.

## Sources of truth

- The root README is the project entry point. When consulting material under `docs/`, AI agents must first read `docs/manifest.md` or its equivalent Chinese version `docs/manifest.zh-CN.md`, then read only the authorities and supporting material relevant to the task. Read dated plans/references only when tracing stage evidence.
- Product behavior and effective decisions: explicitly accepted sections in `docs/decisions.md` (a single flat file at current volume; split into `docs/decisions/<topic>.md` only when independently maintained topics warrant it). Interface signatures and semantics: the canonical `PlatformApi` contract in `lib/core/api/contract.dart`. Proposed behavior and static implementation observations are not automatically accepted requirements.
- Rules that must already hold: `docs/invariants.md`.
- Current code structure and implementation boundaries: `docs/architecture.md`.
- Domain terminology and user-facing vocabulary: `docs/glossary.md`.
- `docs/status.md`, `docs/handoff.md`, `docs/plans/`, `docs/designs/`, and `docs/references/` describe operating state and stage evidence; they are not programming-rule authorities.

If two authoritative sources disagree, do not silently choose one. Verify the implementation and update the stale source in the same change.

## Working discipline

- For analysis, diagnosis, or review requests, inspect and report without modifying production code.
- For implementation or fix requests, make the required change and complete risk-proportionate verification.
- Read the relevant implementation, tests, invariants, and design documents before editing.
- Find and fix the root cause. Do not hide defects with silent fallbacks, duplicated branches, or unrelated refactors.
- Keep changes scoped to the requested behavior and preserve unrelated existing worktree changes.
- A change is not complete until relevant verification has run or the unverified portion and reason are stated.

## Platform model and backend boundary

- v1 is the only live backend. Environments are `dev` / `uat` / `prod`, selected explicitly via `APP_ENV` / `API_BASE_URL`; other environments must not silently reuse `dev` configuration. The Web project's open alias mechanism is not ported.
- UI (modules, shell, design_system) accesses backends only through `core` providers and the `PlatformApi` contract — never through adapters, Dio, or storage plugins directly.
- Backend paths, wire payloads, field dialects, enum crosswalks, and venue-specific capability corrections belong only in `lib/core/adapters/*`.
- `lib/modules/*` must not import one another. Promote cross-module behavior to `lib/shell`, `lib/core`, or `lib/design_system`.
- `lib/core/domain` and `lib/core/api` stay pure Dart: no Flutter SDK, Riverpod, Forui, or storage-plugin imports.
- The boundary is enforced by `tool/check_architecture.dart` plus `test/architecture_test.dart`. The gate is lexical, not a full AST analyzer; passing it does not replace code review.
- When live v1 behavior and the target contract differ, preserve the live behavior in the v1 adapter and record the target-contract delta in `docs/decisions.md`; do not bend feature code around v1.

## Data and financial correctness

- Never fabricate a venue-owned value. Missing data remains `null` or raises an explicit malformed/unsupported error.
- Never replace missing money, price, quantity, enum, timestamp, or status with `0`, an empty string, a guessed value, a mid price, or a borrowed field.
- Financial values are parsed, calculated, and rendered with `Decimal` (`package:decimal`); Dart `double` arithmetic must not touch financial values.
- Price and quantity precision comes from venue-provided market metadata; do not hardcode decimal places per screen.
- Local demo data (order book, orders, assets) must be deterministic, confined to `demo_*.dart`, labeled “演示数据” in the UI, and must never enter an API request path. It is removed when the real feed lands.
- Degradation paths must log or surface the failure. Bare `catch {}`/`catch (_)` on data reads is forbidden unless the absence of the capability is explicitly the expected result. Logs record the error type only — never credentials, tokens, or response bodies.
- Before claiming a live v1 field or capability is absent, inspect the Web v1 frontend usage, the live route payload, and the live UI behavior.

## Shared frontend authorities

- Reuse existing `lib/design_system` primitives and `lib/core` domain authorities before creating feature-local behavior. Foundational UI patterns belong in `design_system`; foundational domain behavior belongs in `core`.
- Use the shared primitives (`AppCard`, `AppIconButton`, `AppListRow`, `PageStatus`, `trading/` components) and the token layers (`tokens/app_*.dart`, `tokens/trading_tokens.dart`); do not introduce ad-hoc colors, radii, or spacing in feature code.
- Forui is the confirmed UI foundation; `MaterialApp` remains only the routing/host shell. Do not mix Material `ThemeData` with Forui themes in one subtree.
- Page-level prompts use `showFToast` at the root `FToaster`; there is no Material `Scaffold` under `FScaffold`, so `SnackBar` is not available.
- Charts render through WebView only; the Dart layer owns data and trading. A chart must never hold credentials or initiate trading.
- User-facing strings use the shared i18n keys (`AppText`). `en-US` is the canonical key tree and `zh-CN`/`zh-TW` must remain key-compatible; language resolution (Hans/Hant) shares the pure-Dart `languageForTags` between HTTP and UI.
- Venue data such as tickers and team names is backend content, not an i18n key.

## Authentication posture

- v1 uses its venue-issued `x-auth-token`. The token is persisted in `flutter_secure_storage`, namespaced by environment + API origin, and injected by the HTTP layer. v1 has no refresh token; treat persisted-token-on-device as the explicit legacy posture, not the target architecture.
- Confirm identity before persisting a session; when the backend provides no `expiresAt`, keep it `null` — never guess one.
- Authentication state and user-scoped caches must be cleared together on logout or token rejection. A stale request's 401 must not tear down a newer session: session generations and the ordered write queue isolate old requests and old logins.
- MFA challenges are explicitly refused until the MFA flow is implemented; Google login is a UI placeholder until a real integration decision exists.
- Real-account login/registration verification requires an explicitly authorized test account; protocol and concurrency tests with controlled HTTP fixtures do not substitute for it.

## Specification-driven changes

- A new user flow, public primitive, cross-module behavior, domain type, or `PlatformApi` contract change requires an accepted design/specification in `docs/designs/` before implementation. Fold accepted behavior and its effective decision into `docs/decisions.md`; keep the design document as stage evidence, not a parallel authority.
- Specifications must state goals, non-goals, behavioral states, contract changes, acceptance criteria, migration/rollout impact, and verification evidence.
- Proposed or incomplete behavior belongs in designs, plans, or roadmap documents; it must not be written as an invariant.
- If implementation changes an accepted behavior, update the relevant specification, decision, and invariant in the same change.

## Documentation lifecycle

- Maintain documentation according to this section and the roles and navigation in `docs/manifest.md` / `docs/manifest.zh-CN.md`. These overviews provide equivalent navigation and maintenance guidance for `docs/`; this file remains the project-rule authority.
- Documentation overviews and README files must provide complete English and Simplified Chinese versions with reciprocal language links (separate files or sections). Keep their scope, rules, status, and links equivalent. Other documents follow the developer's current language preference; translation is not required solely for consistency.
- Choose the documentation shape according to actual volume and complexity: a topic may remain `docs/<topic>.md`, or use `docs/<topic>/` when independently maintained subtopics warrant it. Decisions stay in the single `docs/decisions.md` until volume justifies `docs/decisions/<topic>.md`. Execution records belong in `docs/plans/`, raw source evidence in `docs/references/`; tool-named paths are not authorities.
- Keep one maintained source for each rule or behavior. Maintain a complete topic context in one file by default. Keep global invariants, terminology, and architecture as single maintained files. Preserve stable IDs and historical attribution, and update affected links and indexes.
- Mark proposed, accepted, implemented, verified, superseded, and historical claims explicitly where applicable. Preserve dates, authors/attribution, reasons, and replacement links when recording changes; do not invent missing attribution or infer completion from an old date. A documentation review does not certify runtime behavior.
- Treat persistent documentation as part of the product: when reading an authoritative or operational document, compare its material claims with the relevant implementation, configuration, tests, and live evidence. Correct or consolidate it in the same change when it is stale.
- Do not preserve contradictory current guidance. If the difference is substantial, first capture the verified current rule in the appropriate authoritative document, then archive the obsolete document or section with its date and reason; archived material is evidence, never a source of current requirements.
- Keep current documents concise and single-purpose. `docs/status.md` contains only the current snapshot and open items; `docs/handoff.md` is the single actionable handoff while one is needed.
- For small changes with limited impact, record the date, change description and session summary in a comment near the affected code or document. Use `YYYY-MM-DD | change | session summary` (the reason/request and resulting conclusion, not an operation transcript or sensitive data). Each such comment retains at most the latest three dated records; rely on Git history for older change records. Markdown may use HTML comments. This exemption concerns change logging only: still update any changed behavior/contract authority and perform appropriate verification.
- Create a dated plan in `docs/plans/` only for work that is active and has an owner, scope, acceptance criteria, and completion/exit condition.
  - **Archiving records acceptance.** A plan is closed as accepted only when development is complete and the acceptance outcome and its evidence are recorded — which files/behaviors landed and which verification actually ran. Do not present an unexecuted check as acceptance: state plainly what was not executed and carry it into the owning document's open items.
  - **Archiving harvests knowledge, verified against code.** Before closing, compare the record with the actual implementation and fold every knowledge point the current documentation system does not already carry into its authority: `decisions.md` for behavior, `invariants.md` for global constraints, `glossary.md` for vocabulary. A plan may lag the code, so verify each claim in the source — code wins over stale plan wording — and record the discrepancy instead of importing the stale statement.

## Verification

- Verify against applicable specifications/cases, or the current request and affected behavior. Cover normal paths, key boundaries, failures, and regressions proportionate to risk; report omitted checks.

### Gates and evidence

- Standard gates (run before claiming completion):
  ```powershell
  .\scripts\flutter.ps1 analyze
  .\scripts\flutter.ps1 test
  D:\development\flutter\bin\dart.bat run tool/check_architecture.dart
  ```
  `scripts/check-android-requirements.ps1` runs automatically before `run`/`build apk` via `scripts/flutter.ps1`; after dependency changes, re-run it manually because IDE Run does not execute it.
- Live-protocol probes under `tool/` (`ws_probe.dart`, `storage_probe.dart`, `live_catalog_check.dart`) are evidence tools against the dev environment; storage probes use dedicated non-account test keys and never prove real login.
- Keep verification evidence under `docs/references/` (emulator screenshot matrices, probe outputs) with dated filenames; name screenshots by case and result and mask unrelated personal data.
- Passing tests, analyze, and the architecture gate do not certify real-account trading, real-time behavior on device, or iOS: those require their own explicit acceptance. Trading writes require an explicitly authorized environment and account.
- Claim passed only when required checks pass with complete evidence; report failures, blockers, and partial/unexecuted coverage. Fix within authorized scope, then rerun failed checks and affected regressions.

### Methods and executors

| Check | Method | Executor |
| --- | --- | --- |
| Logic, contract, and decoding rules | Unit/widget tests with assertions (`flutter test`), analyze, architecture gate | Current agent locally |
| Live dev-environment protocol checks | Probes under `tool/`; compare payloads with the Web v1 usage | Current agent locally |
| Emulator interactive/visual checks | Run the debug APK on the Android emulator; screenshot matrices per case, light/dark and language variants where relevant | Test subagent or user |
| Checks requiring human judgment or real accounts (real login, trading writes, iOS device) | User executes with provided steps, expected results, and evidence requirements | User |

- Assert results where possible; screenshots alone do not prove correctness, and visual comparison requires a confirmed baseline. Missing execution capability blocks the affected checks — report the block instead of substituting weaker evidence.

<!-- 2026-10-20 | Rewrite as Flutter-native rule set | Code review found CLAUDE.md was a verbatim copy of the dex_v2_fe Web rules; ported generic discipline, replaced Web-specific platform/auth/verification rules with the confirmed Flutter mappings. -->
