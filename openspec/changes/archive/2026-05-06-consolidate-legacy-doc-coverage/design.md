## Current State

The existing specs validate and every requirement has scenarios, but the audit found several differences between the permanent specs, legacy documentation, and the current project tree:

- `documentation/fsd_fragerunde1.md` contains precise mobile positioning, routing, performance, offline, language, and hardware constraints that were only partially represented.
- `documentation/API_DOCUMENTATION.md` describes product/category write and OpenSearch maintenance endpoints that were outside the current public search spec.
- `documentation/SPRINT_ADMIN_PLATFORM_COMPLETE_DOCUMENTATION.md` contains concrete UI, editor-context, layout JSON, beacon validation, and legacy customer/layout boundaries that needed sharper requirements.
- Current Swift code under `swift/indooro-/indooroApp` contains shopping-list and AR navigation behavior not represented in OpenSpec.
- The current product layout code is slash-separated, for example `310/1/1/1`, while the config/spec context still included a hyphenated example.
- The two PDFs were inspected. `Layoutplan-Testraum.pdf` contains a simple test-room sketch with `Regal`, `Beacon`, and approximate dimensions `~5` and `~9`; the Scrum retrospective contains process learnings rather than durable runtime requirements.

## Decisions

- Keep permanent behavior organized by capability instead of by source document.
- Treat implemented or source-present behavior as spec-covered even when it came from code rather than legacy docs.
- Separate customer-facing search behavior from catalog maintenance/write operations.
- Separate map/layout semantics from mobile positioning and route guidance to keep requirements discoverable.
- Document shopping-list and AR app behavior as current app capabilities, but keep shared backend shopping lists, Android parity, analytics, live inventory, and production PDF ingestion out of MVP unless a future change scopes them.
- Use direct OpenSpec delta specs and archive them into main specs because this is documentation/spec consolidation, not runtime implementation.

## Alternatives Considered

- Directly edit `openspec/specs/` only: rejected because the user specifically requested ADDED/MODIFIED delta specs and traceability.
- Create one large `project-overview` addition: rejected because future agents need domain-specific behavior near the relevant capability.
- Treat shopping lists and AR as out of scope because older FSD answers called them future work: rejected because the current project tree contains concrete app implementations that should not remain invisible to OpenSpec.

## Risks

- Some app capabilities may be experimental or demo-only. The specs therefore avoid promising production backend synchronization or Android parity.
- Some legacy documentation predates Keycloak. The specs preserve the current Keycloak-protected boundary and mark older anonymous admin assumptions as historical.
- The customer web view still uses the legacy global layout API. The specs document this compatibility boundary instead of forcing an architecture migration in this audit.

## Verification Strategy

- Run OpenSpec validation for the change and all specs.
- Confirm no active changes remain after archive.
- Use targeted text checks for scenario coverage and corrected layout-code examples.
- Do not run runtime tests because this change intentionally updates OpenSpec documentation/configuration only.
