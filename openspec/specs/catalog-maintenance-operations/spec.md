# catalog-maintenance-operations Specification

## Purpose
Defines catalog maintenance behavior for OpenSearch-backed products and categories, including index setup/reset, write and bulk import endpoints, deployment readiness checks, health checks, and PDF export utilities.
## Requirements
### Requirement: OpenSearch product index can be initialized
The backend SHALL provide a catalog maintenance operation for creating the OpenSearch product index used by product search.

#### Scenario: Product index is created
- **GIVEN** OpenSearch is reachable and the product index is absent
- **WHEN** an operator calls `POST /api/admin/index/create`
- **THEN** the backend creates the product index with the documented product field mappings

#### Scenario: Product index already exists
- **GIVEN** the product index already exists
- **WHEN** an operator calls the index-create endpoint again
- **THEN** the backend returns an explicit failure instead of silently redefining existing data

### Requirement: OpenSearch product index reset is destructive
The backend SHALL expose product index deletion only as an explicit maintenance/reset operation because it removes indexed product data.

#### Scenario: Product index is deleted
- **GIVEN** an operator intentionally resets product search data
- **WHEN** they call `DELETE /api/admin/index`
- **THEN** the backend deletes the product index and the operator must recreate and reimport product data before search is complete

#### Scenario: Reset is considered for production
- **GIVEN** production-like product data exists
- **WHEN** a future change automates index reset
- **THEN** it must define authorization, backup, and recovery expectations before implementation

### Requirement: Product write endpoints maintain catalog documents
The backend SHALL support indexing one product with `POST /api/products` and bulk indexing many products with `POST /api/products/bulk`.

#### Scenario: Single product is indexed
- **GIVEN** a valid product JSON document is supplied
- **WHEN** the client calls `POST /api/products`
- **THEN** the backend creates or updates the corresponding OpenSearch document

#### Scenario: Product list is bulk indexed
- **GIVEN** a JSON array of products is supplied
- **WHEN** the client calls `POST /api/products/bulk`
- **THEN** the backend indexes the supplied products in bulk and reports the processed count

### Requirement: Category maintenance supports lookup and bulk import
The backend SHALL support category listing, category-code lookup, and bulk category indexing through the category API.

#### Scenario: Category code is requested
- **GIVEN** a category has been indexed
- **WHEN** a client calls `GET /api/categories/{categoryCode}`
- **THEN** the backend returns the category or a not-found response

#### Scenario: Categories are bulk imported
- **GIVEN** a JSON array of category objects is supplied
- **WHEN** the client calls `POST /api/categories/bulk`
- **THEN** the backend indexes the categories and reports the count

### Requirement: Catalog health check is available for operations
The backend SHALL provide a health check endpoint at `GET /api/admin/health` for deployment and smoke-test workflows.

#### Scenario: Backend is reachable
- **GIVEN** the backend process is running
- **WHEN** an operator calls `/api/admin/health`
- **THEN** the backend returns an UP-style response suitable for a smoke test

#### Scenario: Protected-route policy applies
- **GIVEN** Keycloak route protection is active
- **WHEN** `/api/admin/health` is evaluated
- **THEN** the expected authentication boundary must match the current `application.properties` permission policy and deployment verification notes

### Requirement: Product data is not automatically imported on deployment
The deployment SHALL NOT assume that product JSON files in the repository automatically populate OpenSearch; operators must trigger import or bulk indexing when catalog data is needed.

#### Scenario: Backend starts with empty index
- **GIVEN** the backend is deployed and OpenSearch is reachable
- **WHEN** no product import has been run
- **THEN** product search may return empty results even though the backend itself is healthy

#### Scenario: Operator imports demo data
- **GIVEN** `backend/indooro_server/belegplan.json` or another valid catalog file is available
- **WHEN** the operator posts it to `/api/products/bulk`
- **THEN** product search can return the imported documents

### Requirement: PDF export creates belegplan PDFs from product data
The backend SHALL expose `POST /api/export/pdf` to generate a PDF belegplan-style export from supplied product data.

#### Scenario: Product list is exported
- **GIVEN** a client submits product JSON to `/api/export/pdf`
- **WHEN** PDF generation succeeds
- **THEN** the backend returns an `application/pdf` response with a download filename

#### Scenario: Export fails
- **GIVEN** the product payload or PDF generation fails
- **WHEN** the export endpoint cannot generate a valid PDF
- **THEN** the backend returns an explicit server error instead of a corrupt PDF
