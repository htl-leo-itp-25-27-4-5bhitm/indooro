## Context

Product catalog data is currently stored in OpenSearch. The Admin Platform writes products through `POST /api/admin/products`, while public product routes remain anonymous read/search surfaces. Role enforcement already uses `@RolesAllowed("admin")` plus `AdminAccessService.requireAdmin()` in `AdminProductResource`.

## Decisions

- Add `DELETE /api/admin/products/{id}` instead of overloading the public `/api/products` resource.
- Delete the OpenSearch document by the same product id used for indexing.
- Return `204 No Content` after a successful delete and `404 Not Found` when the product id does not exist.
- Keep the Admin UI optimistic only after the API succeeds: remove the product from local state after the delete request returns.

## Non-Goals

- No bulk delete.
- No soft-delete or audit-log expansion for OpenSearch products.
- No change to anonymous product search/read routes.
- No database migration, because products are OpenSearch documents rather than PostgreSQL entities.

## Risks

- OpenSearch index availability still determines whether product mutations succeed.
- A deleted product disappears from public search and mobile product navigation, so the UI asks for confirmation before deletion.
