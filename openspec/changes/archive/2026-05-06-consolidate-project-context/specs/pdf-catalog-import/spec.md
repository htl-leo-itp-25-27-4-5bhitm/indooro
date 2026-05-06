## ADDED Requirements

### Requirement: PDF import is a planned catalog ingestion capability
The system SHALL treat supermarket PDF catalog import as a planned capability for transforming delivered product documents into structured catalog data for Indooro search.

#### Scenario: Future import implementation starts
- **WHEN** a future change implements PDF import
- **THEN** it must use this capability as the starting contract and refine unanswered parser, review, and persistence details before coding

#### Scenario: Current runtime is described
- **WHEN** current deployed behavior is documented
- **THEN** PDF import must not be claimed as fully automated production behavior unless an implementation change has added and verified it

### Requirement: Digital text-layer PDFs are the first supported input
The planned PDF import pipeline SHALL first target digital PDFs with extractable text layers before relying on OCR-heavy image extraction.

#### Scenario: Text-layer PDF is provided
- **WHEN** a supported digital PDF with extractable text is imported
- **THEN** the pipeline can extract product text without OCR as the primary mechanism

#### Scenario: Scanned image PDF is provided
- **WHEN** a scanned image-only PDF is provided before OCR support is specified
- **THEN** the pipeline must reject it or mark it unsupported rather than silently producing low-confidence data

### Requirement: PDF import produces structured JSON before persistence
The planned PDF import pipeline SHALL produce a structured JSON representation of extracted products before writing product data to backend persistence or OpenSearch.

#### Scenario: PDF extraction succeeds
- **WHEN** product rows are extracted from a PDF
- **THEN** the pipeline writes or exposes structured JSON containing the extracted product fields and mapping information before import into the catalog index

#### Scenario: Extracted data requires review
- **WHEN** extraction confidence or mapping quality is insufficient
- **THEN** the JSON output can be reviewed or rejected before catalog persistence

### Requirement: Half imports are avoided
The planned PDF import pipeline SHALL avoid partial half-imports that leave product catalog data in an inconsistent state.

#### Scenario: Import fails during validation
- **WHEN** extracted products fail validation before persistence
- **THEN** no partially validated product set is published as the active catalog data

#### Scenario: Import fails during persistence
- **WHEN** persistence fails after extraction
- **THEN** the system must preserve enough status or logs to determine whether any catalog data was written and how to recover safely

### Requirement: Imported products preserve layout mapping fields
The planned PDF import pipeline SHALL preserve or derive the product fields needed by Indooro search and location mapping, including product name, price where available, category or category code where available, and layout code where available.

#### Scenario: PDF contains layout code
- **WHEN** a product row includes a layout/location code
- **THEN** the structured JSON output preserves that code for later layout mapping

#### Scenario: PDF lacks layout code
- **WHEN** a product row lacks layout/location information
- **THEN** the output marks the location as unresolved instead of inventing one

### Requirement: PDF imports are auditable
The planned PDF import pipeline SHALL record import actions, failures, and operator-relevant status in a way that can be audited or diagnosed.

#### Scenario: Import completes
- **WHEN** a PDF import completes successfully
- **THEN** the system records enough metadata to identify source, time, result count, and operator or automation context where available

#### Scenario: Import fails
- **WHEN** a PDF import fails
- **THEN** the system records enough error detail for an operator or developer to diagnose the failure without exposing sensitive data through public routes

### Requirement: Email/PDF delivery assumptions remain explicit
The system SHALL treat product data delivered by email/PDF or similar periodic documents as an ingestion source assumption, not as a guaranteed real-time inventory feed.

#### Scenario: Product changes between PDFs
- **WHEN** products change before the next delivered document is imported
- **THEN** the system does not promise real-time inventory correctness from the PDF pipeline alone

#### Scenario: Future real-time integration is requested
- **WHEN** a future change proposes live ERP/POS integration
- **THEN** it must be specified as a separate integration capability rather than a small extension of PDF import
