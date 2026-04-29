# Keycloak Auth Verification

Use these checks for the `keycloak-user-management` sprint demo.

## Local Prerequisites

1. Start Keycloak:

   ```bash
   docker compose up keycloak
   ```

2. Start PostgreSQL and create at least one region/store if testing scoped users.
3. Start the Quarkus backend with the default local OIDC settings.

## Protected Admin Checks

- Anonymous browser request to `/admin/` redirects to Keycloak login.
- Login as `indooro-admin` with password `admin` opens the Admin Platform.
- `/api/admin/me` returns subject `11111111-1111-1111-1111-111111111111`, role `admin`, and empty region/store scope.
- Logout through `/admin/logout` returns to `/`.
- Reopening `/admin/` after logout starts a fresh login flow.

## Role And Scope Checks

- `admin` can list all regions, stores, beacons, store layouts, audit logs, and error logs.
- `region-manager` needs a row in `user_access_assignments` with subject `22222222-2222-2222-2222-222222222222` and a real `region_id`.
- `region-manager` only receives stores in the assigned region and receives an authorization failure for another region/store.
- `store-manager` needs a row in `user_access_assignments` with subject `33333333-3333-3333-3333-333333333333` and a real `store_id`.
- `store-manager` only receives the assigned store and receives an authorization failure for another store layout or beacon assignment.
- A Keycloak role that does not match the active database assignment role is rejected.
- A Keycloak user without an active database assignment is rejected.

## Public Route Checks

These routes must not redirect to Keycloak:

```bash
curl -i http://localhost:8080/api/mobile/stores
curl -i http://localhost:8080/api/mobile/stores/by-beacon
curl -i http://localhost:8080/api/products
curl -i http://localhost:8080/api/categories
curl -i http://localhost:8080/api/layout/current
```

## Build Verification

On Java 24 with this Quarkus version, pass the Byte Buddy flag explicitly:

```bash
cd backend/indooro_server
sh mvnw test -Dnet.bytebuddy.experimental=true
```
