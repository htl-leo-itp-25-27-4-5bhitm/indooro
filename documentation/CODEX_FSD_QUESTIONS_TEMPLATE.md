# Functional Specification Discovery for Codex

## Purpose

This document is a structured discovery template for creating a functional specification before implementation starts.

Codex must not make assumptions. If information is missing, unclear, contradictory, or risky, Codex must ask follow-up questions before writing code.

## Instructions for Codex

Before implementing anything:

1. Read the full project context and this document.
2. Identify which requirements are confirmed and which are still unknown.
3. Ask clear follow-up questions for every missing or ambiguous requirement.
4. Do not invent business rules, roles, data fields, workflows, API behavior, UI behavior, permissions, or deployment behavior.
5. Do not start coding until the product owner or team has answered the required questions.
6. After the answers are provided, create a final functional specification in English.
7. Only after the final specification is confirmed should implementation begin.

## Project Context

Fill this section with the actual project context.

### Project Name

Question: What is the name of the project or feature?

Answer:

### Current System State

Question: What already exists in the system today?

Answer:

### Target Outcome

Question: What should be working at the end of this implementation?

Answer:

### Non-Goals

Question: What is explicitly not part of this feature or sprint?

Answer:

## Stakeholders and Roles

### User Roles

Question: Which user roles exist in this feature?

Answer:

### Role Responsibilities

Question: What is each role allowed or expected to do?

Answer:

### Permissions

Question: Which actions are restricted to specific roles?

Answer:

### Authentication

Question: Is login/authentication required now, later, or not at all?

Answer:

### Authorization

Question: Should authorization be enforced in the backend, frontend, or both?

Answer:

## Functional Requirements

### Main User Stories

Question: What are the user stories this feature must support?

Answer:

### Required Workflows

Question: What are the exact workflows users should follow?

Answer:

### Create Behavior

Question: What objects can users create, and which fields are required?

Answer:

### Read/List Behavior

Question: What lists, detail pages, filters, and searches are required?

Answer:

### Update Behavior

Question: What can be edited after creation?

Answer:

### Delete or Archive Behavior

Question: Should records be deleted permanently, archived, deactivated, or restored?

Answer:

### Validation Rules

Question: Which validation rules must be enforced?

Answer:

### Error Handling

Question: What should happen when an operation fails?

Answer:

### Audit or History

Question: Should changes be logged, versioned, or visible in a history view?

Answer:

## Data Model Questions

### Entities

Question: Which domain entities are required?

Answer:

### Entity Fields

Question: Which fields does each entity need?

Answer:

### Relationships

Question: How are the entities related to each other?

Answer:

### Required Constraints

Question: Which fields must be unique, required, indexed, or immutable?

Answer:

### Example Data

Question: What realistic example data should be used for testing and demos?

Answer:

### Existing Data Migration

Question: Is there existing data that must be migrated or preserved?

Answer:

## Backend/API Questions

### Existing Backend

Question: Is there an existing backend that should be extended?

Answer:

### API Style

Question: Should the API be REST, GraphQL, RPC, or something else?

Answer:

### Required Endpoints

Question: Which endpoints are required?

Answer:

### Request and Response Formats

Question: What should the request and response bodies look like?

Answer:

### HTTP Status Codes

Question: Which status codes should be returned for success and failure cases?

Answer:

### Backend Validation

Question: Which validation must happen on the server side?

Answer:

### External Services

Question: Does this feature need to connect to external services?

Answer:

## Frontend/UI Questions

### Existing Frontend

Question: Is there an existing frontend that should be extended?

Answer:

### Required Pages

Question: Which pages, views, or dialogs are required?

Answer:

### Navigation

Question: How should users navigate between the views?

Answer:

### Forms

Question: Which forms are required, and what fields should they contain?

Answer:

### Tables and Lists

Question: Which data should be shown in tables or lists?

Answer:

### Empty States

Question: What should the UI show when no data exists?

Answer:

### Loading States

Question: What should the UI show while data is loading?

Answer:

### Error States

Question: What should the UI show when something fails?

Answer:

### Design Requirements

Question: Are there design, branding, layout, accessibility, or responsive requirements?

Answer:

## Mobile/App Questions

### Mobile Scope

Question: Is a mobile app affected by this feature?

Answer:

### Mobile Behavior

Question: What exactly should happen in the mobile app?

Answer:

### Offline Behavior

Question: Does any part of the feature need to work offline?

Answer:

### Permissions

Question: Does the mobile app need permissions such as Bluetooth, location, camera, or notifications?

Answer:

## Deployment and Infrastructure Questions

### Target Environment

Question: Where should the feature run?

Answer:

### Deployment Method

Question: How should the feature be deployed?

Answer:

### Database

Question: Which database should be used?

Answer:

### Environment Variables

Question: Which environment variables or secrets are required?

Answer:

### URLs and Routing

Question: Which public URLs or internal routes should be used?

Answer:

### CI/CD

Question: Should deployment happen manually or automatically through CI/CD?

Answer:

## Acceptance Criteria

### Required Demo Scenarios

Question: Which scenarios must work in the sprint review or demo?

Answer:

### Minimum Success Criteria

Question: What is the smallest version that still counts as successful?

Answer:

### Full Success Criteria

Question: What does the complete finished version include?

Answer:

### Testing Requirements

Question: Which manual tests, automated tests, or integration tests are required?

Answer:

## Open Risks and Unknowns

### Technical Risks

Question: Which technical parts are unclear or risky?

Answer:

### Product Risks

Question: Which product or business rules are unclear?

Answer:

### Dependencies

Question: What does this feature depend on?

Answer:

### Decisions Needed

Question: Which decisions must be made before implementation can start?

Answer:

## Final Specification Checklist

Codex should only mark an item as complete after the team has explicitly answered it.

- [ ] Project goal is clear.
- [ ] Non-goals are clear.
- [ ] User roles are clear.
- [ ] Permissions are clear.
- [ ] Required workflows are clear.
- [ ] Data model is clear.
- [ ] API behavior is clear.
- [ ] UI behavior is clear.
- [ ] Validation rules are clear.
- [ ] Error handling is clear.
- [ ] Deployment target is clear.
- [ ] Acceptance criteria are clear.
- [ ] Open risks are documented.
- [ ] No implementation assumptions remain.

## Prompt to Use with Codex

Copy the following prompt into a new Codex chat together with the project files or repository context.

```text
You are Codex working on this project. Before writing any code, create a functional specification in English.

Important rules:
- Do not make assumptions.
- If anything is missing, unclear, contradictory, or risky, ask questions first.
- Do not implement anything until the questions are answered and the final functional specification is confirmed.
- Use the repository code as context, but do not infer business rules without confirmation.
- The final specification must include goals, non-goals, roles, workflows, data model, API requirements, UI requirements, validation rules, error handling, deployment notes, acceptance criteria, and open risks.

Start by reading the project context and then ask the necessary clarification questions.
```
