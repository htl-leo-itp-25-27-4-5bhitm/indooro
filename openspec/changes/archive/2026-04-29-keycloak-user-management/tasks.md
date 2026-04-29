## 1. OpenSpec Setup

- [x] 1.1 Check whether OpenSpec is initialized in the repo
- [x] 1.2 Initialize OpenSpec for Codex because the repo had no OpenSpec structure
- [x] 1.3 Enable expanded OPSX commands and run OpenSpec update
- [x] 1.4 Create `openspec/config.yaml` with `spec-driven` project context
- [x] 1.5 Create the `keycloak-user-management` OpenSpec change
- [x] 1.6 Generate and review proposal, specs, design, and tasks artifacts

## 2. Keycloak Local Setup

- [x] 2.1 Add a local Keycloak realm import for realm `indooro`, client `indooro-admin-web`, roles, and demo users
- [x] 2.2 Add local container configuration or documentation to run modern Keycloak with realm import
- [x] 2.3 Document demo user credentials, redirect URIs, logout URIs, and how to obtain/update Keycloak subject mappings

## 3. Backend Authentication

- [x] 3.1 Add Quarkus OIDC/security dependencies to the backend module
- [x] 3.2 Configure OIDC web-app login, logout, public paths, protected admin paths, and environment overrides
- [x] 3.3 Add a current-user admin endpoint that returns Keycloak identity and Indooro access assignment
- [x] 3.4 Add authentication and role annotations to admin resources

## 4. Backend User Scope Model

- [x] 4.1 Add Flyway migration for `user_access_assignments`
- [x] 4.2 Add entity, enum, repository, DTO, and service support for access assignments
- [x] 4.3 Implement current-user resolution from Keycloak subject and role consistency checks
- [x] 4.4 Implement reusable region/store scope check helpers

## 5. Backend Scope Enforcement

- [x] 5.1 Enforce region/store filters in region and store admin reads
- [x] 5.2 Enforce region/store scope checks for store create/update/archive/audit/beacon views
- [x] 5.3 Enforce store scope checks for layout reads and mutations
- [x] 5.4 Enforce store scope checks for beacon reads, create/update/archive, assign, and release
- [x] 5.5 Keep mobile/customer/catalog/layout public routes unprotected

## 6. Frontend Admin Auth

- [x] 6.1 Show current logged-in user, role, and scope in the Admin UI
- [x] 6.2 Add logout control wired to the Quarkus OIDC logout path
- [x] 6.3 Handle authorization failures with an access denied state instead of stale protected data
- [x] 6.4 Apply the same user/logout affordance to the server logs and layout editor admin pages where practical

## 7. Deployment

- [x] 7.1 Add or update Kubernetes manifests for Keycloak and backend OIDC environment variables/secrets
- [x] 7.2 Update `DEPLOYMENT.md` with local and LeoCloud Keycloak/OIDC setup and verification steps
- [x] 7.3 Ensure deployment docs preserve the public mobile/customer API behavior

## 8. Verification

- [x] 8.1 Add focused backend tests or documented manual checks for unauthenticated, unauthorized, admin, region-manager, and store-manager behavior
- [x] 8.2 Run backend Maven verification
- [x] 8.3 Run local route checks where possible for protected admin and public customer/mobile endpoints
- [x] 8.4 Run `/opsx:verify keycloak-user-management`
- [x] 8.5 Archive the change with `/opsx:archive keycloak-user-management`
