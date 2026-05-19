## ADDED Requirements

### Requirement: Admin product writes use protected catalog maintenance API
The backend SHALL expose protected product catalog maintenance operations under `/api/admin/products` for Admin Platform product creation and updates.

#### Scenario: Admin indexes single product through admin API
- **GIVEN** an authenticated `admin` with an active Indooro access assignment submits a valid product document
- **WHEN** the client calls `POST /api/admin/products`
- **THEN** the backend validates the product and creates or updates the matching OpenSearch document

#### Scenario: Public search remains available
- **GIVEN** public customer product search routes are configured
- **WHEN** an anonymous customer calls product read or search endpoints under `/api/products`
- **THEN** product search/read behavior remains available without requiring an admin login

#### Scenario: Invalid admin product is submitted
- **GIVEN** an authenticated admin submits a product missing id, name, price, or layout code
- **WHEN** the backend validates the request
- **THEN** it returns a bad-request response and does not index the product
