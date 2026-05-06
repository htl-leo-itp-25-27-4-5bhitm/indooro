## ADDED Requirements

### Requirement: Admin domain uniqueness constraints are explicit
The database model SHALL enforce uniqueness for region codes, store codes, beacon codes, beacon identity keys, one active layout per store, and one active assignment per beacon where those constraints are part of the current schema.

#### Scenario: Duplicate store code is created
- **GIVEN** a store with the requested store code already exists
- **WHEN** an admin attempts to create another store with the same code
- **THEN** the database/backend rejects the duplicate identity

#### Scenario: Second active layout is activated
- **GIVEN** a store already has an active layout version
- **WHEN** another layout version for the same store is activated
- **THEN** the system ensures only one layout version remains active for that store

### Requirement: Runtime sample data is illustrative
Runtime object diagrams and sample database values SHALL be treated as illustrative current-state evidence, not permanent business constants.

#### Scenario: Sample region exists
- **GIVEN** documentation shows sample region/store/beacon IDs from LeoCloud
- **WHEN** a future change uses those examples
- **THEN** it must not hardcode those UUIDs as permanent business identifiers unless explicitly seeded for demo users or tests

#### Scenario: Sample data reveals inconsistency
- **GIVEN** runtime documentation shows active beacons assigned to one store and an active layout belonging to another store
- **WHEN** a future change depends on aligned store/layout/beacon data
- **THEN** it must verify or seed coherent test/demo data before using the sample state as proof

### Requirement: Error logs capture failed API requests
The domain model SHALL persist operational error records with status code, method, path, message, error type, stack trace where available, and timestamps for protected diagnostics.

#### Scenario: Validation request fails
- **GIVEN** an admin API request fails validation
- **WHEN** the error mapper records the failure
- **THEN** an error log record can be inspected by authorized diagnostics users

#### Scenario: Error data is exposed
- **GIVEN** error log records exist
- **WHEN** a client requests protected error logs as an authorized admin
- **THEN** the response includes diagnostic fields without exposing them through anonymous routes
