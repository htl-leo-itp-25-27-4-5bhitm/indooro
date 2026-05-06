## ADDED Requirements

### Requirement: Store layouts are versioned per store
The system SHALL manage store layouts as store-specific versions and SHALL identify which version is active/current for client use.

#### Scenario: New layout version is created
- **WHEN** an authorized admin saves a new layout version for a store
- **THEN** the version belongs to that store and can be distinguished from prior versions

#### Scenario: Current layout is requested
- **WHEN** a client requests the current layout for a store
- **THEN** the system returns the active version for that store if one exists

### Requirement: Admin layout editor manages physical map objects
The Admin Platform SHALL support layout data that can represent physical map objects such as walls, shelves, aisles, cashiers, entrances, and points of interest.

#### Scenario: Store employee edits shelf layout
- **WHEN** an authorized user edits shelf or aisle objects in the admin layout workflow
- **THEN** the saved layout data can represent those objects for later mobile display and routing

#### Scenario: Layout contains entrance and cashier
- **WHEN** a layout contains entrance or cashier objects
- **THEN** the layout data preserves them as meaningful map objects rather than anonymous decorative elements

### Requirement: Layout editor workflows are no-code oriented
The system SHALL treat layout editing as an admin/staff workflow that should be usable without code changes and can support draw, move, resize, rotate, snap, group, delete, and layer concepts as future editor capabilities.

#### Scenario: Future snapping behavior is added
- **WHEN** a future change adds snap-to-grid or object snapping
- **THEN** it must preserve the saved layout data contract and document the interaction in OpenSpec

#### Scenario: Future layer behavior is added
- **WHEN** a future change adds layout layers
- **THEN** the change must define how layer visibility and persistence work before implementation

### Requirement: Mobile current-layout route is public
The system SHALL expose the current layout needed by the mobile customer experience through a public mobile route unless a future OpenSpec change explicitly changes that route boundary.

#### Scenario: Anonymous mobile client opens map
- **WHEN** an anonymous mobile client requests `/api/mobile/stores/{storeId}/layout/current`
- **THEN** the backend returns the active layout for that store without requiring admin login

#### Scenario: Store has no active layout
- **WHEN** a mobile client requests the current layout for a store without an active layout
- **THEN** the system returns an explicit not-found or empty-state response rather than a misleading layout

### Requirement: Admin layout routes are protected
The system SHALL protect admin layout routes under `/api/stores/{storeId}/layout/*` and SHALL apply role/scope checks before reading or mutating layout versions.

#### Scenario: Admin edits any store layout
- **WHEN** an authenticated `admin` edits a layout for any store
- **THEN** the system allows the operation if existing layout validation passes

#### Scenario: Store manager edits another store layout
- **WHEN** a `store-manager` tries to edit a layout outside the assigned store
- **THEN** the system rejects the operation

### Requirement: Product locations map to layout targets
The system SHALL enable products with valid layout codes to map to layout targets such as shelf areas or nearby walkable target points.

#### Scenario: Product has valid layout code
- **WHEN** a product with a valid layout code is selected
- **THEN** the mobile experience can identify the corresponding layout target when the layout contains matching location data

#### Scenario: Layout target is blocked
- **WHEN** a product location maps to a shelf or blocked object
- **THEN** routing should target a nearby walkable point rather than routing through the blocked object

### Requirement: Routing uses walkable areas
The mobile routing model SHALL route through walkable areas such as aisles and SHALL avoid walls, shelves, and other blocked layout objects.

#### Scenario: Route is calculated to product target
- **WHEN** a mobile client calculates a route to a product target
- **THEN** the route follows walkable layout space and avoids blocked objects

#### Scenario: No walkable path exists
- **WHEN** no valid walkable path exists between start and target
- **THEN** the client or backend route workflow must show an explicit no-route state rather than drawing an invalid path

### Requirement: MVP layout assumptions are explicit
The system SHALL treat one-floor layouts, approximate grid/vector representation, and one-product route targets as MVP assumptions unless expanded by a future OpenSpec change.

#### Scenario: Multi-floor support is requested
- **WHEN** a future change requests multi-floor navigation
- **THEN** the proposal must define floor transitions, layout data shape, and route behavior

#### Scenario: Shopping-list optimization is requested
- **WHEN** a future change requests optimized routes across multiple products
- **THEN** the proposal must define ordering, route recalculation, and UI behavior before implementation
