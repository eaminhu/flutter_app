# Documentation overview

**English** | [简体中文](manifest.zh-CN.md)

Start with current documents; dated plans and verifications preserve stage evidence.

- [Project constraints](project-rules.md): established engineering constraints and Web↔Flutter mappings; Agent instructions remain in AGENTS.md / CLAUDE.md.
- [Invariants](invariants.md): rules that must already hold, each cross-referenced to its source.
- [Glossary](glossary.md): domain terminology and user-facing vocabulary.
- [Mobile design](design-system.md): accepted visual direction, current components and remaining design scope.
- [Design tokens](design-tokens.md): actual Forui 0.27.5 colors, typography, radii and local spacing; trading tokens remain undefined.
- [Architecture](architecture.md): current dependencies and implementation boundaries.
- [Decisions](decisions.md): accepted scope and authorization, with historical stages identified.
- [Current state](status.md): implemented behavior and remaining scope.
- [Handoff](handoff.md): actionable environment, verification and next-stage context.

## Design and execution evidence

- [Accepted foundation design](designs/2026-10-12-flutter-foundation.md): overall mobile Spot target.
- [Network/session design](designs/2026-10-13-network-session-foundation.md), [plan](plans/2026-10-13-network-session-foundation.md) and [verification](references/2026-10-13-network-session-verification.md): implemented phase and Android evidence; real-account login remains unverified.
- [Foundation plan](plans/2026-10-13-foundation-framework.md) and [verification](references/2026-10-13-foundation-verification.md): earlier framework-stage record.
- [Framework dependencies](references/framework-dependencies.md): initial approved dependencies; later versions are recorded in handoff and network/session verification.
- [Environment plan](plans/2026-10-12-environment-and-bootstrap.md), [installation evidence](references/windows-install-checklist.md), [bootstrap verification](references/2026-10-12-bootstrap-verification.md) and [Android Studio/emulator verification](references/2026-10-13-android-emulator-verification.md).

Current documents distinguish accepted direction, implemented behavior and verified evidence. Planned capabilities are not effective invariants. Update documentation alongside affected code; keep one maintained source per concept. Documentation review and automated tests do not certify real-account trading or iOS acceptance.

<!-- 2026-10-13 | Documentation inventory | Added constraints, design/token snapshots and repaired handoff navigation. -->
<!-- 2026-10-20 | Rule-set alignment | CLAUDE.md rewritten Flutter-native; added invariants.md and glossary.md authorities. -->

