## ADDED Requirements

### Requirement: Mobile store routes stay anonymous
The system SHALL keep mobile store detection and mobile current-layout routes anonymous unless a future OpenSpec change explicitly protects them.

#### Scenario: Anonymous mobile client lists stores
- **WHEN** an anonymous mobile client requests `/api/mobile/stores`
- **THEN** the system processes the request without redirecting to Keycloak

#### Scenario: Anonymous mobile client loads current layout
- **WHEN** an anonymous mobile client requests `/api/mobile/stores/{storeId}/layout/current`
- **THEN** the system processes the request without requiring an Admin Platform session

### Requirement: Beacon identities route exposes active detection UUIDs
The system SHALL expose `GET /api/mobile/stores/beacon-identities` under `/api/mobile/stores` and return all active, non-archived beacon UUIDs relevant for mobile store detection.

#### Scenario: Active detection identities are requested
- **WHEN** an anonymous mobile client requests `/api/mobile/stores/beacon-identities`
- **THEN** the response body contains a JSON object with a `uuids` array of beacon UUID strings

#### Scenario: Archived beacon exists
- **WHEN** a beacon is archived or otherwise inactive
- **THEN** its UUID is not included in the `uuids` array

### Requirement: Mobile beacon UUIDs are normalized and deduplicated
The system SHALL return beacon UUIDs from mobile detection routes as normalized no-hyphen lowercase identifiers or as valid UUID strings and SHALL remove duplicate UUID values from mobile identity lists.

#### Scenario: Duplicate active identities exist
- **WHEN** multiple records would produce the same mobile beacon UUID
- **THEN** `/api/mobile/stores/beacon-identities` returns that UUID only once

#### Scenario: UUID contains formatting differences
- **WHEN** stored beacon UUIDs differ only by hyphens or case
- **THEN** the mobile identity response normalizes them to a stable comparable form

### Requirement: Beacon-based store lookup uses active assignments
The system SHALL resolve beacon-based store detection only through active, non-archived beacons and active store assignments.

#### Scenario: Mobile client sends known beacon
- **WHEN** an anonymous mobile client requests store lookup by a beacon identity with an active store assignment
- **THEN** the system returns the matching store information needed for mobile context

#### Scenario: Beacon has no active assignment
- **WHEN** a mobile client sends a beacon identity without an active store assignment
- **THEN** the system does not return a false store match

### Requirement: Manual store selection remains possible
The mobile experience SHALL support store search or selection flows that do not depend on BLE detection so customers can still search products and view maps when beacon detection fails.

#### Scenario: BLE signal is unavailable
- **WHEN** a mobile device cannot detect a usable beacon signal
- **THEN** the mobile client can still use public store listing or search flows to choose a store

#### Scenario: Store is selected manually
- **WHEN** a customer manually selects a store
- **THEN** product search and current layout retrieval can proceed for that store

### Requirement: Customer position is not stored server-side for MVP
The system SHALL NOT require server-side storage of anonymous customer positions for MVP store detection, search, map display, or routing.

#### Scenario: Mobile client calculates local route
- **WHEN** the mobile app calculates or displays a route
- **THEN** the backend is not required to persist the customer's live position

#### Scenario: Detection request is processed
- **WHEN** the mobile client performs beacon-based store lookup
- **THEN** the request can be handled without creating a customer identity profile
