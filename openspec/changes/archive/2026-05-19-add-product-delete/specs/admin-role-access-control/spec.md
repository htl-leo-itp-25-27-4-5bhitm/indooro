## MODIFIED Requirements

### Requirement: Admin role has full admin access
The system SHALL allow users with the `admin` role and an active Indooro access assignment to view and manage all regions, stores, beacons, layouts, product catalog maintenance, audit logs, and error logs in the protected Admin Platform.

#### Scenario: Admin lists all stores
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an authenticated `admin` requests `/api/stores`
- **THEN** the response includes stores across all regions according to the existing filters and pagination

#### Scenario: Admin accesses system logs
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an authenticated `admin` requests `/api/admin/logs`
- **THEN** the system returns audit log data

#### Scenario: Admin manages any store layout
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an authenticated `admin` requests admin layout management for any store
- **THEN** the system allows access if the requested layout operation passes existing validation

#### Scenario: Admin creates or updates product catalog
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an authenticated `admin` creates or updates a product through `/api/admin/products`
- **THEN** the system allows the mutation if product validation passes

#### Scenario: Admin deletes product catalog entry
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an authenticated `admin` deletes a product through `/api/admin/products/{id}`
- **THEN** the system removes that product document from the catalog if it exists

### Requirement: Admin data mutations respect scope
The system SHALL apply scope checks to protected admin mutations as well as reads, and SHALL reserve global product catalog mutations for the `admin` role.

#### Scenario: Region manager creates store outside assigned region
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** a `region-manager` attempts to create or update a store for another region
- **THEN** the system rejects the mutation

#### Scenario: Store manager mutates beacon outside assigned store
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** a `store-manager` attempts to assign, release, update, or archive beacon data outside the assigned store
- **THEN** the system rejects the mutation

#### Scenario: Store manager archives assigned store resource
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** a `store-manager` mutates an allowed resource inside the assigned store
- **THEN** the system allows the mutation only if the existing domain validation rules allow that action

#### Scenario: Non-admin attempts product mutation
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an authenticated `region-manager` or `store-manager` calls `/api/admin/products`, `/api/admin/products/{id}`, `POST /api/products`, or `POST /api/products/bulk` for a product mutation
- **THEN** the system rejects the mutation without changing product catalog data
