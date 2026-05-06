## ADDED Requirements

### Requirement: Layout grid and scale are explicit
The system SHALL treat the store map as a grid/vector layout with real-world scale metadata sufficient for positioning and route calculation.

#### Scenario: Layout is loaded by mobile app
- **GIVEN** a layout JSON contains `gridSize` and positioned elements
- **WHEN** the mobile app loads the layout
- **THEN** it can derive map bounds and route graph coordinates from that layout

#### Scenario: Physical scale is needed
- **GIVEN** route distance, beacon accuracy, or AR alignment depends on map units
- **WHEN** a future change changes grid scale
- **THEN** it must document the relationship between map units and real metres

### Requirement: Layout objects include routable access semantics
The layout model SHALL allow blocked physical objects such as shelves and walls to remain separate from walkable aisles and access points used for navigation.

#### Scenario: Product maps to shelf slot
- **GIVEN** a product layout code resolves to a shelf, segment, compartment, or slot
- **WHEN** the route target is calculated
- **THEN** the route target is placed at a nearby walkable access point rather than inside the blocked shelf geometry

#### Scenario: Shelf has access angle metadata
- **GIVEN** a layout element includes `accessAngle` or equivalent access metadata
- **WHEN** navigation target placement uses that element
- **THEN** the app can choose the aisle-facing approach side more accurately

### Requirement: Layout JSON preserves editor fields
The layout JSON contract SHALL preserve fields needed by the admin editor and mobile app, including `shopName`, `gridSize`, `elements`, element `type`, coordinates, dimensions, label/category/meter, rotation, access angle, lock state, and beacon identifiers where present.

#### Scenario: Editor saves layout
- **GIVEN** an authorized user saves a layout from the admin editor
- **WHEN** the layout JSON is persisted
- **THEN** editor/mobile fields needed for display, routing, and beacon placement are preserved

#### Scenario: Mobile app decodes layout
- **GIVEN** the mobile app receives layout JSON
- **WHEN** optional editor fields are absent
- **THEN** the app treats absent optional fields as unavailable rather than failing the whole layout unless required fields are missing

### Requirement: Map display supports zoom and rotation
The customer-facing map experience SHALL support zoomable map inspection and SHALL preserve layout rotation metadata so rotated shelves or elements display consistently.

#### Scenario: Customer inspects map
- **GIVEN** a store layout is visible
- **WHEN** the customer zooms or pans the map
- **THEN** the map remains usable for finding product and route context

#### Scenario: Shelf is rotated
- **GIVEN** a layout element contains `rotation`
- **WHEN** the admin editor saves and the customer/mobile map renders that layout
- **THEN** the rotated element is preserved instead of being flattened to an unrotated block

### Requirement: Admin editor can place beacons in store context
The admin layout editor SHALL support placing beacon elements from the beacons assigned to the selected store so mobile positioning can use the active layout as calibration input.

#### Scenario: Store editor context loads
- **GIVEN** a store has assigned active beacons
- **WHEN** an authorized user opens `/admin/editor/?storeId=<storeId>`
- **THEN** the editor can show those assigned beacons for placement in the layout

#### Scenario: No free beacon remains
- **GIVEN** all assigned beacons are already used or no eligible beacon is available
- **WHEN** the user tries to add another beacon element
- **THEN** the editor shows an explicit unavailable/empty state

### Requirement: Layout editor keeps legacy and store modes distinct
The layout editor SHALL keep legacy global layout mode and store-specific layout mode distinct until a future change removes the legacy compatibility layer.

#### Scenario: Editor opens without store id
- **GIVEN** the editor is opened without `storeId`
- **WHEN** it loads and saves layout data
- **THEN** it uses the legacy/global layout flow

#### Scenario: Editor opens with store id
- **GIVEN** the editor is opened with `storeId`
- **WHEN** it loads and saves layout data
- **THEN** it uses store-specific layout versions for that store

### Requirement: Test-room layout artifacts are supporting inputs
The PDF test-room layout artifact SHALL be treated as supporting calibration/test context and SHALL NOT replace the JSON layout contract.

#### Scenario: Test room PDF is reviewed
- **GIVEN** `documentation/Layoutplan-Testraum.pdf` contains a simple shelf/beacon sketch with approximate dimensions
- **WHEN** a future change uses it for tests
- **THEN** the change must translate needed geometry into explicit layout JSON or test data
