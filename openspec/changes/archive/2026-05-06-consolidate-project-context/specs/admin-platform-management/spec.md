## ADDED Requirements

### Requirement: Admin Platform is the staff management surface
The system SHALL provide an Admin Platform under `/admin` for authorized staff to manage Indooro regions, stores, beacons, layouts, audit logs, and error logs.

#### Scenario: Authorized admin opens platform
- **WHEN** a Keycloak-authenticated user with an active allowed Indooro assignment opens `/admin/`
- **THEN** the system serves the static Admin Platform and allows the frontend to load protected admin data according to role and scope

#### Scenario: Anonymous user opens platform
- **WHEN** an anonymous user opens `/admin/`
- **THEN** the system starts the configured Keycloak login flow instead of rendering protected admin data

### Requirement: Region management is protected
The system SHALL protect region management APIs and SHALL apply role and scope rules before returning or mutating region data.

#### Scenario: Admin lists regions
- **WHEN** an authenticated `admin` requests region data
- **THEN** the system returns the available regions according to existing filters

#### Scenario: Store manager requests unrelated regions
- **WHEN** an authenticated `store-manager` requests broad region management data
- **THEN** the system restricts or rejects the response according to the user's assigned store scope

### Requirement: Store management is protected and scoped
The system SHALL protect store management APIs and SHALL return or mutate only stores allowed by the current user's role and Indooro assignment.

#### Scenario: Region manager creates a store in assigned region
- **WHEN** a `region-manager` creates a store for the assigned region
- **THEN** the system accepts the mutation if all existing validation rules pass

#### Scenario: Region manager creates a store outside assigned region
- **WHEN** a `region-manager` creates or updates a store outside the assigned region
- **THEN** the system rejects the mutation without changing store data

### Requirement: Beacon management is protected and scoped
The system SHALL protect beacon creation, update, archive, assignment, release, and listing workflows and SHALL apply role and store/region scope checks.

#### Scenario: Admin assigns beacon
- **WHEN** an authenticated `admin` assigns an active beacon to a store
- **THEN** the system records the assignment according to existing beacon validation rules

#### Scenario: Store manager edits another store beacon
- **WHEN** a `store-manager` attempts to assign, release, update, or archive beacon data outside the assigned store
- **THEN** the system rejects the mutation without exposing unrelated beacon data

### Requirement: Admin layout management is protected and scoped
The system SHALL protect admin layout routes under `/api/stores/{storeId}/layout/*` and SHALL enforce that users can only manage layouts for stores allowed by their role and assignment.

#### Scenario: Store manager opens assigned layout
- **WHEN** a `store-manager` requests the admin layout editor data for the assigned store
- **THEN** the system returns the layout data needed by the editor

#### Scenario: Store manager opens another store layout
- **WHEN** a `store-manager` requests admin layout data for another store
- **THEN** the system rejects the request without returning layout details

### Requirement: Audit logs are admin-visible operational history
The system SHALL provide protected audit log access for users whose role allows operational history inspection.

#### Scenario: Admin opens audit logs
- **WHEN** an authenticated `admin` requests `/api/admin/logs`
- **THEN** the system returns audit log data according to existing pagination or filters

#### Scenario: Non-admin requests audit logs
- **WHEN** an authenticated user without sufficient log permissions requests audit logs
- **THEN** the system rejects the request without returning audit history

### Requirement: Error logs are protected diagnostics
The system SHALL provide protected error log access for users whose role allows diagnostics inspection and SHALL avoid exposing error diagnostics through anonymous routes.

#### Scenario: Admin opens error logs
- **WHEN** an authenticated `admin` requests `/api/admin/error-logs`
- **THEN** the system returns error log data according to existing pagination or filters

#### Scenario: Anonymous user requests error logs
- **WHEN** an anonymous user requests `/api/admin/error-logs`
- **THEN** the system rejects the request and returns no diagnostics data

### Requirement: Admin UI handles authorization state explicitly
The Admin Platform SHALL display identity, role, scope, loading, denied, and empty states without rendering stale protected data after a 401 or 403 response.

#### Scenario: Current user loads successfully
- **WHEN** the Admin UI loads the current authenticated user's identity and access assignment
- **THEN** the UI displays the user's username, email or fallback identifier, role, and relevant region/store scope

#### Scenario: Protected fetch receives 403
- **WHEN** a protected admin API request returns a 403 authorization failure
- **THEN** the UI shows an access denied state for the affected view instead of silently keeping partial or previous data

### Requirement: Archive semantics are preferred over destructive deletion
The system SHALL prefer archive/status-based lifecycle transitions for managed admin records where the domain model supports archiving, so historical relationships remain inspectable.

#### Scenario: Store is archived
- **WHEN** an authorized admin archives a store
- **THEN** the store is excluded from active workflows according to existing filters without requiring hard deletion

#### Scenario: Beacon is archived
- **WHEN** an authorized admin archives a beacon
- **THEN** mobile detection excludes the archived beacon from active identity responses
