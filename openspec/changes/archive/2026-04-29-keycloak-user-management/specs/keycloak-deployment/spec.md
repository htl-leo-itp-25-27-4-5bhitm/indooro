## ADDED Requirements

### Requirement: Local Keycloak dev setup is reproducible
The system SHALL provide a local Keycloak dev/demo setup with an `indooro` realm, an `indooro-admin-web` confidential OIDC client, and realm roles `admin`, `region-manager`, and `store-manager`.

#### Scenario: Developer starts local Keycloak
- **WHEN** a developer starts the documented local Keycloak setup
- **THEN** Keycloak imports the Indooro realm and exposes it without using legacy `/auth/realms/...` URLs

#### Scenario: Demo user logs in locally
- **WHEN** a demo admin user logs in through local Keycloak
- **THEN** Quarkus accepts the authorization code flow for the `indooro-admin-web` client

### Requirement: Realm import uses modern Keycloak container behavior
The system SHALL use a modern Keycloak container image and startup import from `/opt/keycloak/data/import` with the Keycloak `--import-realm` behavior.

#### Scenario: Realm JSON mounted for startup
- **WHEN** the Keycloak container starts with the realm JSON mounted in the import directory
- **THEN** the container imports regular `.json` realm files from that directory at startup

### Requirement: Quarkus OIDC configuration is deployable
The system SHALL configure OIDC through environment-overridable properties for auth server URL, client id, client secret, application URL behavior, logout path, and public/protected path policies.

#### Scenario: LeoCloud sets OIDC environment
- **WHEN** the backend runs in LeoCloud with OIDC environment variables set
- **THEN** Quarkus uses the LeoCloud Keycloak endpoint and client secret without code changes

#### Scenario: Local developer uses defaults
- **WHEN** the backend runs locally with no deployment overrides
- **THEN** Quarkus uses the documented local Keycloak realm and client defaults

### Requirement: Deployment documentation describes auth setup
The system SHALL document the Keycloak realm/client settings, redirect URIs, logout URIs, secrets, Kubernetes resources, and verification steps needed for LeoCloud.

#### Scenario: Operator follows deployment docs
- **WHEN** an operator follows the updated deployment instructions
- **THEN** they can configure Keycloak and backend OIDC settings consistently for the Admin Platform

### Requirement: Verification covers protected and public paths
The system SHALL include verification steps that demonstrate login, logout, role-based access, scope filtering, unauthorized failures, and unchanged public route accessibility.

#### Scenario: Verification checks admin protection
- **WHEN** verification is run before archive
- **THEN** it includes evidence that protected admin pages and APIs require login and roles

#### Scenario: Verification checks public routes
- **WHEN** verification is run before archive
- **THEN** it includes evidence that selected mobile/customer routes remain public
