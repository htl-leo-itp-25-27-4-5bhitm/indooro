## Why

The first OpenSpec consolidation captured the broad Indooro domains, but the final audit found durable behavior in the legacy documentation and current project tree that was still under-specified, especially in the iOS navigation stack, catalog maintenance APIs, PDF conversion/export, customer web view, and layout data contract.

This change closes those gaps so `openspec/specs/` can serve as the repository source of truth before the next feature request starts.

## What Changes

- Add explicit mobile positioning and route guidance requirements for iBeacon/iBKS hardware, Blue Dot behavior, map matching, live rerouting, offline layout fallback, iOS scope, and performance targets from the FSD and Swift code.
- Add current local iOS shopping-list behavior, transfer files, and multi-stop route preview as a documented app capability while preserving that backend/shared shopping-list workflows remain future scope.
- Add the current AR route preview/navigation overlay as an experimental mobile capability found in the app tree.
- Add a customer web experience capability for the hosted `/customer/` page and its legacy layout dependency.
- Add catalog maintenance operations for product/category write endpoints, OpenSearch index setup/reset, health checks, PDF export, and import expectations.
- Modify existing layout, PDF, product, admin, mobile detection, domain model, deployment, and project overview specs where legacy docs were more precise than the current specs.
- Update `openspec/config.yaml` with the audit findings, corrected layout-code format, current iOS source layout, and follow-on agent rules.

## Capabilities

### New Capabilities
- `mobile-positioning-navigation`: iOS customer positioning, BLE/iBeacon scanning, Blue Dot confidence, route line behavior, live rerouting, offline map fallback, and performance targets.
- `mobile-shopping-lists`: local shopping-list management, item status, route stop ordering, import/export transfer packages, and current backend boundary.
- `mobile-ar-navigation`: ARKit route overlay, map/world alignment, calibration, route preview waypoints, and blocked states.
- `customer-web-experience`: hosted customer web view, public search/map behavior, and legacy layout compatibility.
- `catalog-maintenance-operations`: OpenSearch catalog setup/reset/write endpoints, product/category bulk operations, health check, and PDF export.

### Modified Capabilities
- `project-overview`: clarify MVP boundaries against app features that now exist locally but are not backend/shared product scope.
- `product-catalog-search`: correct layout-code format to slash-separated `categoryCode/meter/fach/reihe`, add category lookup/no-result/search-latency behavior.
- `store-layout-management`: add grid/metre scale, access points, zoom/rotation, layout JSON fields, beacon placement, editor-context, and legacy layout compatibility.
- `pdf-catalog-import`: distinguish current PDF-to-JSON and PDF-export utilities from the planned production ingestion pipeline.
- `admin-platform-management`: add dashboard/filter/editor/log UI requirements and beacon validation details from sprint documentation.
- `deployment-operations`: add hosted web surfaces, mobile base URL requirement, Java 24 build flag, and LeoCloud import/data caveats.
- `mobile-store-detection`: make the by-beacon request/response behavior and active-store filtering explicit.
- `domain-model`: add database uniqueness and lifecycle constraints from the runtime object diagram and sprint docs.

## Impact

- OpenSpec artifacts under `openspec/changes/consolidate-legacy-doc-coverage/`.
- Permanent specs under `openspec/specs/` after archive.
- `openspec/config.yaml` agent context and rules.
- No runtime source code changes are intended.
