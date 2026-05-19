# Design: Add Admin Product Management

## Context
The project already has public catalog read/search routes under `/api/products` and existing write behavior for indexing products. Because `application.properties` currently treats `/api/products/*` as public to support customer search, the Admin Platform needs a protected admin namespace for product maintenance instead of relying on the public path.

## Decisions
- Add `/api/admin/products` as the Admin Platform product maintenance API.
- Require the `admin` role at the resource level and call the existing `AdminAccessService.requireAdmin()` check so the Keycloak role and Indooro access assignment must both authorize the action.
- Reuse `OpenSearchService` and the existing `Product` model so no new product persistence model is introduced.
- Validate the required product fields before indexing:
  - `id` must be present.
  - `name` must be non-empty.
  - `layoutCode` must be non-empty.
  - `price` must be present and non-negative.
- Add the product form to the Admin Platform dashboard rather than the canvas-only layout editor, because product catalog maintenance is a catalog-admin workflow and should not be confused with drawing layout geometry.

## UI Behavior
The Admin Platform loads the current user through `/api/admin/me`. Product maintenance controls are rendered only for `admin`. If a non-admin accesses the UI, product navigation and forms are hidden. If a non-admin calls the protected API directly, the backend rejects the mutation.

## Open Questions
- Bulk product import remains a separate maintenance/import workflow and is not expanded in this change.
- Product deletion/archive is intentionally out of scope because the current catalog model only defines indexing/update behavior.
