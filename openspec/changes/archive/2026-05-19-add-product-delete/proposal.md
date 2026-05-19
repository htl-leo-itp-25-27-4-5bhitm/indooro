## Why

Admins can already create and update product catalog entries, but they cannot remove products that are wrong, obsolete, or accidentally created. This leaves stale OpenSearch documents visible in public product search and mobile navigation flows.

## What Changes

- Add a protected admin product delete route for deleting one product by product id.
- Add a delete action to the Admin Platform product list.
- Keep product deletion restricted to authenticated `admin` users.
- Keep public product search/read routes unchanged.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `admin-platform-management`: Product management includes deleting product catalog documents.
- `admin-role-access-control`: Product delete is treated as an admin-only product catalog mutation.

## Impact

- Backend admin API under `/api/admin/products`.
- OpenSearch product index document operations.
- Static Admin Platform product list UI.
- OpenSpec product-management and admin role access requirements.
