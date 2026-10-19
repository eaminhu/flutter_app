# Project engineering rules

This file is the canonical project-level programming rule set for `dex_v2_fe`. Tool-specific instruction files must import or reference this file and must not redefine a competing rule set.

## Instruction precedence and portability

- Follow the active environment's system, developer, and user-level instructions before repository instructions. If they conflict, use the higher-priority instruction and report any material project-rule conflict rather than silently weakening either rule.
- This file is the single portable project-rule authority for Claude Code, Codex, Cursor, CI, and future agents. `AGENTS.md` and Cursor rules import it; scoped rules may add narrower detail only when consistent with it.
- Do not make project behavior depend on a tool-specific personal path, private user configuration, agent skill, or local credential. Treat environment-provided capabilities as supplementary; the repository's engineering, documentation, and verification rules must remain understandable and enforceable without them.



## Sources of truth

- The root README is the project entry point. When consulting material under `docs/`, AI agents must first read `docs/manifest.md` or its equivalent Chinese version `docs/manifest.zh-CN.md`, then read only the authorities and supporting material relevant to the task. Read archived material only when tracing historical evidence.
- Product behavior and effective decisions: explicitly accepted sections in `docs/decisions/<module>.md`; interface signatures and semantics: the canonical `PlatformApi` contract. Proposed behavior and static implementation observations are not automatically accepted requirements.
- Rules that must already hold: `docs/invariants.md`.
- Current code structure and implementation boundaries: `docs/architecture.md`.
- Domain terminology and user-facing vocabulary: `docs/glossary.md`.
- Decision navigation: `docs/decisions.md` points to maintained module decisions and module/year history; archives preserve provenance and never override current definitions.
- `docs/status.md`, `docs/instructions.md`, `docs/worklog.md`, `docs/plans/`, and `docs/handoffs/` describe operating state; they are not programming-rule authorities.

If two authoritative sources disagree, do not silently choose one. Verify the implementation and update the stale source in the same change.

## Working discipline

- For analysis, diagnosis, or review requests, inspect and report without modifying production code.
- For implementation or fix requests, make the required change and complete risk-proportionate verification.
- Read the relevant implementation, tests, invariants, and design documents before editing.
- Find and fix the root cause. Do not hide defects with silent fallbacks, duplicated branches, or unrelated refactors.
- Keep changes scoped to the requested behavior and preserve unrelated existing worktree changes.
- A change is not complete until relevant verification has run or the unverified portion and reason are stated.



## Platform model and backend boundary

- v2 defines the target product model and ideal `PlatformApi` contract.
- The `prod` alias is the current live v1 production source; `dev` is a v1 development alias. Other published aliases are configured by environment files.
- `mock` is the target-contract reference; `v2server` is the future v2 backend integration. Adapter families are `mock`, `v1`, and `v2server` (`config/adapter-set.ts`). Historical names `v2mock`, `v1server`, and `v1prod` are not current selection aliases.
- Feature code, Shell, and Design System access backends only through `@core`.
- Backend paths, wire payloads, field dialects, enum crosswalks, and venue-specific capability corrections belong only in `src/core/adapters/*`.
- `modules/*` must not import one another. Promote cross-vertical behavior to `@shell`, `@core`, or `@ds`.
- When live v1 behavior and the target v2 contract differ, preserve the live behavior in the v1 adapter and record the target-contract delta; do not bend feature code around v1.



## Data and financial correctness

- Never fabricate a venue-owned value. Missing data remains `null` or raises an explicit malformed/unsupported error.
- Never replace missing money, price, quantity, enum, timestamp, or status with `0`, an empty string, a guessed value, a mid price, or a borrowed field.
- Financial values are parsed, calculated, and rendered with `BigNumber`/`Decimal`; JavaScript floating-point arithmetic must not touch financial values.
- Price and quantity precision comes from venue-provided market metadata and the shared `@core/format` authority.
- Degradation paths must log or surface the failure. Bare `catch {}` on data reads is forbidden unless storage/browser capability absence is explicitly the expected result.
- Before claiming a live v1 field or capability is absent, inspect the v1 frontend usage, the live route payload, and the live UI behavior.



## Shared frontend authorities

- Reuse existing `@ds` primitives and `@core` domain authorities before creating feature-local behavior.
- Foundational UI patterns belong in `@ds`; foundational domain behavior belongs in `@core`.
- Inline help and reject/cancel reasons use `InfoTip`; truncated money uses `MoneyValue`; truncated labels use `TruncatedText`; shrinking single-line heroes use `FitText`.
- Floating UI uses `anchoredPopover`; never position tips with feature-local `top/bottom: calc(100% + ...)` CSS.
- Mobile is `≤768px`; use the named breakpoint tokens and `@ds/composables/useMediaQuery`, not new arbitrary breakpoints.
- User-facing strings use i18n. `en-US` is the canonical key tree and `zh-CN`/`zh-TW` must remain type-compatible.
- Venue data such as tickers and team names is backend content, not an i18n key.
- Orders and positions must continue to use the shared holdings authorities and public grid/table primitives.



## Authentication posture

- v1 (including `dev`/`prod`) uses its venue-issued `x-auth-token`. Because v1 has no refresh-token cookie, the adapter persists the token in a namespaced **JS-readable Cookie** (not HttpOnly, not `localStorage`) to survive reloads and still injects `x-auth-token`. Treat this as an explicit legacy XSS-readable risk, not the target architecture.
- v2 (`v2server`) keeps the access token in memory and relies on a backend-issued `Secure`, `HttpOnly`, `SameSite` refresh cookie. Automatic refresh behavior may be claimed only after it is implemented and tested.
- Authentication state and user-scoped caches must be cleared together on logout or token rejection.
- Verification environment/account configuration lives in `test/config/<environment>.local.json`; write restrictions follow that configuration and `docs/best-practices/trading-verification.md`.



## Specification-driven changes

- A new user flow, public primitive, cross-module behavior, domain type, or `PlatformApi` contract change requires an accepted design/specification before implementation. Fold accepted behavior and its effective decision into the owning module document; keep the review draft as evidence, not a parallel authority.
- Specifications must state goals, non-goals, behavioral states, contract changes, acceptance criteria, migration/rollout impact, and verification evidence.
- Proposed or incomplete behavior belongs in designs, plans, or roadmap documents; it must not be written as an invariant.
- If implementation changes an accepted behavior, update the relevant specification, decision, and invariant in the same change.



## Documentation lifecycle

- Maintain documentation according to this section and the roles and navigation in `docs/manifest.md` / `docs/manifest.zh-CN.md`. These overviews provide equivalent navigation and maintenance guidance for `docs/`; this file remains the project-rule authority.
- Documentation overviews and README files must provide complete English and Simplified Chinese versions with reciprocal language links (separate files or sections). Keep their scope, rules, status, and links equivalent. Other documents follow the developer's current language preference; translation is not required solely for consistency.
- Choose the documentation shape according to actual volume and complexity: a topic may remain `docs/<topic>.md`, or use `docs/<topic>/` when independently maintained subtopics warrant it. Do not introduce a universal `docs/modules/` layer. The large decision collection uses `docs/decisions/<topic>.md`, maintaining effective decisions together with the context needed to understand them; `docs/decisions.md` is its entry. `docs/designs.md` maps historical designs to maintained summaries; the old collection is archived as a whole. Create new review drafts only when needed, using the owning topic or an explicitly scoped design collection. Execution/verification records belong in `docs/plans/`, raw source evidence in `docs/references/`; tool-named paths are not authorities.
- Keep one maintained source for each rule or behavior. Maintain a complete module context in one file by default; add a module only for an independent responsibility and reason to change. Keep global invariants, terminology, architecture and worklog as single maintained files. Preserve stable IDs and historical attribution, and update affected links and indexes. Do not create one file per decision or split solely to meet a line limit.
- Mark proposed, accepted, implemented, verified, superseded, and historical claims explicitly where applicable. Preserve dates, authors/attribution, reasons, and replacement links when recording changes; do not invent missing attribution or infer completion from an old date. A documentation review does not certify runtime behavior.
- Treat persistent documentation as part of the product: when reading an authoritative or operational document, compare its material claims with the relevant implementation, configuration, tests, and live evidence. Correct or consolidate it in the same change when it is stale.
- Do not preserve contradictory current guidance. If the difference is substantial, first capture the verified current rule in the appropriate authoritative document, then archive the obsolete document or section with its date and reason; archived material is evidence, never a source of current requirements.
- Keep current documents concise and single-purpose. `status.md` contains only the current snapshot and open items; `instructions.md` contains only active operator directives; `worklog.md` remains one file and retains the most recent 90 days by default. Review at least monthly and at milestone closeout; age-based archiving applies only after 90 days. The only early-archive exception is work content confirmed to no longer match the actual project, with a specific reason and replacement reference. Do not archive recent entries merely because a task is complete, a session ended, or the log is long. First carry unresolved actions into current topic open items or status. Valid definitions and unrevoked operator directives never expire solely because of age.
- For small changes with limited impact, record the date, change description and session summary in a comment near the affected code or document; do not add a worklog entry. Use `YYYY-MM-DD | change | session summary` (the reason/request and resulting conclusion, not an operation transcript or sensitive data). Each such comment retains at most the latest three dated records; keep necessary explanatory comments independently and rely on Git history for older change records. Markdown may use HTML comments. This exemption concerns change logging only: still update any changed behavior/contract authority and perform appropriate verification. Changes that alter cross-topic behavior, public contracts, important business flows, or financial/security rules have broader impact and require normal documentation and worklog treatment; a small presentation or wording change is judged by its actual impact, not by the page category.
- Create a dated plan in `docs/plans/` only for work that is active and has an owner, scope, acceptance criteria, and completion/exit condition. Existing records with unclear ownership or unverified closure must be marked for lifecycle review; never infer completion from age. On completion, cancellation, supersession, or loss of an active owner, move it to `docs/archive/plans/<year>/` and preserve its outcome.
- Create a handoff in `docs/handoffs/` only when another session needs actionable, current context. Archive it when its work is completed, superseded, or no longer has an owner. Remove the old path after archiving; do not leave redirect stubs or an empty directory/index. Create the handoff directory only when a current handoff is needed. At each milestone closeout and at least monthly, archive closed handoffs and roll worklog history older than 90 days (or confirmed project-inconsistent content), and superseded status/instruction history into `docs/archive/<category>/<year>/`.
- Research, reports, and verifications are evidence. Keep them active only while they support an unresolved decision or implementation; otherwise archive them under `docs/archive/<category>/<year>/`. Keep reusable conclusions in a design, decision, invariant, reference, or best-practice document before archiving the raw investigation.
- Preserve legacy archives in their original file units, names, contents and collection structure. Do not retrospectively split, regroup or combine old files into the new topic layout; extract current conclusions into maintained topic documents without reshaping the original evidence. The legacy decision log stays one `docs/archive/decisions/2026/decisions.md`; old directory collections retain their own paths under the archive. Only records created and maintained under the new topic layout are subsequently archived under `docs/archive/decisions/<topic>/<year>/`, retaining that new source structure. Worklog continues its separately defined 90-day rolling policy, with whole legacy source snapshots preserved as evidence. Preserve the archive and Git history; update affected links, indexes and both overviews whenever archiving.



## Verification

- Verify against applicable specifications/cases, or the current request and affected behavior. Cover normal paths, key boundaries, failures, and regressions proportionate to risk; report omitted checks.

### Preparation, evidence, and completion

- Before each run, read the `test/config/<environment>.local.json` for the environment URL, account, and write permissions; confirm runtime/browser availability and ask only for missing or invalid configuration. Follow `docs/best-practices/trading-verification.md`: non-trading probes retain the interceptor and verify `writes attempted: NONE`; trading checks follow authorized limits and cleanup requirements.
- Keep artifacts under `test/`, with screenshots in `test/screenshots/<delivery>/`. Use the development document's filename stem, otherwise the first request timestamp (`YYYY-MM-DD-HHmm-<request>`, project timezone; use first execution time if unavailable). Reuse this directory for retests, distinguish attempts, and retain failure evidence.
- Record expected/actual results, status, environment, and evidence in the existing cases/delivery record or conversation. Name screenshots by case and page/result, mask unrelated personal data, and display necessary screenshots with absolute paths.
- Claim passed only when required checks pass with complete evidence; report failures, blockers, and partial/unexecuted coverage. Fix within authorized scope, then rerun failed checks and affected regressions.

### Methods and executors

| Check | Method | Executor |
| --- | --- | --- |
| Logic and interface contracts/API | Local or target-service unit, contract, and API checks with assertions (project scripts in `package.json`: `test`, `rules:check`, `typecheck`, `lint`, `build:dev`). | Current agent locally. |
| Scriptable Web checks | Playwright steps and state/result assertions; screenshots or screenshot comparison as needed. | Test subagent. |
| Web operations tools cannot script, or checks requiring human judgment | Browser operation, including `browser-use`; automate steps/screenshots where possible, then assess explicit criteria. | User chooses self-execution or a browser-operating subagent. |

- Reuse a valid executor choice; otherwise ask once when a choice is required. For user execution, provide the URL, steps, expected results, and evidence requirements, then obtain actual results and evidence.
- Delegate with the baseline/cases, scope, URL, configuration path and environment/account identifiers, steps, expected results, and evidence directory; require actual results, runtime environment, and evidence paths back.
- Assert results where possible; screenshots alone do not prove correctness, and visual comparison requires a confirmed baseline. Missing execution capability blocks the affected checks.

<!-- 2026-10-12 | Codex: simplify verification and migrate accounts | User requested concise rules and local environment configuration. -->
