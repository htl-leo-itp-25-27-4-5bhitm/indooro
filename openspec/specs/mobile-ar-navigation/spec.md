# mobile-ar-navigation Specification

## Purpose
Defines optional iOS AR route preview behavior, including ARKit route overlays, map-to-world alignment, calibration, bounded waypoints, blocked states, and fallback to standard 2D navigation.
## Requirements
### Requirement: AR navigation overlays planned route previews
The iOS app SHALL support an AR route preview mode that visualizes the current navigation route in AR when route, user position, and AR tracking state are sufficient.

#### Scenario: AR route display is ready
- **GIVEN** an active navigation route exists and AR tracking is usable
- **WHEN** the customer opens AR navigation
- **THEN** the app can display route markers or waypoints aligned with the map route

#### Scenario: No route exists
- **GIVEN** no active navigation route exists
- **WHEN** the customer opens AR navigation
- **THEN** the app shows a blocked state instead of rendering unrelated markers

### Requirement: AR alignment maps store coordinates to world coordinates
The AR navigation mode SHALL maintain an alignment between 2D store map coordinates and ARKit world coordinates using calibration data, heading, scale, and floor estimate.

#### Scenario: Alignment is calibrated
- **GIVEN** ARKit tracking is normal and the app has a reliable map position or manual alignment
- **WHEN** the AR route is displayed
- **THEN** map route points are transformed into stable world positions

#### Scenario: Alignment needs recalibration
- **GIVEN** world/map alignment is missing or stale
- **WHEN** the AR route would be shown
- **THEN** the app prompts for or performs recalibration before trusting the overlay

### Requirement: AR route preview is bounded
The AR route preview SHALL limit displayed waypoints and preview distance so the overlay remains readable and does not flood the scene.

#### Scenario: Route contains many points
- **GIVEN** the calculated route contains many sampled points
- **WHEN** AR preview waypoints are generated
- **THEN** the app selects a bounded set of path indices and waypoints

#### Scenario: Decision point is near
- **GIVEN** a route preview reaches a decision point
- **WHEN** the app builds the AR preview plan
- **THEN** the plan can stop or highlight the relevant decision point

### Requirement: AR navigation remains optional
The system SHALL treat AR navigation as an iOS app enhancement and SHALL keep standard 2D map route guidance available without requiring ARKit.

#### Scenario: Device or user cannot use AR
- **GIVEN** ARKit is unavailable, blocked, or declined
- **WHEN** the customer needs navigation
- **THEN** the standard 2D map route remains the baseline navigation experience

#### Scenario: Future AR production hardening is requested
- **GIVEN** AR route preview exists in the app
- **WHEN** a future change proposes production AR guidance
- **THEN** it must define calibration UX, safety language, permissions, testing, and fallback behavior
