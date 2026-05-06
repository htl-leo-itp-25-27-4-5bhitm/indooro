# pdf-catalog-import Specification

## Purpose
Defines the planned PDF catalog ingestion capability, including text-layer input assumptions, JSON-first extraction, validation, all-or-nothing publication expectations, layout mapping fields, and import auditability.
## Requirements
### Requirement: PDF import is a planned catalog ingestion capability
The system SHALL treat supermarket PDF catalog import as a staged capability. Current code may convert supported text-layer PDFs to JSON-like product data through utility endpoints, but fully automated production ingestion into the active catalog remains planned unless a future change verifies validation, review, persistence, rollback, and audit behavior.

#### Scenario: Current PDF conversion is used
- **GIVEN** a supported text-layer PDF is uploaded to the current conversion utility
- **WHEN** the backend parses the PDF successfully
- **THEN** it can return extracted product-like JSON data without claiming the active catalog was updated

#### Scenario: Future import implementation starts
- **GIVEN** a future change implements production catalog import from PDFs
- **WHEN** it starts planning
- **THEN** it must refine unanswered parser, review, validation, persistence, rollback, and audit details before coding

#### Scenario: Current runtime is described
- **GIVEN** current deployed behavior is documented
- **WHEN** PDF import is mentioned
- **THEN** it must not be claimed as fully automated production catalog ingestion unless an implementation change has added and verified it

### Requirement: Digital text-layer PDFs are the first supported input
The planned PDF import pipeline SHALL first target digital PDFs with extractable text layers before relying on OCR-heavy image extraction.

#### Scenario: Text-layer PDF is provided
- **GIVEN** the PDF import/export capability is being evaluated
- **WHEN** a supported digital PDF with extractable text is imported
- **THEN** the pipeline can extract product text without OCR as the primary mechanism

#### Scenario: Scanned image PDF is provided
- **GIVEN** the PDF import/export capability is being evaluated
- **WHEN** a scanned image-only PDF is provided before OCR support is specified
- **THEN** the pipeline must reject it or mark it unsupported rather than silently producing low-confidence data

### Requirement: PDF import produces structured JSON before persistence
The planned PDF import pipeline SHALL produce a structured JSON representation of extracted products before writing product data to backend persistence or OpenSearch.

#### Scenario: PDF extraction succeeds
- **GIVEN** the PDF import/export capability is being evaluated
- **WHEN** product rows are extracted from a PDF
- **THEN** the pipeline writes or exposes structured JSON containing the extracted product fields and mapping information before import into the catalog index

#### Scenario: Extracted data requires review
- **GIVEN** the PDF import/export capability is being evaluated
- **WHEN** extraction confidence or mapping quality is insufficient
- **THEN** the JSON output can be reviewed or rejected before catalog persistence

### Requirement: Half imports are avoided
The planned PDF import pipeline SHALL avoid partial half-imports that leave product catalog data in an inconsistent state.

#### Scenario: Import fails during validation
- **GIVEN** the PDF import/export capability is being evaluated
- **WHEN** extracted products fail validation before persistence
- **THEN** no partially validated product set is published as the active catalog data

#### Scenario: Import fails during persistence
- **GIVEN** the PDF import/export capability is being evaluated
- **WHEN** persistence fails after extraction
- **THEN** the system must preserve enough status or logs to determine whether any catalog data was written and how to recover safely

### Requirement: Imported products preserve layout mapping fields
The planned PDF import pipeline SHALL preserve or derive the product fields needed by Indooro search and location mapping, including product name, price where available, category or category code where available, and layout code where available.

#### Scenario: PDF contains layout code
- **GIVEN** the PDF import/export capability is being evaluated
- **WHEN** a product row includes a layout/location code
- **THEN** the structured JSON output preserves that code for later layout mapping

#### Scenario: PDF lacks layout code
- **GIVEN** the PDF import/export capability is being evaluated
- **WHEN** a product row lacks layout/location information
- **THEN** the output marks the location as unresolved instead of inventing one

### Requirement: PDF imports are auditable
The planned PDF import pipeline SHALL record import actions, failures, and operator-relevant status in a way that can be audited or diagnosed.

#### Scenario: Import completes
- **GIVEN** the PDF import/export capability is being evaluated
- **WHEN** a PDF import completes successfully
- **THEN** the system records enough metadata to identify source, time, result count, and operator or automation context where available

#### Scenario: Import fails
- **GIVEN** the PDF import/export capability is being evaluated
- **WHEN** a PDF import fails
- **THEN** the system records enough error detail for an operator or developer to diagnose the failure without exposing sensitive data through public routes

### Requirement: Email/PDF delivery assumptions remain explicit
The system SHALL treat product data delivered by email/PDF or similar periodic documents as an ingestion source assumption, not as a guaranteed real-time inventory feed.

#### Scenario: Product changes between PDFs
- **GIVEN** the PDF import/export capability is being evaluated
- **WHEN** products change before the next delivered document is imported
- **THEN** the system does not promise real-time inventory correctness from the PDF pipeline alone

#### Scenario: Future real-time integration is requested
- **GIVEN** the PDF import/export capability is being evaluated
- **WHEN** a future change proposes live ERP/POS integration
- **THEN** it must be specified as a separate integration capability rather than a small extension of PDF import

### Requirement: PDF conversion endpoint returns JSON before persistence
The backend SHALL expose current PDF-to-JSON conversion as a utility behavior that returns extracted product rows before any catalog persistence step.

#### Scenario: PDF file is uploaded
- **GIVEN** a multipart PDF file is uploaded to `/api/convert/pdf-to-json`
- **WHEN** the file exists and parsing succeeds
- **THEN** the backend returns JSON containing extracted id, name, and layout code fields where available

#### Scenario: No file is uploaded
- **GIVEN** the conversion endpoint receives no usable file
- **WHEN** the request is processed
- **THEN** the backend returns a bad-request response

### Requirement: Text-layer extraction is the current parser path
The current PDF conversion utility SHALL rely on extractable text from PDFBox-style parsing and SHALL NOT silently promise OCR for scanned/image-only PDFs.

#### Scenario: Text is extractable
- **GIVEN** the PDF contains a text layer matching the expected belegplan patterns
- **WHEN** the conversion utility parses it
- **THEN** rows can be extracted into structured items

#### Scenario: PDF is scanned image only
- **GIVEN** a scanned image PDF lacks extractable text
- **WHEN** the current conversion utility processes it
- **THEN** it returns no reliable extracted products or an error instead of fabricating data

### Requirement: Belegplan PDF export is separate from import
The backend SHALL keep PDF export from product JSON separate from PDF import/conversion so agents do not confuse generated belegplan PDFs with source ingestion documents.

#### Scenario: Export endpoint is called
- **GIVEN** a client supplies product JSON to `/api/export/pdf`
- **WHEN** PDF generation succeeds
- **THEN** the backend returns a generated PDF document

#### Scenario: Import pipeline is discussed
- **GIVEN** the export endpoint exists
- **WHEN** a future change discusses production ingestion from delivered PDFs
- **THEN** it must not treat export behavior as proof that external PDF import is production-ready

