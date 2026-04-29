# Keycloak Sprint Concept And OpenSpec Implementation Plan

## Purpose

This document defines the sprint concept, architecture direction, implementation plan, and backlog structure for introducing Keycloak-based authentication and authorization into the Indooro project.

It is written for two purposes:
1. Align the sprint scope before implementation.
2. Give a new implementation chat enough context to execute the sprint correctly.

This sprint must follow the OpenSpec OPSX workflow exactly. The implementation chat should not jump directly into coding.

## Why This Sprint Exists

The previous sprint delivered the Admin Platform, store management, beacon management, and store layout workflows. The next sprint must move the project from an open prototype to a controlled admin system.

Current gap:
- There is no real authentication.
- There is no enforced authorization.
- Roles such as administrator, region manager, and store manager exist only as domain ideas, not as secure runtime behavior.

Sprint outcome:
- The Admin Platform is protected by login.
- Access to admin functions is role-based.
- Region and store scope are enforced in the backend.
- A full customer-facing demo path is closer to feature freeze.

## OpenSpec Method Is Mandatory

The implementation chat must use OpenSpec OPSX, not ad hoc planning.

### Required OpenSpec ideas

From the OpenSpec workflow docs:
- Work is based on actions, not rigid phases.
- The normal artifact flow is `proposal -> specs -> design -> tasks -> implement`.
- Expanded workflow commands are available after enabling the expanded profile.
- Artifacts can be updated during implementation if new information is discovered.
- Verification and archive are part of the workflow, not optional polish.

### Required command style

The implementation chat should use the expanded workflow, not only the quick path.

Expected sequence:

```text
openspec init
openspec config profile
openspec update
```

Then:

```text
/opsx:new keycloak-user-management
/opsx:ff
/opsx:apply
/opsx:verify
/opsx:archive
```

### Mandatory OpenSpec rules for the new chat

The new chat must:
- enable the expanded OpenSpec workflow if not already enabled
- use the `spec-driven` schema
- create or update `openspec/config.yaml`
- include project context in the OpenSpec config
- produce `proposal.md`, `specs/`, `design.md`, and `tasks.md` before implementation
- review and refine artifacts before coding
- update artifacts if implementation reveals new constraints
- run verification before considering the sprint done

The new chat must not:
- start coding before proposal/specs/design/tasks exist
- skip `verify`
- use OpenSpec only as decoration while actually coding first

## Current Indooro Project Context

### Tech stack
- Backend: Quarkus 3, Java, REST endpoints, PostgreSQL, Flyway, OpenSearch
- Admin frontend: static HTML/JS served by Quarkus under `META-INF/resources/admin`
- Customer/mobile support endpoints: REST endpoints already exist for store detection by beacon and current layout retrieval
- Deployment target: LeoCloud Kubernetes environment

### Existing backend structure

Relevant code areas:
- `backend/indooro_server/src/main/java/at/htl/resource/admin/*`
- `backend/indooro_server/src/main/java/at/htl/resource/mobile/MobileStoreResource.java`
- `backend/indooro_server/src/main/java/at/htl/admin/service/*`
- `backend/indooro_server/src/main/java/at/htl/admin/repository/*`
- `backend/indooro_server/src/main/java/at/htl/admin/entity/*`
- `backend/indooro_server/src/main/resources/META-INF/resources/admin/*`
- `backend/indooro_server/src/main/resources/db/migration/*`
- `backend/indooro_server/src/main/resources/application.properties`

### Existing database model

Already present in Flyway migrations:
- `regions`
- `stores`
- `beacons`
- `beacon_assignments`
- `layout_versions`
- `audit_logs`
- `error_logs`

This means the auth sprint should build on a real domain model, not invent a separate parallel structure.

### Existing admin API surface

Admin-facing APIs already exist and are the primary protection target:
- `/api/admin/logs`
- `/api/admin/error-logs`
- `/api/regions`
- `/api/stores`
- `/api/beacons`
- `/api/stores/{storeId}/layout/*`

Other existing routes:
- `/api/mobile/stores`
- `/api/mobile/stores/by-beacon`
- `/api/mobile/stores/{storeId}/layout/current`
- `/api/products`
- `/api/categories`
- `/api/layout`
- `/api/convert`
- `/api/export`

### Existing role ideas from prior sprint planning

The project already works with these business roles:
- `admin`
- `region-manager`
- `store-manager`

These roles should now become runtime-enforced roles.

## Source Analysis

## OpenSpec / OPSX

Useful source material:
- `/Users/erikbergi/Downloads/workflows.md`
- OpenSpec OPSX docs: <https://github.com/Fission-AI/OpenSpec/blob/main/docs/opsx.md>
- OpenSpec workflow guide: <https://openspec.pro/workflow/>

Important takeaways:
- Use the expanded workflow for explicit artifact creation.
- Use `openspec/config.yaml` to inject project context and artifact rules.
- Keep the change small and reviewable.
- Use `verify` before archive.

## HTL Keycloak lecture notes repo

Source repo:
- <https://github.com/htl-leonding-college/quarkus-security-lecture-notes>

What is useful for Indooro:
- basic Quarkus OIDC configuration patterns
- `@Authenticated` and `@RolesAllowed` usage
- realm, client, role, and user setup concepts
- separating user and admin resources by role

What is not safe to copy blindly:
- many labs are explicitly under `outdated-and-incomplete`
- some examples use old Keycloak URLs with `/auth/realms/...`
- examples use old container images such as `jboss/keycloak:15.0.2`
- examples for Keycloak Authorization Services / policy enforcer are more complex than needed for the sprint MVP

Recommended interpretation:
- use the HTL repo for concepts and old classroom examples
- use current Quarkus and Keycloak documentation for actual implementation details

## Current Quarkus docs

Useful official references:
- Quarkus OIDC web app auth code flow: <https://quarkus.io/guides/security-oidc-code-flow-authentication>
- Quarkus web endpoint authorization: <https://quarkus.io/guides/security-authorize-web-endpoints-reference>
- Quarkus Keycloak authorization guide: <https://quarkus.io/guides/security-keycloak-authorization>

Important takeaways:
- for web app login flows, `quarkus-oidc` with `application-type=web-app` is the right base
- Quarkus recommends annotation-based authorization for JAX-RS endpoints
- `@Authenticated` and `@RolesAllowed` should be the main enforcement mechanism
- Keycloak Authorization Services / policy-enforcer should only be used if a clear need exists

## Current Keycloak docs

Useful official references:
- Keycloak container docs: <https://www.keycloak.org/server/containers>
- Keycloak import/export docs: <https://www.keycloak.org/server/importExport>

Important takeaways:
- modern Keycloak supports realm import via `/opt/keycloak/data/import` and `start-dev --import-realm`
- modern setup should not rely on the legacy `jboss/keycloak` image from the lecture notes

## Architecture Decision For This Sprint

### Recommended auth model

Use Quarkus OIDC Authorization Code Flow for the Admin Platform.

Why this is the best fit:
- The Admin UI is already served by Quarkus.
- The Admin UI and Admin API are same-origin.
- Quarkus can handle login redirect, session, token exchange, and protected routes centrally.
- This avoids implementing a separate SPA token dance in plain JavaScript during a feature-freeze sprint.

### Recommended Keycloak setup

Use one realm for the project:
- `indooro`

Use one main client for this sprint:
- `indooro-admin-web`

Client type recommendation:
- confidential OIDC client for Quarkus web-app flow

Potential future clients, not required now:
- `indooro-ios`
- `indooro-customer-web`

### Recommended authorization model

Use a combination of:
- Keycloak roles for coarse-grained authorization
- application database mapping for region/store scope

Why not rely only on Keycloak attributes:
- business scope is part of the domain model
- region/store assignments are easier to manage in the Indooro backend database
- database mapping is easier to evolve later into a real user administration screen

### Recommended scope mapping model

Add a new application table such as:
- `user_access_assignments`

Suggested fields:
- `id`
- `keycloak_subject` (stable `sub` claim from token)
- `username`
- `email`
- `role`
- `region_id` nullable
- `store_id` nullable
- `status`
- `created_at`
- `updated_at`

Business rules:
- `admin`: no region/store restriction
- `region-manager`: exactly one region, no store required
- `store-manager`: exactly one store, region optional if derivable from store

## Scope Boundaries For This Sprint

### In scope
- Keycloak setup for development
- Keycloak setup for LeoCloud deployment path
- Quarkus OIDC integration
- login + logout for admin platform
- protecting admin pages and admin APIs
- role-based authorization
- backend user scope filtering by region/store
- showing logged-in user info in admin UI
- role-based UI restrictions
- basic demo users and demo realm config
- documentation for setup and usage

### Out of scope by default
- polished login screen design
- full self-service registration portal
- password reset UX polish
- complete user management UI inside the Admin Platform
- customer app redesign
- product maintenance UI completion
- stitch-based redesign work

### Assumption for planning

For this sprint, user creation may be admin-driven via Keycloak Admin Console or realm import.

If teachers explicitly require public self-registration, it should be treated as a separate scoped story. Do not assume it is free.

## Security Boundary Proposal

### Must be protected now
- `/admin/*`
- `/api/admin/*`
- `/api/regions/*`
- `/api/stores/*`
- `/api/beacons/*`
- `/api/stores/{storeId}/layout/*`

### Stay public for now unless later changed
- `/api/mobile/stores`
- `/api/mobile/stores/by-beacon`
- `/api/mobile/stores/{storeId}/layout/current`
- `/api/products/*`
- `/api/categories/*`
- `/api/export/*`
- `/api/convert/*`

Reason:
- these are currently part of customer/mobile flows or existing project utilities
- protecting them now would likely break the current customer demo without replacement flows

## Concrete Implementation Plan

## Phase 0 - OpenSpec setup

Goal:
- establish the sprint as an OpenSpec change before coding

Tasks:
1. Check whether OpenSpec is already initialized in the repo.
2. If missing, run `openspec init`.
3. Enable expanded OPSX commands with `openspec config profile` and `openspec update`.
4. Create `openspec/config.yaml` with Indooro-specific context.
5. Use `spec-driven` schema.

Expected artifact:
- ready OpenSpec environment for this sprint

## Phase 1 - Define the change in OpenSpec

Goal:
- create reviewable sprint artifacts before coding

Tasks:
1. `/opsx:new keycloak-user-management`
2. create `proposal.md`
3. use `/opsx:ff` to generate all planning artifacts
4. review and refine:
   - proposal
   - specs
   - design
   - tasks

Proposal should capture:
- why the project needs authentication now
- what is in scope
- what stays public
- what roles exist
- what success looks like for the sprint demo

Specs should capture:
- login requirements
- logout requirements
- access control requirements
- region manager restrictions
- store manager restrictions
- unauthorized behavior
- deployment and setup expectations

Design should capture:
- Quarkus OIDC strategy
- Keycloak realm/client structure
- DB scope mapping
- route protection matrix
- LeoCloud deployment design

Tasks should be concrete and ordered.

## Phase 2 - Local development infrastructure

Goal:
- get Keycloak working locally with repeatable setup

Tasks:
1. Add a local Keycloak container setup.
2. Use a modern Keycloak image, not `jboss/keycloak:15.0.2`.
3. Add realm import support.
4. Add a checked-in realm export JSON for local development.
5. Add demo users and roles.
6. Document local startup.

Recommended deliverables:
- local container config
- realm JSON import file
- setup doc

## Phase 3 - Backend authentication baseline

Goal:
- make Quarkus trust Keycloak and protect admin entry points

Tasks:
1. Add Quarkus OIDC dependencies/configuration.
2. Configure `application-type=web-app` for admin login.
3. Protect `/admin/*`.
4. Add a backend endpoint such as `/api/me` for current user info.
5. Add logout route if needed.
6. Add role annotations to admin endpoints.
7. Decide whether to deny unannotated admin endpoints globally.

Expected result:
- unauthenticated admin requests redirect to login or fail cleanly
- authenticated requests establish a session

## Phase 4 - Domain authorization and scope filtering

Goal:
- enforce real business restrictions, not only coarse roles

Tasks:
1. Add DB model for user access assignment.
2. Add repository/service for resolving current app user context from Keycloak subject.
3. Implement scope resolution service.
4. Filter store lists by role and scope.
5. Filter store detail access by role and scope.
6. Filter layout routes by role and scope.
7. Restrict beacon operations by role and scope.

Expected result:
- admin sees all
- region manager sees only assigned region
- store manager sees only assigned store

## Phase 5 - Admin frontend integration

Goal:
- make the current Admin Platform usable in the new auth model

Tasks:
1. Detect logged-in user.
2. Add logout button.
3. Show username and role in the admin UI.
4. Hide or disable unauthorized actions.
5. Handle expired session gracefully.
6. Keep same-origin API fetches working with the Quarkus session model.

Expected result:
- the admin page feels like one authenticated application, not separate systems glued together

## Phase 6 - LeoCloud deployment path

Goal:
- make the system demoable in the target environment

Tasks:
1. Decide how Keycloak runs in LeoCloud.
2. Add Kubernetes manifests or adapt existing deployment structure.
3. Decide database strategy for Keycloak:
   - separate Keycloak DB in same PostgreSQL instance, or
   - separate PostgreSQL deployment
4. Configure ingress/route strategy.
5. Configure redirect URIs and external base URLs.
6. Test login and logout in LeoCloud.

Recommended deployment direction:
- same Kubernetes namespace as Indooro
- modern Keycloak container
- realm import at startup for development/demo environments
- explicit environment variables for base URL and secrets

## Phase 7 - Verification and demo hardening

Goal:
- finish the sprint as a feature-freeze-ready increment

Tasks:
1. Run `/opsx:verify`.
2. Test all three roles end-to-end.
3. Verify unauthorized access behavior.
4. Verify admin platform navigation.
5. Verify existing customer/mobile flows still work.
6. Update deployment and usage docs.

Expected demo scenarios:
1. Admin logs in and sees everything.
2. Region manager logs in and only sees assigned region.
3. Store manager logs in and only sees assigned store/layout.
4. Anonymous user cannot access admin platform.
5. Existing customer/mobile route still works.

## GitHub Scrum Board Backlog

## Epic A - OpenSpec Sprint Scaffolding
- Initialize OpenSpec in Indooro repo
- Enable expanded OPSX workflow commands
- Create OpenSpec project config for Indooro
- Create OpenSpec change `keycloak-user-management`
- Generate proposal, specs, design, and tasks artifacts
- Review and approve OpenSpec planning artifacts before coding

## Epic B - Keycloak Foundation
- Add modern local Keycloak container setup for development
- Create `indooro` realm export JSON for demo environment
- Create Keycloak roles `admin`, `region-manager`, `store-manager`
- Create demo users for all roles
- Document local Keycloak startup and realm import process

## Epic C - Backend Authentication
- Integrate Quarkus backend with OIDC web-app authentication
- Protect `/admin/*` routes with login
- Add backend current-user endpoint
- Add logout handling for admin session
- Protect admin API routes with role-based annotations

## Epic D - Backend Authorization And Scope
- Design and add user access assignment database model
- Implement current user access context service
- Restrict region access for region managers
- Restrict store access for store managers
- Restrict layout endpoints by scope
- Restrict beacon management by scope

## Epic E - Admin Frontend Integration
- Add logged-in user display to admin UI
- Add logout button to admin UI
- Handle unauthenticated admin page access cleanly
- Hide or disable unauthorized UI actions by role
- Handle expired sessions in admin frontend

## Epic F - Deployment And Demo
- Add Keycloak deployment plan for LeoCloud
- Configure Keycloak external URLs and redirect URIs
- Test auth flow in LeoCloud
- Prepare demo accounts and demo script
- Verify customer-facing routes still behave correctly
- Update deployment and sprint documentation

## Suggested Role Matrix

| Capability | admin | region-manager | store-manager |
|---|---|---|---|
| View regions | yes | own region only | no |
| Create/update/archive regions | yes | no | no |
| View stores | yes | only assigned region | only assigned store |
| Create/update/archive stores | yes | assigned region only | no |
| View beacons | yes | optional read-only or none | no |
| Create/update/archive beacons | yes | no | no |
| Assign/release beacons | yes | no | no |
| View store layouts | yes | assigned region only | own store only |
| Save/activate layouts | yes | assigned region only | own store only |
| View audit logs | yes | no | no |
| View error logs | yes | no | no |

If teachers want different permissions, this matrix should be updated inside the OpenSpec artifacts before implementation.

## Key Risks And Warnings

1. The HTL repo is useful, but several examples are old and incomplete.
2. Do not copy old `/auth/realms/...` URLs without checking the actual Keycloak version.
3. Do not begin with Keycloak Authorization Services unless simple `@RolesAllowed` proves insufficient.
4. Do not mix customer/mobile route lockdown into the same change unless explicitly planned.
5. Do not attempt polished self-registration early if feature freeze is the real sprint target.

## Definition Of Done

This sprint is done when:
- OpenSpec artifacts exist and are consistent with the implementation
- Admin Platform requires login
- Roles are enforced in backend
- region/store scope is enforced in backend
- admin UI reflects auth state and role limitations
- Keycloak dev setup is reproducible
- LeoCloud deployment path is documented and at least one environment is working
- `/opsx:verify` has been completed
- sprint demo scenarios are executable

## Recommended First Change Name

Use this OpenSpec change name:

```text
keycloak-user-management
```

