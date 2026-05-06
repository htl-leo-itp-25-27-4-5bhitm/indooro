# product-catalog-search Specification

## Purpose
Defines public product and category search behavior, OpenSearch-backed catalog expectations, product document location fields, layout-code semantics, store-aware search direction, and unsupported category-code route assumptions.
## Requirements
### Requirement: Product catalog routes are public customer routes
The system SHALL keep customer product and category lookup routes public unless a future OpenSpec change explicitly protects them.

#### Scenario: Anonymous client lists products
- **GIVEN** the OpenSearch-backed catalog API is configured
- **WHEN** an anonymous client requests `/api/products`
- **THEN** the system processes the request without requiring Admin Platform login

#### Scenario: Anonymous client lists categories
- **GIVEN** the OpenSearch-backed catalog API is configured
- **WHEN** an anonymous client requests `/api/categories`
- **THEN** the system processes the request without requiring Admin Platform login

### Requirement: Product documents include location mapping data
The system SHALL represent searchable products with enough data to display product information and map the product to a store layout location, including at least product id, name, price where available, and layout code where available.

#### Scenario: Product search result is shown in mobile app
- **GIVEN** the OpenSearch-backed catalog API is configured
- **WHEN** a product appears in a search result
- **THEN** the client can display the product identity and use its layout code to locate the product in the store layout when the code is present

#### Scenario: Product lacks layout code
- **GIVEN** the OpenSearch-backed catalog API is configured
- **WHEN** a product has no usable layout code
- **THEN** the client can still display the product but must not claim a precise shelf location from that product alone

### Requirement: Layout code format is documented
The system SHALL treat the documented product layout code as a structured slash-separated location code composed of category code, meter, shelf compartment (`fach`), and row/slot (`reihe`), for example `310/1/1/1`.

#### Scenario: Layout code is parsed by future routing work
- **GIVEN** a product has a layout code such as `310/2/3/1`
- **WHEN** a future change maps products to shelf targets
- **THEN** it can use the category code, meter, compartment, and row/slot portions of the layout code as the documented semantic parts

#### Scenario: Invalid layout code is encountered
- **GIVEN** a product contains a layout code that does not match `{categoryCode}/{meter}/{fach}/{reihe}`
- **WHEN** the system or client attempts precise location mapping
- **THEN** the precise location is treated as unresolved rather than inventing a shelf target

### Requirement: Product search uses OpenSearch-backed catalog data
The system SHALL use OpenSearch-backed product and category indexes for customer catalog lookup and search workflows.

#### Scenario: Product search is requested
- **GIVEN** the OpenSearch-backed catalog API is configured
- **WHEN** a client searches products by text query
- **THEN** the backend queries the configured OpenSearch product index and returns matching product documents according to the implemented search contract

#### Scenario: Category list is requested
- **GIVEN** the OpenSearch-backed catalog API is configured
- **WHEN** a client requests categories
- **THEN** the backend returns category data from the configured catalog/search source

### Requirement: Store-aware catalog data is preferred
The system SHALL preserve store identity in product catalog data where multi-store correctness matters, so future search and navigation can return products for the selected or detected store.

#### Scenario: Product exists in multiple stores
- **GIVEN** the OpenSearch-backed catalog API is configured
- **WHEN** product catalog data contains the same product name in multiple stores
- **THEN** the search workflow can distinguish the store-specific product record or location

#### Scenario: Mobile client has selected store
- **GIVEN** the OpenSearch-backed catalog API is configured
- **WHEN** a mobile client searches after selecting or detecting a store
- **THEN** the search behavior can be scoped to the selected store when the route supports store scoping

### Requirement: Search quality improvements remain compatible with the catalog contract
The system SHALL allow future fuzzy, synonym, colloquial, and typo-tolerant search improvements without changing the public expectation that products are searchable anonymously and map back to product documents.

#### Scenario: User searches colloquial term
- **GIVEN** the OpenSearch-backed catalog API is configured
- **WHEN** a future search change adds synonym or colloquial matching
- **THEN** the response still returns normal product documents usable by the existing mobile/catalog UI

#### Scenario: Ranking changes
- **GIVEN** the OpenSearch-backed catalog API is configured
- **WHEN** a future change changes OpenSearch ranking
- **THEN** the change must preserve the documented response contract for product identity and location mapping

### Requirement: Category-code product lookup is not assumed
The system SHALL NOT treat a dedicated route for "products by category code" as available unless a future OpenSpec change adds or documents the route, request parameters, store scope, and response shape.

#### Scenario: Developer needs products for one category code
- **GIVEN** the OpenSearch-backed catalog API is configured
- **WHEN** a future feature needs to fetch products by category code
- **THEN** the change must either use an existing documented search/filter contract or add a new OpenSpec requirement and implementation for that route

#### Scenario: User asks whether category-code lookup exists
- **GIVEN** the OpenSearch-backed catalog API is configured
- **WHEN** the implemented routes are reviewed
- **THEN** only documented product, product search, and category routes can be claimed as existing behavior

### Requirement: Product search supports bounded result sets
The product search API SHALL support a query string and result-size limit so customer clients can request a bounded set of matching products.

#### Scenario: Query is provided
- **GIVEN** OpenSearch is reachable and product data exists
- **WHEN** a client calls `/api/products/search?q=<term>&size=<limit>`
- **THEN** the backend returns at most the requested bounded result set according to the implemented search contract

#### Scenario: Query is missing
- **GIVEN** a client calls the search endpoint without a non-empty query
- **WHEN** the request is processed
- **THEN** the backend returns a bad-request response instead of running an unbounded search

### Requirement: Empty search results are explicit
The customer search workflow SHALL handle no-result searches explicitly and SHALL NOT invent product locations or category suggestions that are not returned by the backend.

#### Scenario: No product matches
- **GIVEN** the customer searches for a term with no indexed product match
- **WHEN** the backend returns an empty result set
- **THEN** the client shows a no-result state instead of selecting a false product target

#### Scenario: Alternative suggestions are added later
- **GIVEN** a future change adds category suggestions or synonyms for no-result searches
- **WHEN** that change is implemented
- **THEN** suggestions must be based on documented search/index data rather than hardcoded guesses

### Requirement: Search latency target is documented
The customer search experience SHALL target results within about 300 milliseconds under good network and OpenSearch conditions, while still handling slower or failed requests gracefully.

#### Scenario: Search is fast
- **GIVEN** the network and OpenSearch are healthy
- **WHEN** a customer searches for a product
- **THEN** results should appear quickly enough to feel near-instant in the mobile/customer UI

#### Scenario: Search is slow or unavailable
- **GIVEN** the request exceeds the expected latency or fails
- **WHEN** the client receives timeout/error behavior
- **THEN** the UI shows loading or error feedback without blocking already loaded map context

### Requirement: Category lookup by code is supported
The category API SHALL allow clients to list categories and fetch a category by category code, while product-by-category lookup remains separate unless explicitly added.

#### Scenario: Category exists
- **GIVEN** a category document with the requested category code exists
- **WHEN** a client calls `/api/categories/{categoryCode}`
- **THEN** the backend returns that category document

#### Scenario: Products by category are requested
- **GIVEN** a client needs all products for a category code
- **WHEN** no documented product-by-category endpoint exists
- **THEN** the change must add or reuse an explicit product search/filter contract before claiming support

