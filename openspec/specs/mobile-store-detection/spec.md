# mobile-store-detection Specification

## Purpose
Defines anonymous mobile store detection behavior, public mobile routes, active beacon identity exposure, beacon-based store lookup, manual fallback, and the MVP boundary against server-side customer tracking.
## Requirements
### Requirement: Mobile store routes stay anonymous
The system SHALL keep mobile store detection and mobile current-layout routes anonymous unless a future OpenSpec change explicitly protects them.

#### Scenario: Anonymous mobile client lists stores
- **GIVEN** active store, beacon, and assignment data are available as described
- **WHEN** an anonymous mobile client requests `/api/mobile/stores`
- **THEN** the system processes the request without redirecting to Keycloak

#### Scenario: Anonymous mobile client loads current layout
- **GIVEN** active store, beacon, and assignment data are available as described
- **WHEN** an anonymous mobile client requests `/api/mobile/stores/{storeId}/layout/current`
- **THEN** the system processes the request without requiring an Admin Platform session

### Requirement: Beacon identities route exposes active detection UUIDs
The system SHALL expose `GET /api/mobile/stores/beacon-identities` under `/api/mobile/stores` and return all active, non-archived beacon UUIDs relevant for mobile store detection.

#### Scenario: Active detection identities are requested
- **GIVEN** active store, beacon, and assignment data are available as described
- **WHEN** an anonymous mobile client requests `/api/mobile/stores/beacon-identities`
- **THEN** the response body contains a JSON object with a `uuids` array of beacon UUID strings

#### Scenario: Archived beacon exists
- **GIVEN** active store, beacon, and assignment data are available as described
- **WHEN** a beacon is archived or otherwise inactive
- **THEN** its UUID is not included in the `uuids` array

### Requirement: Mobile beacon UUIDs are normalized and deduplicated
The system SHALL return beacon UUIDs from mobile detection routes as normalized no-hyphen lowercase identifiers or as valid UUID strings and SHALL remove duplicate UUID values from mobile identity lists.

#### Scenario: Duplicate active identities exist
- **GIVEN** active store, beacon, and assignment data are available as described
- **WHEN** multiple records would produce the same mobile beacon UUID
- **THEN** `/api/mobile/stores/beacon-identities` returns that UUID only once

#### Scenario: UUID contains formatting differences
- **GIVEN** active store, beacon, and assignment data are available as described
- **WHEN** stored beacon UUIDs differ only by hyphens or case
- **THEN** the mobile identity response normalizes them to a stable comparable form

### Requirement: Beacon-based store lookup uses active assignments
The system SHALL resolve beacon-based store detection only through active, non-archived beacons and active store assignments.

#### Scenario: Mobile client sends known beacon
- **GIVEN** active store, beacon, and assignment data are available as described
- **WHEN** an anonymous mobile client requests store lookup by a beacon identity with an active store assignment
- **THEN** the system returns the matching store information needed for mobile context

#### Scenario: Beacon has no active assignment
- **GIVEN** active store, beacon, and assignment data are available as described
- **WHEN** a mobile client sends a beacon identity without an active store assignment
- **THEN** the system does not return a false store match

### Requirement: Manual store selection remains possible
The mobile experience SHALL support store search or selection flows that do not depend on BLE detection so customers can still search products and view maps when beacon detection fails. Store selection maps SHALL use real persisted store coordinates only.

#### Scenario: BLE signal is unavailable
- **GIVEN** active store, beacon, and assignment data are available as described
- **WHEN** a mobile device cannot detect a usable beacon signal
- **THEN** the mobile client can still use public store listing or search flows to choose a store

#### Scenario: Store is selected manually
- **GIVEN** active store, beacon, and assignment data are available as described
- **WHEN** a customer manually selects a store
- **THEN** product search and current layout retrieval can proceed for that store

#### Scenario: Store map uses persisted coordinates
- **GIVEN** active stores have persisted latitude and longitude values
- **WHEN** the mobile store map renders store pins
- **THEN** the pins are placed at those persisted coordinates without city-based or deterministic-offset fallback

#### Scenario: Store has no coordinates
- **GIVEN** an active store lacks latitude or longitude
- **WHEN** the mobile store map renders
- **THEN** that store is omitted from the map or handled as a non-production debug case instead of being shown at a fake coordinate

### Requirement: Customer position is not stored server-side for MVP
The system SHALL NOT require server-side storage of anonymous customer positions for MVP store detection, search, map display, or routing.

#### Scenario: Mobile client calculates local route
- **GIVEN** active store, beacon, and assignment data are available as described
- **WHEN** the mobile app calculates or displays a route
- **THEN** the backend is not required to persist the customer's live position

#### Scenario: Detection request is processed
- **GIVEN** active store, beacon, and assignment data are available as described
- **WHEN** the mobile client performs beacon-based store lookup
- **THEN** the request can be handled without creating a customer identity profile

### Requirement: Beacon store lookup accepts UUID and optional major/minor
The mobile store lookup route SHALL accept beacon identity input with UUID and optional major/minor query parameters and resolve it against active beacon assignments.

#### Scenario: Full beacon identity is sent
- **GIVEN** a beacon with UUID, major, and minor is active and assigned to an active store
- **WHEN** an anonymous mobile client requests `/api/mobile/stores/by-beacon` with matching query parameters
- **THEN** the backend returns the matched store context and matched beacon information

#### Scenario: UUID-only identity is sent
- **GIVEN** a beacon identity is configured without major/minor
- **WHEN** a mobile client sends only the UUID query parameter
- **THEN** the backend can resolve it if the stored identity and active assignment match UUID-only semantics

### Requirement: Mobile store list includes active stores only
The mobile store listing route SHALL expose stores that are active and suitable for anonymous customer selection, including address and coordinate fields needed by the mobile store map.

#### Scenario: Active stores are requested
- **GIVEN** active and archived stores exist
- **WHEN** an anonymous mobile client requests `/api/mobile/stores`
- **THEN** the response includes active selectable stores and excludes archived stores

#### Scenario: Store has no active layout
- **GIVEN** a store is active but lacks active/current layout data
- **WHEN** it appears in mobile selection flows
- **THEN** clients must still handle missing layout as a separate no-layout state

#### Scenario: Store coordinates are returned
- **GIVEN** an active store has latitude and longitude
- **WHEN** an anonymous mobile client requests `/api/mobile/stores`
- **THEN** the response includes `address`, `latitude`, and `longitude` for that store

### Requirement: Mobile store detection does not require exact customer position
Beacon-based store detection SHALL identify the active store context and SHALL NOT require computing or uploading the customer's exact indoor coordinates.

#### Scenario: Beacon resolves store
- **GIVEN** the mobile app detects a beacon assigned to a store
- **WHEN** it calls the store lookup route
- **THEN** the backend returns store context without storing the customer's position

#### Scenario: Exact positioning is needed
- **GIVEN** the app needs Blue Dot positioning within a store
- **WHEN** it computes customer position
- **THEN** the computation remains a mobile positioning/navigation concern rather than a store-detection API requirement

