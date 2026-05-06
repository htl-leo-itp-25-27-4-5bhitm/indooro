## ADDED Requirements

### Requirement: Product catalog routes are public customer routes
The system SHALL keep customer product and category lookup routes public unless a future OpenSpec change explicitly protects them.

#### Scenario: Anonymous client lists products
- **WHEN** an anonymous client requests `/api/products`
- **THEN** the system processes the request without requiring Admin Platform login

#### Scenario: Anonymous client lists categories
- **WHEN** an anonymous client requests `/api/categories`
- **THEN** the system processes the request without requiring Admin Platform login

### Requirement: Product documents include location mapping data
The system SHALL represent searchable products with enough data to display product information and map the product to a store layout location, including at least product id, name, price where available, and layout code where available.

#### Scenario: Product search result is shown in mobile app
- **WHEN** a product appears in a search result
- **THEN** the client can display the product identity and use its layout code to locate the product in the store layout when the code is present

#### Scenario: Product lacks layout code
- **WHEN** a product has no usable layout code
- **THEN** the client can still display the product but must not claim a precise shelf location from that product alone

### Requirement: Layout code format is documented
The system SHALL treat the documented product layout code as a structured location code composed of category code, meter, shelf compartment (`fach`), and row (`reihe`), for example `OBST-01-A-02`.

#### Scenario: Layout code is parsed by future routing work
- **WHEN** a future change maps products to shelf targets
- **THEN** it can use the category code, meter, compartment, and row portions of the layout code as the documented semantic parts

#### Scenario: Invalid layout code is encountered
- **WHEN** a product contains a layout code that does not match the documented structure
- **THEN** the system or client must treat the precise location as unresolved rather than inventing a shelf target

### Requirement: Product search uses OpenSearch-backed catalog data
The system SHALL use OpenSearch-backed product and category indexes for customer catalog lookup and search workflows.

#### Scenario: Product search is requested
- **WHEN** a client searches products by text query
- **THEN** the backend queries the configured OpenSearch product index and returns matching product documents according to the implemented search contract

#### Scenario: Category list is requested
- **WHEN** a client requests categories
- **THEN** the backend returns category data from the configured catalog/search source

### Requirement: Store-aware catalog data is preferred
The system SHALL preserve store identity in product catalog data where multi-store correctness matters, so future search and navigation can return products for the selected or detected store.

#### Scenario: Product exists in multiple stores
- **WHEN** product catalog data contains the same product name in multiple stores
- **THEN** the search workflow can distinguish the store-specific product record or location

#### Scenario: Mobile client has selected store
- **WHEN** a mobile client searches after selecting or detecting a store
- **THEN** the search behavior can be scoped to the selected store when the route supports store scoping

### Requirement: Search quality improvements remain compatible with the catalog contract
The system SHALL allow future fuzzy, synonym, colloquial, and typo-tolerant search improvements without changing the public expectation that products are searchable anonymously and map back to product documents.

#### Scenario: User searches colloquial term
- **WHEN** a future search change adds synonym or colloquial matching
- **THEN** the response still returns normal product documents usable by the existing mobile/catalog UI

#### Scenario: Ranking changes
- **WHEN** a future change changes OpenSearch ranking
- **THEN** the change must preserve the documented response contract for product identity and location mapping

### Requirement: Category-code product lookup is not assumed
The system SHALL NOT treat a dedicated route for "products by category code" as available unless a future OpenSpec change adds or documents the route, request parameters, store scope, and response shape.

#### Scenario: Developer needs products for one category code
- **WHEN** a future feature needs to fetch products by category code
- **THEN** the change must either use an existing documented search/filter contract or add a new OpenSpec requirement and implementation for that route

#### Scenario: User asks whether category-code lookup exists
- **WHEN** the implemented routes are reviewed
- **THEN** only documented product, product search, and category routes can be claimed as existing behavior
