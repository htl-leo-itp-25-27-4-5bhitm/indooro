## Context

Indooro has a Quarkus-served Admin Platform and existing admin APIs for regions, stores, beacons, layouts, audit logs, and error logs. These endpoints currently rely on the application data model but do not have runtime authentication, role checks, or region/store scope enforcement.

The user-facing/mobile APIs are already separate and should remain public for this sprint. The security boundary is the Admin Platform and admin API surface. The static Admin UI is same-origin with the backend, so a Quarkus OIDC web-app login/session flow is simpler and safer than adding a plain JavaScript token-handling flow.

References used for this design:
- OpenSpec OPSX workflow: local `workflows.md`, OpenSpec OPSX docs, and OpenSpec workflow guide.
- HTL Keycloak lecture notes: useful for Quarkus/Keycloak role concepts, but not copied verbatim because several labs are outdated and use legacy Keycloak paths/images.
- Quarkus OIDC web-app auth code flow: use `quarkus-oidc` with `quarkus.oidc.application-type=web-app`.
- Quarkus web endpoint authorization: use path permissions for public/protected route boundaries and annotations such as `@RolesAllowed` for endpoint authorization.
- Quarkus Keycloak authorization guide: `quarkus-keycloak-authorization` is intentionally excluded unless Keycloak Authorization Services become necessary.
- Keycloak container/import docs: modern containers import realm JSON from `/opt/keycloak/data/import` using `start-dev --import-realm` for dev/demo.

## Goals / Non-Goals

**Goals:**

- Require login for `/admin` and `/admin/*`.
- Protect `/api/admin/logs`, `/api/admin/error-logs`, `/api/regions`, `/api/stores`, `/api/beacons`, and `/api/stores/{storeId}/layout/*`.
- Keep `/api/mobile/*`, `/api/products`, `/api/categories`, and `/api/layout` public.
- Enforce `admin`, `region-manager`, and `store-manager` roles.
- Enforce region/store scope through the Indooro database, keyed by Keycloak subject.
- Show logged-in user identity and access scope in the Admin UI.
- Provide logout.
- Provide a modern local Keycloak realm import and a LeoCloud deployment path.

**Non-Goals:**

- Building a full user administration UI.
- Protecting mobile/customer APIs.
- Migrating product/catalog/layout legacy APIs into admin-only APIs.
- Using Keycloak Authorization Services or policy-enforcer for this sprint.
- Implementing multi-tenant realms or mobile OIDC clients.

## Decisions

### Decision: Use Quarkus OIDC web-app flow for Admin Platform login

Use `quarkus-oidc` with:

- `quarkus.oidc.application-type=web-app`
- `quarkus.oidc.auth-server-url=${OIDC_AUTH_SERVER_URL:http://localhost:8180/realms/indooro}`
- `quarkus.oidc.client-id=${OIDC_CLIENT_ID:indooro-admin-web}`
- `quarkus.oidc.credentials.secret=${OIDC_CLIENT_SECRET:dev-secret}`
- `quarkus.oidc.logout.path=/admin/logout`
- `quarkus.oidc.logout.post-logout-path=/`
- `quarkus.oidc.authentication.cookie-path=/`

Rationale: the Admin UI is served by Quarkus, so Quarkus can handle redirects, session cookies, code exchange, and logout. This avoids storing tokens in static JavaScript.

Alternative considered: SPA-style token handling in the static Admin UI. Rejected for this sprint because it increases token handling complexity without adding needed functionality.

### Decision: Use path permissions for route boundaries and annotations for admin roles

Configure HTTP permissions so `/admin*`, `/api/admin/*`, `/api/regions*`, `/api/stores*`, and `/api/beacons*` require authentication. Configure more specific public permissions for `/api/mobile/*`, `/api/products*`, `/api/categories*`, and `/api/layout*`. Quarkus path matching uses longest-path behavior, so specific public route rules must be explicit where they overlap broad protected paths.

Use `@Authenticated` or `@RolesAllowed({"admin", "region-manager", "store-manager"})` on admin resources. Use stricter `@RolesAllowed("admin")` for audit/error logs unless implementation proves managers need limited logs for the demo. Avoid protecting customer/mobile resources.

Rationale: this keeps coarse access policy visible at the resource boundary and lets service methods handle Indooro-specific scope rules.

Alternative considered: only HTTP path permissions. Rejected because endpoint-level role annotations are easier to review and test for resource classes.

### Decision: Enforce scope in application services

Add an auth/access service that resolves the current user from `SecurityIdentity` or OIDC claims and loads the active Indooro user access assignment by `sub`. The service exposes helpers such as:

- `currentUser()`
- `requireAnyAdminRole()`
- `requireAdmin()`
- `requireRegionAccess(UUID regionId)`
- `requireStoreAccess(UUID storeId)`
- `effectiveRegionFilter(UUID requestedRegionId)`
- `effectiveStoreFilter(UUID requestedStoreId)`

Resource methods keep role annotations; services apply scope filters and deny cross-scope reads/mutations. Store scope checks can derive region through `StoreRepository` when only a store id is available.

Rationale: Keycloak roles are coarse-grained identity facts; region/store assignment is Indooro domain data and belongs in the application database.

Alternative considered: Keycloak user attributes for region/store scope. Rejected because assignments need to reference Indooro domain rows and are likely to evolve into application-managed user administration.

### Decision: Add `user_access_assignments`

Add Flyway migration `V4__user_access_assignments.sql` with:

- `id UUID PRIMARY KEY`
- `keycloak_subject VARCHAR(120) NOT NULL`
- `username VARCHAR(120) NOT NULL`
- `email VARCHAR(254)`
- `role VARCHAR(40) NOT NULL`
- `region_id UUID NULL REFERENCES regions(id)`
- `store_id UUID NULL REFERENCES stores(id)`
- `status VARCHAR(20) NOT NULL`
- `created_at TIMESTAMPTZ NOT NULL`
- `updated_at TIMESTAMPTZ NOT NULL`

Constraints:

- role must be `admin`, `region-manager`, or `store-manager`.
- status must be `ACTIVE` or `DISABLED`.
- one active assignment per `keycloak_subject`.
- `region-manager` requires `region_id` and no `store_id`.
- `store-manager` requires `store_id`.
- `admin` requires neither `region_id` nor `store_id`.

Rationale: one active assignment keeps the sprint behavior deterministic and reviewable. The schema can be extended later if a user needs multiple store scopes.

Alternative considered: many-to-many user/scope tables now. Rejected to keep this sprint small and demoable.

### Decision: Keycloak realm/client setup

Use realm `indooro` and client `indooro-admin-web`.

Client:

- OIDC confidential client.
- Authorization code flow enabled.
- Direct access grants disabled unless needed for manual test scripts.
- Valid redirect URI locally: `http://localhost:8080/*`.
- Valid post-logout redirect URI locally: `http://localhost:8080/*`.
- LeoCloud redirect/logout URI: `https://it220209.cloud.htl-leonding.ac.at/*`.

Realm roles:

- `admin`
- `region-manager`
- `store-manager`

Dev users:

- at least one demo user for each role.
- access assignments seeded in Flyway or documented SQL using actual Keycloak subject values from the realm import.

Rationale: realm roles map cleanly to Quarkus role checks. One confidential web client matches Quarkus web-app flow.

### Decision: Local Keycloak setup

Add a local realm JSON under a repo path such as `keycloak/realm/indooro-realm.json` and mount it into a modern Keycloak container at `/opt/keycloak/data/import`. Start dev Keycloak with `start-dev --import-realm`, bootstrap admin credentials, and expose it on `localhost:8180`.

Rationale: Keycloak's current container/import flow supports startup import from `data/import`; the HTL lecture notes' old `jboss/keycloak:15.0.2` and `/auth` examples should not be reused.

### Decision: LeoCloud deployment

Add Kubernetes support for:

- Keycloak Deployment/Service using a modern Keycloak image.
- Realm import ConfigMap or documented one-time import path.
- Backend environment variables:
  - `OIDC_AUTH_SERVER_URL`
  - `OIDC_CLIENT_ID`
  - `OIDC_CLIENT_SECRET`
  - optional public URL/proxy settings if required by Keycloak redirects.

Update `DEPLOYMENT.md` with:

- Keycloak URL and admin access.
- client secret handling, preferably Kubernetes Secret for the client secret.
- redirect/logout URI values for `https://it220209.cloud.htl-leonding.ac.at/`.
- verification commands for protected and public routes.

Rationale: LeoCloud already uses Kubernetes manifests and an nginx ingress for the backend; auth deployment should fit that style.

## Risks / Trade-offs

- [Risk] Quarkus 3.6 OIDC property support differs from latest docs. -> Mitigation: verify against the project version during implementation and adjust artifacts if needed.
- [Risk] Static resources under `/admin` may need path permission tuning to avoid breaking CSS/JS loads after login. -> Mitigation: protect `/admin*` as a group and test the full UI after login.
- [Risk] Public `/api/stores` does not exist separately from admin store management. -> Mitigation: keep `/api/stores` protected and leave only explicitly listed mobile/customer endpoints public.
- [Risk] Scope filtering can be missed on one mutation path. -> Mitigation: centralize store/region checks in an auth access service and call it from each admin service method touching scoped data.
- [Risk] Demo user Keycloak `sub` values in realm import may change if users are recreated manually. -> Mitigation: document how to update `user_access_assignments` from the current token/current-user endpoint.
- [Risk] Keycloak in LeoCloud needs hostname/proxy tuning behind ingress. -> Mitigation: document tested env vars and keep local setup separate from deployment settings.

## Migration Plan

1. Add OIDC/security dependencies and configuration with environment defaults.
2. Add `user_access_assignments` migration and matching backend model/repository/service.
3. Add Keycloak realm import and local container setup.
4. Protect admin pages/APIs and add current-user/logout UI support.
5. Add scope checks to admin services and focused tests/manual verification.
6. Update LeoCloud manifests/docs for Keycloak and backend OIDC variables.
7. Run Maven verification and `/opsx:verify`.

Rollback:

- Disable or revert OIDC path permissions and remove OIDC env vars from deployment.
- Keep the `user_access_assignments` table if already migrated; it is additive and does not alter existing admin data.
- Revert Keycloak manifests without impacting PostgreSQL/OpenSearch state.

## Open Questions

- Should audit/error logs be admin-only, or should scoped managers see only their own scoped audit entries in a later sprint?
- Should demo assignments be seeded automatically with stable imported user ids, or should `DEPLOYMENT.md` document assignment SQL after first login?
- Does LeoCloud provide a shared Keycloak service, or should this repo own its Keycloak Deployment for the demo?
