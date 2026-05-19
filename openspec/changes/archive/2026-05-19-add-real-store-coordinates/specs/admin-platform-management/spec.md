## ADDED Requirements

### Requirement: Admin store management supports coordinates
The Admin Platform SHALL allow optional latitude and longitude values to be maintained for stores and SHALL validate geographic ranges before persisting them.

#### Scenario: Admin saves valid coordinates
- **GIVEN** an authorized admin or scoped manager can update a store
- **WHEN** they submit latitude between -90 and 90 and longitude between -180 and 180
- **THEN** the backend persists the coordinates with the store

#### Scenario: Admin submits invalid coordinates
- **GIVEN** an authorized admin or scoped manager can update a store
- **WHEN** latitude or longitude is outside the valid range
- **THEN** the backend rejects the store mutation without changing stored coordinates

#### Scenario: Store coordinates are optional
- **GIVEN** a store is created before exact coordinates are known
- **WHEN** the admin leaves latitude and longitude empty
- **THEN** the store can still be saved, but mobile store maps do not render a fake production pin for it
