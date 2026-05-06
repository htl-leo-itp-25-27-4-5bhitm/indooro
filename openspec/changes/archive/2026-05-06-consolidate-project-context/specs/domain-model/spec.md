## ADDED Requirements

### Requirement: Regions contain stores
The system SHALL model a region as the parent grouping for stores and SHALL preserve the relationship between each store and its region for admin management, scope filtering, and mobile display.

#### Scenario: Store is listed with regional context
- **WHEN** an authorized admin user lists stores
- **THEN** each store can be interpreted in the context of its owning region

#### Scenario: Region manager scope is evaluated
- **WHEN** a `region-manager` accesses store data
- **THEN** the system can compare the store's region with the user's assigned region

### Requirement: Stores are the central operational unit
The system SHALL treat a store as the central unit connecting public mobile metadata, product/layout lookup, beacon assignments, layout versions, and scoped admin management.

#### Scenario: Mobile client selects a store
- **WHEN** a mobile client selects or detects a store
- **THEN** product lookup, layout retrieval, and route calculation can be scoped to that store

#### Scenario: Store manager scope is evaluated
- **WHEN** a `store-manager` accesses protected admin data
- **THEN** the system can compare the requested store with the user's assigned store

### Requirement: Beacon identities are normalized and unique for detection
The system SHALL store and expose beacon identities in a normalized form suitable for mobile detection and SHALL avoid duplicate active beacon identities in mobile-facing detection responses.

#### Scenario: Beacon UUID is stored after normalization
- **WHEN** a beacon UUID is persisted or migrated
- **THEN** the system uses a normalized identity form that is stable for matching

#### Scenario: Mobile identity list is generated
- **WHEN** the system returns active mobile beacon identities
- **THEN** duplicate UUIDs are removed from the response

### Requirement: Beacon assignments represent store membership over time
The system SHALL model beacon assignment separately from beacon identity so a physical beacon can be assigned, released, archived, or reassigned without losing its historical identity.

#### Scenario: Beacon is assigned to a store
- **WHEN** an authorized admin assigns a beacon to a store
- **THEN** the system records the store relationship through an assignment rather than changing the beacon identity itself

#### Scenario: Beacon is released
- **WHEN** an authorized admin releases a beacon assignment
- **THEN** historical assignment data remains distinguishable from the current active assignment

### Requirement: Layout versions belong to stores
The system SHALL model layout versions as store-specific records and SHALL distinguish active/current layout versions from inactive historical versions.

#### Scenario: Current layout is requested
- **WHEN** a client requests the current layout for a store
- **THEN** the system returns the active layout version for that store if one exists

#### Scenario: Historical layout remains available for audit
- **WHEN** a new layout version is activated
- **THEN** previous layout versions remain distinguishable from the active version

### Requirement: User access assignments map Keycloak identities to Indooro scope
The system SHALL map the stable Keycloak subject claim to an Indooro user access assignment containing username, email, role, optional region scope, optional store scope, status, creation time, and update time.

#### Scenario: Current user is resolved
- **WHEN** an authenticated Admin Platform user calls a protected admin route
- **THEN** the system resolves the user's Indooro role and scope from the Keycloak subject

#### Scenario: Assignment is inactive
- **WHEN** the Keycloak subject maps to an inactive or disabled assignment
- **THEN** the system denies protected admin access

### Requirement: Operational logs are persistent domain records
The system SHALL persist audit logs for admin actions and error logs for operational failures so administrators and developers can inspect system behavior.

#### Scenario: Admin action is performed
- **WHEN** an authorized admin mutates managed data
- **THEN** the system can record who acted, what changed, and when the action occurred

#### Scenario: Client or backend error is recorded
- **WHEN** a relevant admin/frontend/backend error is logged
- **THEN** the error can be inspected through the protected error log workflow by an authorized user

### Requirement: PostgreSQL and OpenSearch responsibilities are distinct
The system SHALL use PostgreSQL for operational admin/domain state and OpenSearch for search-oriented product, category, and layout documents.

#### Scenario: Region is edited
- **WHEN** an authorized admin creates, updates, archives, or lists regions
- **THEN** the operation uses PostgreSQL-backed domain state

#### Scenario: Product is searched
- **WHEN** an anonymous customer searches products
- **THEN** the operation uses search-oriented catalog data rather than admin-region persistence tables
