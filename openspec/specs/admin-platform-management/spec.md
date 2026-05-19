# admin-platform-management Specification

## Purpose
Defines the protected Admin Platform management surface for staff workflows such as regions, stores, beacons, layout administration, audit logs, error logs, role-aware UI state, and archive-based lifecycle behavior.
## Requirements
### Requirement: Admin Platform is the staff management surface
The system SHALL provide an Admin Platform under `/admin` for authorized staff to manage Indooro regions, stores, beacons, layouts, audit logs, and error logs.

#### Scenario: Authorized admin opens platform
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** a Keycloak-authenticated user with an active allowed Indooro assignment opens `/admin/`
- **THEN** the system serves the static Admin Platform and allows the frontend to load protected admin data according to role and scope

#### Scenario: Anonymous user opens platform
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** an anonymous user opens `/admin/`
- **THEN** the system starts the configured Keycloak login flow instead of rendering protected admin data

### Requirement: Region management is protected
The system SHALL protect region management APIs and SHALL apply role and scope rules before returning or mutating region data.

#### Scenario: Admin lists regions
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** an authenticated `admin` requests region data
- **THEN** the system returns the available regions according to existing filters

#### Scenario: Store manager requests unrelated regions
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** an authenticated `store-manager` requests broad region management data
- **THEN** the system restricts or rejects the response according to the user's assigned store scope

### Requirement: Store management is protected and scoped
The system SHALL protect store management APIs and SHALL return or mutate only stores allowed by the current user's role and Indooro assignment.

#### Scenario: Region manager creates a store in assigned region
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** a `region-manager` creates a store for the assigned region
- **THEN** the system accepts the mutation if all existing validation rules pass

#### Scenario: Region manager creates a store outside assigned region
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** a `region-manager` creates or updates a store outside the assigned region
- **THEN** the system rejects the mutation without changing store data

### Requirement: Beacon management is protected and scoped
The system SHALL protect beacon creation, update, archive, assignment, release, and listing workflows and SHALL apply role and store/region scope checks.

#### Scenario: Admin assigns beacon
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** an authenticated `admin` assigns an active beacon to a store
- **THEN** the system records the assignment according to existing beacon validation rules

#### Scenario: Store manager edits another store beacon
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** a `store-manager` attempts to assign, release, update, or archive beacon data outside the assigned store
- **THEN** the system rejects the mutation without exposing unrelated beacon data

### Requirement: Admin layout management is protected and scoped
The system SHALL protect admin layout routes under `/api/stores/{storeId}/layout/*` and SHALL enforce that users can only manage layouts for stores allowed by their role and assignment.

#### Scenario: Store manager opens assigned layout
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** a `store-manager` requests the admin layout editor data for the assigned store
- **THEN** the system returns the layout data needed by the editor

#### Scenario: Store manager opens another store layout
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** a `store-manager` requests admin layout data for another store
- **THEN** the system rejects the request without returning layout details

### Requirement: Audit logs are admin-visible operational history
The system SHALL provide protected audit log access for users whose role allows operational history inspection.

#### Scenario: Admin opens audit logs
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** an authenticated `admin` requests `/api/admin/logs`
- **THEN** the system returns audit log data according to existing pagination or filters

#### Scenario: Non-admin requests audit logs
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** an authenticated user without sufficient log permissions requests audit logs
- **THEN** the system rejects the request without returning audit history

### Requirement: Error logs are protected diagnostics
The system SHALL provide protected error log access for users whose role allows diagnostics inspection and SHALL avoid exposing error diagnostics through anonymous routes.

#### Scenario: Admin opens error logs
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** an authenticated `admin` requests `/api/admin/error-logs`
- **THEN** the system returns error log data according to existing pagination or filters

#### Scenario: Anonymous user requests error logs
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** an anonymous user requests `/api/admin/error-logs`
- **THEN** the system rejects the request and returns no diagnostics data

### Requirement: Admin UI handles authorization state explicitly
The Admin Platform SHALL display identity, role, scope, loading, denied, and empty states without rendering stale protected data after a 401 or 403 response.

#### Scenario: Current user loads successfully
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** the Admin UI loads the current authenticated user's identity and access assignment
- **THEN** the UI displays the user's username, email or fallback identifier, role, and relevant region/store scope

#### Scenario: Protected fetch receives 403
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** a protected admin API request returns a 403 authorization failure
- **THEN** the UI shows an access denied state for the affected view instead of silently keeping partial or previous data

### Requirement: Archive semantics are preferred over destructive deletion
The system SHALL prefer archive/status-based lifecycle transitions for managed admin records where the domain model supports archiving, so historical relationships remain inspectable.

#### Scenario: Store is archived
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** an authorized admin archives a store
- **THEN** the store is excluded from active workflows according to existing filters without requiring hard deletion

#### Scenario: Beacon is archived
- **GIVEN** the Admin Platform management surface and role/scope context are available
- **WHEN** an authorized admin archives a beacon
- **THEN** mobile detection excludes the archived beacon from active identity responses

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

### Requirement: Admin product management is available in the Admin Platform
The Admin Platform SHALL provide a product management surface that lets authorized admins create, update, or delete product catalog documents with product id, name, price, and layout code.

#### Scenario: Admin creates product
- **GIVEN** an authenticated user with the `admin` role and an active Indooro admin assignment opens the Admin Platform
- **WHEN** the user submits a valid product with id, name, price, and layout code
- **THEN** the Admin Platform sends the product to the protected admin product API and shows a success state after the product is indexed

#### Scenario: Admin deletes product
- **GIVEN** an authenticated user with the `admin` role sees a product in the Admin Platform product list
- **WHEN** the user confirms deletion for that product
- **THEN** the Admin Platform sends a delete request to the protected admin product API and removes the product from the list after the product document is deleted

#### Scenario: Product form is incomplete
- **GIVEN** an authenticated admin is using the product management form
- **WHEN** the user submits a product without a required field or with a negative price
- **THEN** the system rejects the submission and keeps the existing catalog unchanged

#### Scenario: Non-admin opens Admin Platform
- **GIVEN** an authenticated `region-manager` or `store-manager` opens the Admin Platform
- **WHEN** role-aware UI state is applied
- **THEN** product management navigation and product mutation controls are not displayed

### Requirement: Admin store management supports coordinates
The Admin Platform SHALL allow optional latitude and longitude values to be maintained for stores and SHALL validate geographic ranges before persisting them.

#### Scenario: Admin saves valid coordinates
- **GIVEN** an authorized admin or scoped manager can update a store
- **WHEN** they submit latitude between -90 and 90 and longitude between -180 and 180
- **THEN** the backend persists the coordinates with the store

#### Scenario: Admin submits invalid coordinates
- **GIVEN** an authorized admin or scoped manager can update a store
- **WHEN** latitude or longitude is outside the valid range
- **THEN** the backend rejects the store mutation without changing stored coordinates

#### Scenario: Store coordinates are optional
- **GIVEN** a store is created before exact coordinates are known
- **WHEN** the admin leaves latitude and longitude empty
- **THEN** the store can still be saved, but mobile store maps do not render a fake production pin for it

