## MODIFIED Requirements

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

## ADDED Requirements

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
