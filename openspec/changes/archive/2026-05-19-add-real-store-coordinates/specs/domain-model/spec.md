## ADDED Requirements

### Requirement: Stores can carry real outdoor coordinates
The store domain model SHALL support nullable latitude and longitude fields for real-world store positions used by mobile store selection maps.

#### Scenario: Store has coordinates
- **GIVEN** a store record has latitude and longitude values
- **WHEN** backend APIs build store responses
- **THEN** the store can be represented at its persisted real-world coordinate

#### Scenario: Store lacks coordinates
- **GIVEN** a store record has no latitude or longitude
- **WHEN** a mobile store map is rendered
- **THEN** the client must not invent a fake production coordinate for that store

#### Scenario: Coordinates are validated
- **GIVEN** an admin creates or updates store coordinates
- **WHEN** latitude or longitude is outside the valid geographic range
- **THEN** the backend rejects the invalid coordinate values
