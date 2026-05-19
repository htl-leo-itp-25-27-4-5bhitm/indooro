# admin-role-access-control Specification

## Purpose
Defines role-based and scope-based access control for protected Indooro admin workflows, including the `admin`, `region-manager`, and `store-manager` roles and their database-backed region/store assignments.
## Requirements
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

### Requirement: Region manager access is scoped to assigned region
The system SHALL limit users with the `region-manager` role to data and actions for the region assigned in the Indooro user access table.

#### Scenario: Region manager lists stores
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an authenticated `region-manager` requests `/api/stores`
- **THEN** the response includes only stores in the user's assigned region

#### Scenario: Region manager requests another region store
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an authenticated `region-manager` requests a store outside the assigned region
- **THEN** the system rejects the request without returning the store

#### Scenario: Region manager edits assigned region store
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an authenticated `region-manager` updates a store in the assigned region
- **THEN** the system applies the update using the existing store validation rules

#### Scenario: Region manager manages layout in assigned region
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an authenticated `region-manager` manages layout data for a store in the assigned region
- **THEN** the system allows the operation if existing layout validation passes

### Requirement: Store manager access is scoped to assigned store
The system SHALL limit users with the `store-manager` role to the store assigned in the Indooro user access table.

#### Scenario: Store manager lists stores
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an authenticated `store-manager` requests `/api/stores`
- **THEN** the response includes only the assigned store

#### Scenario: Store manager opens assigned store layout
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an authenticated `store-manager` requests `/api/stores/{storeId}/layout/current` for the assigned store through the protected admin layout workflow
- **THEN** the system returns the current layout for that store

#### Scenario: Store manager requests another store layout
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an authenticated `store-manager` requests `/api/stores/{storeId}/layout/current` for any other store through the protected admin layout workflow
- **THEN** the system rejects the request without returning layout data

#### Scenario: Store manager lists beacons
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an authenticated `store-manager` lists or manages beacons
- **THEN** the system limits the operation to beacons and assignments relevant to the assigned store

### Requirement: Role and database assignment must agree
The system SHALL authorize protected admin actions only when the Keycloak role and active Indooro user access assignment agree on the user's role and scope.

#### Scenario: Keycloak role differs from database assignment
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an authenticated user has a Keycloak admin role that differs from the active Indooro access assignment role
- **THEN** the system rejects protected admin API access

#### Scenario: Disabled access assignment
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an authenticated user has an inactive or disabled Indooro access assignment
- **THEN** the system rejects protected admin API access

#### Scenario: Assignment references missing scope
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an active assignment references a missing region or store needed for scoped authorization
- **THEN** the system rejects protected admin access that depends on that missing scope

### Requirement: Scope mapping is stored by Keycloak subject
The system SHALL store access assignments by the stable Keycloak subject claim and include username, email, role, optional region, optional store, status, created timestamp, and updated timestamp.

#### Scenario: Current user lookup by subject
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an authenticated user requests the current-user API
- **THEN** the system looks up the Indooro assignment by the token subject claim

#### Scenario: Store manager assignment references store
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an assignment is created for a `store-manager`
- **THEN** the assignment records a store identifier that can be used for backend scope checks

#### Scenario: Region manager assignment references region
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an assignment is created for a `region-manager`
- **THEN** the assignment records a region identifier that can be used for backend scope checks

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

### Requirement: Public customer routes do not use admin scope filtering
The system SHALL NOT require Keycloak admin roles or Indooro user access assignments for public customer/mobile routes.

#### Scenario: Store manager scope exists
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an anonymous mobile client requests a public route while admin scope rules exist in the backend
- **THEN** the public route remains accessible without resolving a Keycloak subject

#### Scenario: Public product search is requested
- **GIVEN** Keycloak authentication and Indooro access assignments are configured
- **WHEN** an anonymous customer searches products
- **THEN** admin role and scope checks are not applied to the request
