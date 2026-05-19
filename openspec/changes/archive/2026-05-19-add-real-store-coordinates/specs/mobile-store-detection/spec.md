## MODIFIED Requirements

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
