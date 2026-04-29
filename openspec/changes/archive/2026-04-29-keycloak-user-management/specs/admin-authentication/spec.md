## ADDED Requirements

### Requirement: Admin platform requires login
The system SHALL require an authenticated Keycloak-backed session before serving Admin Platform pages under `/admin` and `/admin/*`.

#### Scenario: Anonymous user opens admin overview
- **WHEN** an anonymous user requests `/admin/`
- **THEN** the system redirects the user into the Keycloak login flow

#### Scenario: Authenticated user opens admin overview
- **WHEN** an authenticated user with an allowed admin role requests `/admin/`
- **THEN** the system serves the Admin Platform page

### Requirement: Admin APIs require authentication
The system SHALL require authentication for `/api/admin/logs`, `/api/admin/error-logs`, `/api/regions`, `/api/stores`, `/api/beacons`, and `/api/stores/{storeId}/layout/*`.

#### Scenario: Anonymous API request
- **WHEN** an anonymous client requests a protected admin API endpoint
- **THEN** the system rejects the request without returning admin data

#### Scenario: Authenticated API request
- **WHEN** an authenticated user with an allowed role requests a protected admin API endpoint
- **THEN** the system evaluates role and scope rules before returning data

### Requirement: Public routes stay public
The system SHALL keep `/api/mobile/stores`, `/api/mobile/stores/by-beacon`, `/api/mobile/stores/{storeId}/layout/current`, `/api/products`, `/api/categories`, and `/api/layout` accessible without Admin Platform login.

#### Scenario: Anonymous mobile store lookup
- **WHEN** an anonymous mobile client requests `/api/mobile/stores/by-beacon`
- **THEN** the system processes the request without redirecting to Keycloak

#### Scenario: Anonymous catalog lookup
- **WHEN** an anonymous client requests `/api/products`
- **THEN** the system processes the request without requiring an admin session

### Requirement: Logged-in user information is visible
The system SHALL expose the current authenticated admin user's subject, username, email, roles, and Indooro access assignment to the Admin UI.

#### Scenario: Admin UI loads current user
- **WHEN** an authenticated user opens the Admin Platform
- **THEN** the Admin UI displays the user's identity and role context

#### Scenario: User has no active Indooro access assignment
- **WHEN** an authenticated Keycloak user has no active Indooro access assignment
- **THEN** the system rejects protected admin API access with an authorization failure

### Requirement: Logout ends admin session
The system SHALL provide a logout action that ends the Quarkus OIDC web-app session and returns the user to a non-admin landing path.

#### Scenario: User logs out
- **WHEN** an authenticated admin user activates logout
- **THEN** the system ends the admin session and returns the user to the configured post-logout page

#### Scenario: User revisits admin after logout
- **WHEN** a logged-out user requests `/admin/`
- **THEN** the system starts a fresh Keycloak login flow

### Requirement: Unauthorized behavior is explicit
The system SHALL return an authorization failure for authenticated users whose roles or scope do not allow a protected admin action.

#### Scenario: Authenticated user lacks admin role
- **WHEN** an authenticated Keycloak user without `admin`, `region-manager`, or `store-manager` requests a protected admin API
- **THEN** the system rejects the request without returning admin data

#### Scenario: Admin UI receives authorization failure
- **WHEN** the Admin UI receives an authorization failure from a protected admin API
- **THEN** the Admin UI shows a clear access denied state instead of rendering stale or partial protected data
