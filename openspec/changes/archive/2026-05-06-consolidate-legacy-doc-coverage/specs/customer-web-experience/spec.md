## ADDED Requirements

### Requirement: Customer web view is hosted by the backend
The system SHALL serve the customer web experience from the Quarkus backend under `/customer/` alongside the Admin Platform and landing page.

#### Scenario: Customer opens hosted page
- **GIVEN** the backend is running with static resources enabled
- **WHEN** a customer opens `/customer/`
- **THEN** the backend serves the customer web page without requiring Admin Platform login

#### Scenario: Customer route is deployed to LeoCloud
- **GIVEN** the LeoCloud ingress routes `/` to the backend service
- **WHEN** the customer web path is requested on the public host
- **THEN** the page is reachable through the same public host as the backend APIs

### Requirement: Customer web uses public catalog and layout APIs
The customer web experience SHALL use public product/category/search and legacy layout APIs so anonymous users can search products and view the map.

#### Scenario: Anonymous customer searches
- **GIVEN** the customer page has loaded
- **WHEN** the customer enters a product query
- **THEN** the page calls public product search APIs without Keycloak login

#### Scenario: Customer map loads
- **GIVEN** a legacy current layout exists
- **WHEN** the customer page needs a map
- **THEN** it can load `/api/layout/current` without Admin Platform authentication

### Requirement: Customer web remains a compatibility surface
The system SHALL treat the customer web view as a compatibility/demo surface that may still use the legacy global layout flow until a future change migrates it to store-specific layouts.

#### Scenario: Store-specific layouts exist
- **GIVEN** store-specific layout versions exist in PostgreSQL
- **WHEN** the current customer web view loads map data
- **THEN** it is not assumed to consume `/api/mobile/stores/{storeId}/layout/current`

#### Scenario: Customer web migration is requested
- **GIVEN** the Admin Platform and mobile routes support store-specific layouts
- **WHEN** a future change migrates `/customer/` to store-specific layout selection
- **THEN** the change must define store selection, layout source, fallback, and public route behavior

### Requirement: Customer web does not create customer accounts
The customer web experience SHALL remain anonymous and SHALL NOT create customer profiles, payment flows, analytics tracking, or server-side live position storage as baseline behavior.

#### Scenario: Anonymous web user opens customer view
- **GIVEN** a user opens the customer page
- **WHEN** they search or view a layout
- **THEN** the system does not require registration or login

#### Scenario: Analytics is requested
- **GIVEN** a future change proposes customer analytics or behavior tracking
- **WHEN** the change is proposed
- **THEN** it must define consent, data retention, and privacy requirements before implementation
