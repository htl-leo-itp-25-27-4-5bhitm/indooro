# Change: Add Admin Product Management

## Why
Admins need a maintained product catalog workflow inside the Admin Platform so they can create or update products with the fields required by customer search and layout navigation. Today product writes exist as catalog endpoints, but there is no role-aware Admin UI workflow that makes product maintenance explicit and safe.

## What Changes
- Add an admin-only product management surface to the Admin Platform.
- Add a protected backend endpoint under the admin API namespace for creating/updating catalog products.
- Keep public customer product search and read routes public.
- Document the role boundary so only users with the `admin` role can create or update products from the Admin Platform.

## Impact
- Affects Admin Platform UI, admin role access control, and catalog maintenance behavior.
- Does not change public customer product search semantics.
- Product documents continue to use the existing OpenSearch-backed product model: `id`, `name`, `price`, and `layoutCode`.
