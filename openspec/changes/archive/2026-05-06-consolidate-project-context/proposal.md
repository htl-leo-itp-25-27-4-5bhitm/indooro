## Why

Indooro has accumulated important project knowledge across README files, sprint documentation, deployment notes, API documentation, Keycloak notes, runtime object diagrams, and FSD answers. That knowledge is currently hard to review as one system contract, so future changes risk re-learning existing decisions, accidentally protecting public mobile routes, copying outdated Keycloak examples, or implementing features outside the MVP scope.

This change consolidates the full project context into OpenSpec so future work can start from durable capabilities, explicit requirements, and traceable architectural decisions instead of scattered documentation.

## What Changes

- Add a comprehensive OpenSpec project context to `openspec/config.yaml`, including source documents, architecture, roles, deployment assumptions, route boundaries, domain model, FSD rules, and known open points.
- Add permanent OpenSpec capabilities for the broader Indooro system beyond Keycloak authentication.
- Expand existing Keycloak/Auth capabilities with clear purpose text and additional scenarios around session state, public route boundaries, user identity, role agreement, and deployment verification.
- Document current implemented behavior separately from planned/future behavior where the source documentation describes requirements not yet fully implemented.
- Keep this as a documentation/specification consolidation change only; it does not change application runtime code.

## Capabilities

### New Capabilities

- `project-overview`: Project mission, MVP boundaries, stakeholders, architecture, source-of-truth rules, and OpenSpec governance.
- `domain-model`: Core Indooro domain entities, relationships, lifecycle rules, identifiers, and auditability.
- `admin-platform-management`: Admin Platform pages, protected admin resources, CRUD workflows, layout/admin operations, logs, and role-aware UI expectations.
- `mobile-store-detection`: Anonymous mobile store discovery, beacon identity exposure, BLE/manual fallback expectations, and public mobile route behavior.
- `product-catalog-search`: Product/category search behavior, OpenSearch expectations, layout-code semantics, and public catalog route boundaries.
- `store-layout-management`: Store-specific layout versioning, active layout publication, editor semantics, mobile layout consumption, and routing assumptions.
- `pdf-catalog-import`: Planned PDF/catalog import behavior, text-layer assumptions, JSON-first processing, failure handling, and audit expectations.
- `deployment-operations`: Local development, LeoCloud Kubernetes deployment, runtime components, verification commands, image/secret handling, and operational boundaries.

### Modified Capabilities

- `admin-authentication`: Replace placeholder purpose and clarify login, logout, current-user state, unauthorized behavior, and public route boundaries.
- `admin-role-access-control`: Replace placeholder purpose and clarify role/scope agreement, admin/region/store manager behavior, and scoped mutation expectations.
- `keycloak-deployment`: Replace placeholder purpose and clarify local/LeoCloud Keycloak behavior, modern container usage, realm import, and OIDC deployment verification.

## Impact

- Affected OpenSpec files:
  - `openspec/config.yaml`
  - `openspec/specs/**/spec.md`
  - `openspec/changes/consolidate-project-context/**`
- No backend Java, frontend JavaScript, Kubernetes, Docker, database migration, or mobile app runtime behavior is changed by this consolidation.
- Future implementation changes should reference these permanent specs before coding, especially for auth/public route boundaries, product search semantics, mobile beacon behavior, layout versioning, and LeoCloud deployment.
