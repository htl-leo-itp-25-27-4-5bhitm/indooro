## ADDED Requirements

### Requirement: Indooro mission is explicit
Indooro SHALL be specified as a system that helps anonymous supermarket customers find products inside a selected or detected store and helps authorized staff manage the store data required for that experience.

#### Scenario: Future change starts from OpenSpec
- **WHEN** a future change proposes new mobile, admin, catalog, layout, or deployment behavior
- **THEN** the change can identify whether it supports customer product finding, staff data management, or an explicitly documented future goal

#### Scenario: Server-side customer tracking is proposed
- **WHEN** a future change proposes storing customer identities or live customer positions server-side
- **THEN** the proposal must treat that behavior as new scope and must not assume it is part of the Indooro MVP

### Requirement: MVP boundaries are maintained
The system SHALL treat one-store-at-a-time customer search, one-floor store layouts, one-product route guidance, anonymous mobile use, and authenticated admin management as the MVP baseline unless a future OpenSpec change expands scope.

#### Scenario: Multi-product route optimization is requested
- **WHEN** a future change requests optimized shopping-list routing across multiple products
- **THEN** the change must document it as an MVP expansion rather than existing baseline behavior

#### Scenario: Android parity is requested
- **WHEN** a future change requests Android application support
- **THEN** the change must define Android-specific requirements instead of assuming the existing iOS MVP covers it

### Requirement: Stakeholder roles are documented
The system SHALL distinguish anonymous customer/mobile users from authenticated Admin Platform users and SHALL use the admin roles `admin`, `region-manager`, and `store-manager` for protected management workflows.

#### Scenario: Anonymous customer searches products
- **WHEN** an anonymous customer uses public catalog or mobile routes
- **THEN** the system treats the user as a customer/mobile user and does not require Admin Platform login

#### Scenario: Staff member manages store data
- **WHEN** a staff member opens the Admin Platform
- **THEN** the system requires Keycloak authentication and maps the user to one of the documented admin roles before protected data is returned

### Requirement: Source documentation is represented in OpenSpec
OpenSpec SHALL capture the durable project decisions from README, deployment documentation, API documentation, sprint documentation, runtime object diagrams, Keycloak notes, verification notes, and FSD answers.

#### Scenario: Documentation source contains durable behavior
- **WHEN** existing project documentation describes durable behavior or a future requirement
- **THEN** the relevant OpenSpec capability includes that behavior as a requirement, scenario, design note, or known open point

#### Scenario: Documentation conflicts with implemented code
- **WHEN** documentation and code disagree about runtime behavior
- **THEN** a future implementation change must record the conflict in its OpenSpec design and verify the actual behavior before changing code

### Requirement: Ambiguous work uses Functional Specification Discovery
The project SHALL use Functional Specification Discovery before coding when a request is ambiguous, introduces business rules, changes core workflows, or depends on unanswered product decisions.

#### Scenario: Category-code search behavior is unclear
- **WHEN** a future change asks for product search by category code without specifying route, filters, response shape, or store scope
- **THEN** the change must clarify those details through FSD or document explicit assumptions in OpenSpec before implementation

#### Scenario: Layout editor interaction is expanded
- **WHEN** a future change adds editor behaviors such as grouping, snapping, rotation, layers, or validation
- **THEN** the change must capture the interaction and data-contract requirements in OpenSpec before coding

### Requirement: OpenSpec is the durable change contract
Future repository changes SHALL use OpenSpec proposal, specs, design, tasks, verification, and archive artifacts when they modify durable product behavior, architecture, security, deployment, or public API contracts.

#### Scenario: Security behavior changes
- **WHEN** a future change protects a route, makes a route public, changes role behavior, or changes session handling
- **THEN** the change must update the relevant OpenSpec specs and pass validation before being considered done

#### Scenario: Documentation-only consolidation occurs
- **WHEN** project documentation is consolidated without runtime code changes
- **THEN** the OpenSpec change still records the proposal, design, tasks, specs, validation, and archive trail
