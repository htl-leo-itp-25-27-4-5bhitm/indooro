## ADDED Requirements

### Requirement: Admin product management is available in the Admin Platform
The Admin Platform SHALL provide a product management surface that lets authorized admins create or update product catalog documents with product id, name, price, and layout code.

#### Scenario: Admin creates product
- **GIVEN** an authenticated user with the `admin` role and an active Indooro admin assignment opens the Admin Platform
- **WHEN** the user submits a valid product with id, name, price, and layout code
- **THEN** the Admin Platform sends the product to the protected admin product API and shows a success state after the product is indexed

#### Scenario: Product form is incomplete
- **GIVEN** an authenticated admin is using the product management form
- **WHEN** the user submits a product without a required field or with a negative price
- **THEN** the system rejects the submission and keeps the existing catalog unchanged

#### Scenario: Non-admin opens Admin Platform
- **GIVEN** an authenticated `region-manager` or `store-manager` opens the Admin Platform
- **WHEN** role-aware UI state is applied
- **THEN** product management navigation and product mutation controls are not displayed
