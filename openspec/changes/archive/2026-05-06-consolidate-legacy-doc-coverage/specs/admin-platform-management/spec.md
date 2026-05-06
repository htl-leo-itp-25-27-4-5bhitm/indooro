## ADDED Requirements

### Requirement: Admin dashboard summarizes operational state
The Admin Platform SHALL provide dashboard/status information for active regions, active stores, free beacons, assigned beacons, and recent system actions where the user's role allows access.

#### Scenario: Authorized admin opens dashboard
- **GIVEN** an authenticated admin user has permission for dashboard data
- **WHEN** the Admin Platform loads
- **THEN** it shows high-level operational counts and recent system activity

#### Scenario: Scoped user opens dashboard
- **GIVEN** an authenticated scoped user opens the Admin Platform
- **WHEN** dashboard data is loaded
- **THEN** counts and links respect the user's role and scope

### Requirement: Store and beacon lists support filters
The Admin Platform SHALL support practical list filtering for store and beacon management workflows.

#### Scenario: Stores are filtered
- **GIVEN** an authorized user can view stores
- **WHEN** the user filters by query, region, status, page, or size
- **THEN** the backend returns the matching scoped store list

#### Scenario: Beacons are filtered
- **GIVEN** an authorized user can view beacons
- **WHEN** the user filters by status, assignment state, store, or search query
- **THEN** the backend returns matching scoped beacon data

### Requirement: Store detail exposes related operational data
The Admin Platform SHALL expose store detail data that includes store metadata, active beacon assignments, layout versions, and audit history where allowed.

#### Scenario: Store detail is opened
- **GIVEN** an authorized user opens a store inside their scope
- **WHEN** the store detail view loads
- **THEN** the UI can show store metadata, assigned beacons, layout versions, and relevant audit history

#### Scenario: Store is outside scope
- **GIVEN** a scoped user requests a store outside their assignment
- **WHEN** the backend evaluates the request
- **THEN** protected store detail and related operational data are not returned

### Requirement: Beacon validation protects identity consistency
The backend SHALL validate beacon identity input so `uuid` is required, `beaconCode` is unique, identity keys are unique, and `major`/`minor` are either both supplied or both absent.

#### Scenario: Major without minor is submitted
- **GIVEN** a beacon create or update request includes `major` but omits `minor`
- **WHEN** the backend validates the request
- **THEN** it rejects the request with a bad-request error

#### Scenario: Duplicate identity is submitted
- **GIVEN** another beacon already uses the same identity key
- **WHEN** a beacon create or update request would duplicate it
- **THEN** the backend rejects the mutation

### Requirement: Store archival ends active beacon assignments
The Admin Platform SHALL end active beacon assignments when a store is archived so archived stores do not remain active mobile detection targets.

#### Scenario: Store is archived
- **GIVEN** a store has active beacon assignments
- **WHEN** an authorized user archives the store
- **THEN** the system ends active assignments for that store as part of archive handling

#### Scenario: Mobile detection runs after archive
- **GIVEN** a store has been archived
- **WHEN** mobile detection evaluates beacon assignments
- **THEN** archived store/beacon relationships are excluded from active customer detection

### Requirement: Error log page exposes diagnostics safely
The Admin Platform SHALL provide a protected server-log/error-log page that lists recent API errors and allows stack trace inspection for authorized users.

#### Scenario: Admin opens server logs
- **GIVEN** an authenticated `admin` opens `/admin/server-logs/`
- **WHEN** the page loads error log data
- **THEN** recent status code, method, path, message, type, and diagnostic details are visible

#### Scenario: Anonymous user opens server logs
- **GIVEN** an anonymous user requests the server-log page or API
- **WHEN** Keycloak protection is active
- **THEN** the system does not expose protected diagnostic data

### Requirement: Admin frontend consumes error responses once
The Admin UI SHALL handle API error response bodies without consuming the same response stream multiple times.

#### Scenario: API returns validation error
- **GIVEN** an admin mutation returns a structured or textual error response
- **WHEN** the frontend displays the error
- **THEN** it reads and presents the error without triggering body-consumed failures
