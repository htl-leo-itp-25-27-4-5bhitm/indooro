## ADDED Requirements

### Requirement: Shopping lists are local mobile app state
The mobile app SHALL support local customer shopping lists without requiring server-side customer accounts or server-side customer tracking.

#### Scenario: Customer creates a list
- **GIVEN** the customer is using the iOS app
- **WHEN** they create a shopping list with a non-empty name
- **THEN** the list is persisted locally on the device

#### Scenario: Customer identity is absent
- **GIVEN** shopping-list state exists locally
- **WHEN** the app stores list data
- **THEN** it does not require a backend customer identity

### Requirement: Products can be added to shopping lists
The mobile app SHALL allow a searched product to be added to a shopping list with product id, name, price, layout code, quantity, optional note, and item status.

#### Scenario: Product is added
- **GIVEN** a product search result has product identity and layout code data
- **WHEN** the customer adds it to a shopping list
- **THEN** the app stores a list item that can later be resolved to a shelf target

#### Scenario: Duplicate open product exists
- **GIVEN** the selected list already contains the same open product and layout code
- **WHEN** the customer attempts to add it again
- **THEN** the app prevents duplicate open entries or updates the existing local list state according to the implemented UI behavior

### Requirement: Shopping item statuses are explicit
The mobile app SHALL track shopping item state as open, done, missing, or skipped so a shopping session can distinguish routable and completed items.

#### Scenario: Item is marked done
- **GIVEN** an open shopping item is visible in a shopping session
- **WHEN** the customer marks it done
- **THEN** the item is counted as completed and removed from remaining route stops

#### Scenario: Item cannot be found
- **GIVEN** the customer cannot find an item at the target shelf
- **WHEN** they mark it missing or skipped
- **THEN** the item is treated as completed for session progress without claiming the product was purchased

### Requirement: Shopping stops resolve by layout code
The mobile app SHALL group open shopping items into route stops by resolving product layout codes to shelf/layout elements in the active layout.

#### Scenario: Multiple items share a shelf
- **GIVEN** multiple open items resolve to the same shelf element
- **WHEN** the app builds a shopping route snapshot
- **THEN** those items are grouped into one stop

#### Scenario: Item cannot be resolved
- **GIVEN** a shopping item has no matching shelf/layout element
- **WHEN** the route snapshot is built
- **THEN** the item appears as unresolved instead of being placed at an invented map target

### Requirement: Shopping route order supports list order and optimized mode
The mobile app SHALL support route stop ordering by list order and by an optimized nearest-next-stop mode when user position and layout graph data are available.

#### Scenario: List-order mode is selected
- **GIVEN** a shopping list has multiple resolved stops
- **WHEN** route mode is list order
- **THEN** stops are ordered by the item/list order seed

#### Scenario: Optimized mode is selected
- **GIVEN** a user position and routable layout graph are available
- **WHEN** route mode is optimized
- **THEN** the app may order stops by estimated route distance from current position and previously selected stops

### Requirement: Shopping transfer files are versioned
The mobile app SHALL export and import shopping lists through a versioned Indooro shopping-list transfer package.

#### Scenario: List is exported
- **GIVEN** a selected shopping list has at least one item
- **WHEN** the customer exports or shares it
- **THEN** the app writes a versioned `.indoorolist` package containing transfer items

#### Scenario: Unsupported transfer version is imported
- **GIVEN** the customer imports an Indooro shopping-list file
- **WHEN** the package version is unsupported
- **THEN** the app rejects the import with a clear error state

### Requirement: Shared backend shopping lists are future scope
The system SHALL NOT treat local mobile shopping lists as shared backend shopping-list persistence unless a future OpenSpec change defines customer identity, synchronization, conflict handling, and privacy boundaries.

#### Scenario: Backend sync is requested
- **GIVEN** local shopping-list functionality exists
- **WHEN** a future change requests cross-device or server-backed shopping lists
- **THEN** the proposal must define identity, storage, synchronization, and privacy behavior before implementation
