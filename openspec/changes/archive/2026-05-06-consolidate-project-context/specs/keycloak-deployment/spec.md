## MODIFIED Requirements

### Requirement: Local Keycloak dev setup is reproducible
The system SHALL provide a local Keycloak dev/demo setup with an `indooro` realm, an `indooro-admin-web` OIDC client, realm roles `admin`, `region-manager`, and `store-manager`, and demo users suitable for local role/scope verification.

#### Scenario: Developer starts local Keycloak
- **WHEN** a developer starts the documented local Keycloak setup
- **THEN** Keycloak imports the Indooro realm and exposes it without using legacy `/auth/realms/...` URLs

#### Scenario: Demo user logs in locally
- **WHEN** a demo admin user logs in through local Keycloak
- **THEN** Quarkus accepts the authorization code flow for the `indooro-admin-web` client

#### Scenario: Role-specific demo user logs in locally
- **WHEN** a local demo user with `region-manager` or `store-manager` logs in
- **THEN** the backend can evaluate the user's Keycloak role together with the seeded Indooro access assignment

### Requirement: Realm import uses modern Keycloak container behavior
The system SHALL use a modern Keycloak container image and startup import from `/opt/keycloak/data/import` with the Keycloak `--import-realm` behavior.

#### Scenario: Realm JSON mounted for startup
- **WHEN** the Keycloak container starts with the realm JSON mounted in the import directory
- **THEN** the container imports regular `.json` realm files from that directory at startup

#### Scenario: Classroom example uses old image
- **WHEN** a reference example uses `jboss/keycloak:15.0.2` or legacy `/auth/realms/...` URLs
- **THEN** the Indooro implementation treats it as conceptual guidance only and uses modern Keycloak server behavior

### Requirement: Quarkus OIDC configuration is deployable
The system SHALL configure OIDC through environment-overridable properties for auth server URL, client id, client secret, application URL behavior, logout path, token/session behavior, and public/protected path policies.

#### Scenario: LeoCloud sets OIDC environment
- **WHEN** the backend runs in LeoCloud with OIDC environment variables set
- **THEN** Quarkus uses the LeoCloud Keycloak endpoint and client secret without code changes

#### Scenario: Local developer uses defaults
- **WHEN** the backend runs locally with no deployment overrides
- **THEN** Quarkus uses the documented local Keycloak realm and client defaults

#### Scenario: Public routes are configured
- **WHEN** OIDC path permissions are evaluated
- **THEN** public mobile/customer routes remain anonymous while protected admin routes require authentication

### Requirement: Deployment documentation describes auth setup
The system SHALL document the Keycloak realm/client settings, redirect URIs, logout URIs, secrets, Kubernetes resources, and verification steps needed for LeoCloud.

#### Scenario: Operator follows deployment docs
- **WHEN** an operator follows the updated deployment instructions
- **THEN** they can configure Keycloak and backend OIDC settings consistently for the Admin Platform

#### Scenario: Keycloak is hosted behind relative path
- **WHEN** Keycloak is deployed under `/keycloak` on the LeoCloud public host
- **THEN** the realm and redirect URLs use that path consistently and do not produce malformed duplicate schemes such as `https://https://...`

### Requirement: Verification covers protected and public paths
The system SHALL include verification steps that demonstrate login, logout, role-based access, scope filtering, unauthorized failures, and unchanged public route accessibility.

#### Scenario: Verification checks admin protection
- **WHEN** verification is run before archive
- **THEN** it includes evidence that protected admin pages and APIs require login and roles

#### Scenario: Verification checks public routes
- **WHEN** verification is run before archive
- **THEN** it includes evidence that selected mobile/customer routes remain public

#### Scenario: Verification checks logout
- **WHEN** verification is run after auth changes
- **THEN** it includes a logout/re-login check that confirms the Admin UI does not reuse stale user state

## ADDED Requirements

### Requirement: LeoCloud Keycloak URL is canonical
The system SHALL use `https://it220209.cloud.htl-leonding.ac.at/keycloak/realms/indooro` as the LeoCloud auth-server URL unless a future deployment change explicitly updates the host or Keycloak relative path.

#### Scenario: Backend runs in LeoCloud
- **WHEN** the backend reads OIDC auth-server URL configuration in LeoCloud
- **THEN** the URL points to the public host, `/keycloak`, and the `indooro` realm exactly once

#### Scenario: URL is assembled from variables
- **WHEN** deployment variables are combined into an OIDC URL
- **THEN** the result must not contain duplicated schemes, duplicated hosts, or legacy `/auth` path segments
