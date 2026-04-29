## Why

Indooro's Admin Platform currently exposes operational data and management APIs without real authentication or authorization. Keycloak is needed now to move the project from an open prototype to a controlled admin system before the admin workflows become feature-complete and deployable on LeoCloud.

## What Changes

- Add Keycloak-backed login for the Admin Platform served under `/admin` and `/admin/*`.
- Protect the existing admin API surface:
  - `/api/admin/logs`
  - `/api/admin/error-logs`
  - `/api/regions`
  - `/api/stores`
  - `/api/beacons`
  - `/api/stores/{storeId}/layout/*`
- Keep customer/mobile and catalog/layout read APIs public for this sprint unless a protected admin route explicitly uses them:
  - `/api/mobile/stores`
  - `/api/mobile/stores/by-beacon`
  - `/api/mobile/stores/{storeId}/layout/current`
  - `/api/products`
  - `/api/categories`
  - `/api/layout`
- Enforce the business roles `admin`, `region-manager`, and `store-manager` on protected admin functions.
- Add application database mapping from a stable Keycloak subject to Indooro role and region/store scope.
- Filter admin-visible data by role:
  - `admin` sees all regions, stores, beacons, layouts, and logs.
  - `region-manager` sees and manages data for the assigned region.
  - `store-manager` sees and manages data for the assigned store.
- Add logged-in user context and logout controls to the Admin UI.
- Add a modern Keycloak dev/demo setup using realm import instead of legacy Keycloak images or old `/auth/realms/...` URLs.
- Document and configure the LeoCloud deployment path for Keycloak/OIDC settings.

The sprint demo proves that an unauthenticated user is redirected to login, authenticated users see their identity in the Admin UI, role and scope limits are enforced by the backend, logout ends the admin session, public mobile/customer routes still work, and the deployment configuration is reproducible.

## Capabilities

### New Capabilities

- `admin-authentication`: Login, logout, unauthorized handling, and session-backed Admin Platform protection.
- `admin-role-access-control`: Role-based admin API authorization and region/store scope filtering.
- `keycloak-deployment`: Local/demo Keycloak realm import and LeoCloud OIDC deployment expectations.

### Modified Capabilities

- None. No existing OpenSpec capabilities are present in `openspec/specs/`.

## Impact

- Backend dependencies: add Quarkus OIDC and security support dependencies.
- Backend configuration: update `backend/indooro_server/src/main/resources/application.properties` for OIDC web-app login, protected paths, public paths, and deployable environment variables.
- Backend database: add Flyway migration, Panache entity, repository/service support for user access assignments keyed by Keycloak `sub`.
- Backend APIs: add authentication/role annotations and scope checks to admin resources and services; add a current-user endpoint for the Admin UI.
- Frontend admin resources: show current user and role, handle unauthorized API responses, and provide logout.
- Dev/demo setup: add Keycloak realm import and container configuration using a modern Keycloak image.
- Deployment: update `k8s/*` and `DEPLOYMENT.md` with Keycloak, client secret, public hostname, redirect/logout URI, and verification steps.
- Tests/verification: add focused backend tests where feasible and run Maven/OpenSpec verification before archive.
