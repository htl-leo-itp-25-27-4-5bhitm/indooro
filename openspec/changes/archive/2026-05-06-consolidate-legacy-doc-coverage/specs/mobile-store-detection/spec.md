## ADDED Requirements

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
The mobile store listing route SHALL expose stores that are active and suitable for anonymous customer selection.

#### Scenario: Active stores are requested
- **GIVEN** active and archived stores exist
- **WHEN** an anonymous mobile client requests `/api/mobile/stores`
- **THEN** the response includes active selectable stores and excludes archived stores

#### Scenario: Store has no active layout
- **GIVEN** a store is active but lacks active/current layout data
- **WHEN** it appears in mobile selection flows
- **THEN** clients must still handle missing layout as a separate no-layout state

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
