## MODIFIED Requirements

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

## ADDED Requirements

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
