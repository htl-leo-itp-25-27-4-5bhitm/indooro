## MODIFIED Requirements

### Requirement: MVP boundaries are maintained
The system SHALL treat one-store-at-a-time customer search, one-floor store layouts, one-product route guidance, anonymous customer/mobile use, and authenticated admin management as the MVP baseline. Local/demo app enhancements such as shopping lists or AR route previews SHALL be documented separately and SHALL NOT imply shared backend customer accounts, Android parity, analytics, live inventory, or production-grade multi-product fulfillment unless a future OpenSpec change expands scope.

#### Scenario: Multi-product backend shopping lists are requested
- **GIVEN** the app has local shopping-list assistance
- **WHEN** a future change requests backend-synchronized shopping lists or shared customer accounts
- **THEN** the change must document it as an MVP expansion rather than existing baseline behavior

#### Scenario: Android parity is requested
- **GIVEN** the current mobile implementation is iOS-first
- **WHEN** a future change requests Android application support
- **THEN** the change must define Android-specific requirements instead of assuming the existing iOS MVP covers it

#### Scenario: AR navigation is reviewed
- **GIVEN** AR route preview code exists in the iOS app
- **WHEN** the project MVP boundary is evaluated
- **THEN** standard 2D map guidance remains the baseline customer navigation contract

## ADDED Requirements

### Requirement: Legacy documentation is audit input, not runtime truth by itself
OpenSpec SHALL preserve durable decisions from legacy documentation, but SHALL resolve conflicts by checking current code, current specs, and current deployment context before treating old statements as runtime truth.

#### Scenario: Legacy doc predates Keycloak
- **GIVEN** a legacy document says admin APIs were anonymous before the Keycloak sprint
- **WHEN** a future change evaluates current admin security behavior
- **THEN** the current Keycloak-protected OpenSpec requirements and code configuration take precedence

#### Scenario: Legacy doc describes a future wish
- **GIVEN** a legacy FSD answer describes a desired future feature
- **WHEN** the feature is not implemented or not archived into current specs
- **THEN** OpenSpec must mark it as future/planned rather than current runtime behavior

### Requirement: Language scope is explicit
The project SHALL treat English as the preferred language for OpenSpec, code-facing artifacts, and agent instructions, while customer/admin UI language support may include German and English when explicitly scoped.

#### Scenario: New OpenSpec artifact is created
- **GIVEN** a future change creates specs, design, or tasks
- **WHEN** artifact text is written
- **THEN** it should use English for durable technical requirements unless the user asks otherwise

#### Scenario: Customer multilingual UX is requested
- **GIVEN** FSD identified German and English as desired UI languages
- **WHEN** a future change implements multilingual customer/admin UI
- **THEN** the change must define supported locales, fallback language, translated surfaces, and test expectations
