## ADDED Requirements

### Requirement: iOS positioning uses configured beacon anchors
The mobile app SHALL derive customer position from beacons placed in the active layout and SHALL treat each beacon anchor as a known map coordinate with UUID and optional major/minor identifiers.

#### Scenario: Layout contains positioned beacons
- **GIVEN** the active layout contains beacon elements with map coordinates and identifiers
- **WHEN** the mobile app loads the layout
- **THEN** the app can build the beacon anchor set used for positioning

#### Scenario: Beacon identity is incomplete
- **GIVEN** a layout beacon element lacks a usable UUID or required identifier
- **WHEN** the mobile app configures scanning
- **THEN** that element is not used as a reliable positioning anchor

### Requirement: iBeacon ranging is the primary BLE mode for MVP
The mobile app SHALL support iBeacon ranging for the Accent Systems iBKS USB beacon setup and MAY keep generic BLE RSSI scanning as a fallback/debug mode.

#### Scenario: iBeacon-capable hardware is configured
- **GIVEN** iBKS USB beacons are configured as iBeacon transmitters
- **WHEN** the mobile app scans in normal customer mode
- **THEN** it matches ranged beacons by UUID and major/minor where available

#### Scenario: Ranging cannot be started
- **GIVEN** iBeacon ranging is unavailable because permissions or platform state block it
- **WHEN** the mobile app starts positioning
- **THEN** it exposes a clear positioning status instead of silently showing a trusted Blue Dot

### Requirement: Blue Dot requires enough fresh beacon data
The mobile app SHALL display a trusted Blue Dot only when enough fresh beacon measurements exist for a position solution, with three usable beacons as the MVP threshold for triangulation/trilateration.

#### Scenario: Three usable beacons are visible
- **GIVEN** at least three active layout beacons have fresh measurements
- **WHEN** the mobile app computes position
- **THEN** the Blue Dot can be updated from the solved estimate and confidence

#### Scenario: Fewer than three usable beacons are visible
- **GIVEN** only one or two usable beacons are visible
- **WHEN** the mobile app computes position for MVP navigation
- **THEN** it must not present the position as a fully trusted Blue Dot

#### Scenario: Single-beacon proximity fallback is shown
- **GIVEN** fewer than three usable beacons are visible and a proximity fallback is implemented
- **WHEN** the app presents fallback location feedback
- **THEN** it may show an approximate radius/proximity state without claiming exact aisle-side position

### Requirement: Positioning is smoothed and confidence-aware
The mobile app SHALL smooth noisy radio measurements and sensor signals so the displayed position remains stable while still responding to real movement.

#### Scenario: RSSI measurements fluctuate
- **GIVEN** beacon RSSI values fluctuate while the user is stationary
- **WHEN** the mobile app updates the displayed position
- **THEN** filters, confidence, and map matching reduce visible Blue Dot jitter

#### Scenario: Sensor data is available
- **GIVEN** motion, heading, or step-like sensor data is available on the device
- **WHEN** recent beacon estimates are stale or noisy
- **THEN** the app may use sensor fusion to predict short movement without storing customer position server-side

### Requirement: Positioning quality targets are explicit
The mobile app SHALL target approximately one-meter practical positioning quality for navigation, SHALL keep stationary Blue Dot jitter below two meters where feasible, and SHALL keep movement smooth enough for mid-range phones.

#### Scenario: Position estimate is stable enough
- **GIVEN** beacon coverage and layout calibration are adequate
- **WHEN** the customer stands still in the market
- **THEN** the displayed Blue Dot should not jump more than about two meters

#### Scenario: Position quality is insufficient
- **GIVEN** confidence drops below the navigation threshold
- **WHEN** the app would otherwise draw precise guidance
- **THEN** it shows degraded/low-confidence behavior instead of over-promising exact position

### Requirement: Route guidance is a map line, not turn-by-turn MVP
The mobile navigation MVP SHALL draw a route line from the current customer position to the product target and SHALL NOT require spoken or textual turn-by-turn instructions as baseline behavior.

#### Scenario: Product route is available
- **GIVEN** the user has selected a product with a resolved target location
- **WHEN** the app calculates a route
- **THEN** the customer sees a route line on the store map from Blue Dot to target

#### Scenario: Turn-by-turn is requested
- **GIVEN** a future change requests turn-by-turn arrows or instructions
- **WHEN** that change is proposed
- **THEN** it must define instruction generation, UI behavior, and recalculation rules before implementation

### Requirement: Routes recalculate when the user leaves the path
The mobile app SHALL support live route recalculation when the user's matched position has remained meaningfully off the current route.

#### Scenario: User deviates from route
- **GIVEN** an active route exists and the user has moved away from it
- **WHEN** the distance from user position to route exceeds the configured threshold for the configured hold time
- **THEN** the app recalculates or updates the route if cooldown and confidence rules allow it

#### Scenario: User briefly jitters off route
- **GIVEN** radio jitter briefly places the user outside the route
- **WHEN** the off-route condition does not persist long enough
- **THEN** the app keeps the current route to avoid battery waste and visual churn

### Requirement: Mobile layout can fall back when network is unavailable
The mobile app SHALL keep the map usable during short network failures by using persisted layout selection, recently known layout versions, or bundled layout JSON when server layout retrieval fails.

#### Scenario: Current server layout loads
- **GIVEN** the mobile app can reach the backend
- **WHEN** it opens the active store map
- **THEN** it loads the current server layout or the selected version

#### Scenario: Network is unavailable
- **GIVEN** the mobile app cannot reach the backend during startup
- **WHEN** it needs a map for customer navigation
- **THEN** it uses the best available cached, historical, or bundled layout fallback and clearly distinguishes fallback state

### Requirement: Product search requires network while map display can survive outages
The mobile experience SHALL treat product search as online behavior while allowing already available map data to remain visible during short connectivity loss.

#### Scenario: Search is online
- **GIVEN** the customer enters a product query
- **WHEN** the mobile app searches the catalog
- **THEN** the app calls the public backend search endpoint and handles unavailable network as a search error

#### Scenario: Map is already loaded
- **GIVEN** a layout has already been loaded or cached
- **WHEN** the network is lost temporarily
- **THEN** the map remains visible for orientation even if new catalog searches cannot complete

### Requirement: Mobile platform scope is iOS first
The mobile app SHALL treat iOS 15 or later as the current primary platform baseline and SHALL treat Android parity as future scope unless explicitly specified.

#### Scenario: iOS app is built
- **GIVEN** the current app is Swift/SwiftUI and uses Apple BLE/location APIs
- **WHEN** mobile behavior is changed
- **THEN** iOS constraints and permissions are addressed first

#### Scenario: Android support is requested
- **GIVEN** a future change asks for Android parity
- **WHEN** the change is proposed
- **THEN** it must define Android-specific BLE, permission, layout, and routing requirements
