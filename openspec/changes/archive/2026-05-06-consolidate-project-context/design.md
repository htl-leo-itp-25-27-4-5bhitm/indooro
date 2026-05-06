## Context

The repository already contains working application code and substantial documentation, but the durable OpenSpec state only covers the previous Keycloak sprint. The existing permanent specs do not yet describe the whole Indooro system: mobile store detection, product search, layout management, deployment operations, the domain model, planned PDF import, and the FSD boundaries are scattered across Markdown documents outside `openspec/`.

OpenSpec should be the first place a future coding agent or developer reads before changing behavior. The design for this change is therefore to convert the existing documentation into permanent capability specs while preserving clear boundaries between implemented behavior, planned behavior, and open questions.

Source documents used:
- `README.md`
- `DEPLOYMENT.md`
- `documentation/API_DOCUMENTATION.md`
- `documentation/SPRINT_ADMIN_PLATFORM_COMPLETE_DOCUMENTATION.md`
- `documentation/RUNTIME_OBJECT_DIAGRAM_DATABASE.md`
- `documentation/KEYCLOAK_SPRINT_CONCEPT_OPENSPEC.md`
- `documentation/KEYCLOAK_AUTH_VERIFICATION.md`
- `documentation/KEYCLOAK_NEW_CHAT_OPENSPEC_PROMPT.md`
- `documentation/fsd_fragerunde1.md`
- `documentation/CODEX_FSD_QUESTIONS_TEMPLATE.md`

## Goals / Non-Goals

**Goals:**

- Make `openspec/config.yaml` a rich project-context entry point for future OpenSpec changes.
- Add permanent capability specs for the full Indooro MVP and near-term planned scope.
- Update existing Keycloak/Auth specs so they no longer have placeholder purpose text.
- Preserve the existing OpenSpec workflow: proposal -> specs -> design -> tasks -> verification -> archive.
- Keep requirements testable through scenarios with observable outcomes.
- Distinguish public customer/mobile routes from protected admin routes.
- Capture LeoCloud deployment assumptions and verification expectations.

**Non-Goals:**

- This change does not modify Java, JavaScript, Swift, Docker, Kubernetes, database migrations, or CI/CD behavior.
- This change does not introduce a new product-by-category-code route.
- This change does not implement the future PDF import pipeline.
- This change does not change the Keycloak realm, demo users, secrets, or LeoCloud deployment.
- This change does not resolve open FSD questions that are explicitly still undecided.

## Decisions

### Decision 1: Permanent Context Lives In OpenSpec Specs

The durable project contract will be represented as capability specs in `openspec/specs`, not as one giant narrative document.

Rationale: OpenSpec specs are searchable, validateable, and directly tied to future change proposals. A single long document would be easier to write but harder to use during implementation.

Alternative considered: Put everything into `openspec/config.yaml`. This was rejected because config context is useful for instructions but not a structured behavioral contract with requirements and scenarios.

### Decision 2: Use Capability Boundaries Matching System Responsibilities

The new capabilities are split by responsibility: project overview, domain model, admin management, mobile detection, product search, layout management, PDF import, and deployment operations.

Rationale: These boundaries match how the codebase and documentation are already organized and make future changes easier to scope.

Alternative considered: Split by technology layer only, such as backend/frontend/deployment. This was rejected because user-visible requirements often cross layers, especially layout and auth behavior.

### Decision 3: Preserve Existing Auth Capabilities And Modify Them

The existing `admin-authentication`, `admin-role-access-control`, and `keycloak-deployment` specs will be modified rather than replaced.

Rationale: They were created by the previous archived Keycloak change and already represent real project history. Modifying them keeps continuity and avoids losing traceability.

Alternative considered: Create one new `security` spec and deprecate the three existing specs. This was rejected because the current split is readable and maps well to login/session behavior, role/scope rules, and Keycloak operations.

### Decision 4: Planned Work Is Captured Explicitly As Planned Requirements

Documentation about future work, especially PDF import and some routing/search improvements, is captured as planned capability requirements where appropriate and marked by requirement wording rather than silently treated as implemented code.

Rationale: The user asked for the whole project context, including documentation that describes target behavior. Future implementers need to know these expectations without assuming they already run in production.

Alternative considered: Only document implemented runtime behavior. This was rejected because it would omit important FSD decisions and leave future work under-specified.

### Decision 5: OpenSpec Config Becomes The High-Level Project Brief

`openspec/config.yaml` will contain the broad project context, source documents, architecture map, route boundary summary, FSD rules, and known open points.

Rationale: OpenSpec instructions include config context in artifact-generation prompts, so this is the right place to seed future changes with Indooro-specific facts.

Alternative considered: Keep config minimal and rely on specs only. This was rejected because future changes benefit from concise global context before choosing relevant specs.

## Risks / Trade-offs

- Large specs can become stale -> Mitigation: future changes must modify affected specs during implementation and run OpenSpec validation before archive.
- Some documentation may describe planned behavior, not implemented behavior -> Mitigation: planned capabilities are named explicitly, and code-changing changes must verify actual runtime behavior separately.
- PDF details could not be deeply extracted from the supporting PDFs during this consolidation -> Mitigation: the PDFs are referenced as source artifacts and should be inspected explicitly if a future change depends on their internal content.
- Deployment details can drift quickly -> Mitigation: deployment specs require concrete namespace, host, image tag, manifest, secret, and verification evidence for future deployment changes.
- Product/category route assumptions can be confused with implemented routes -> Mitigation: the specs state that a dedicated products-by-category-code route is not confirmed unless a future change adds it.

## Migration Plan

1. Create this OpenSpec change using the `spec-driven` schema.
2. Add proposal, design, tasks, and delta specs for all new and modified capabilities.
3. Update `openspec/config.yaml` directly because it is project context rather than a generated permanent capability spec.
4. Validate the change and all specs with OpenSpec strict validation.
5. Archive the change so the delta specs become permanent specs under `openspec/specs`.
6. Review `git diff` to confirm only OpenSpec documentation files changed.

Rollback is straightforward because this change does not alter runtime behavior: revert the OpenSpec documentation commit or restore the previous `openspec/` files.

## Open Questions

- The detailed content of `documentation/IndooroScrumRetrospektive4Ls.pdf` and `documentation/Layoutplan-Testraum.pdf` should be extracted in a future change if those PDFs become implementation inputs.
- The exact production PDF import workflow, parser, and operator UX remain future work.
- A dedicated product lookup route by category code remains unconfirmed.
- Final iOS BLE beacon format details depend on the physical iBKS USB beacon configuration.
