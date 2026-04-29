# Copy Paste Prompt For A New Chat

Use the following prompt in a new implementation chat.

```text
You are continuing work in this repository:
/Users/erikbergi/Documents/htl/Indooro

Your task is to implement the next sprint: Keycloak-based user management and access control for the Indooro Admin Platform.

You MUST use the OpenSpec OPSX workflow exactly. This is mandatory.

Do not start coding immediately.
Do not skip OpenSpec.
Do not write a plan only in chat and then code ad hoc.

You must follow this method:

1. Check whether OpenSpec is already initialized in the repo.
2. If not initialized, run:
   - openspec init
3. Enable expanded OPSX commands:
   - openspec config profile
   - openspec update
4. Use the `spec-driven` schema.
5. Create or update `openspec/config.yaml` with project-specific context.
6. Start a new OpenSpec change named:
   - /opsx:new keycloak-user-management
7. Generate planning artifacts with:
   - /opsx:ff
8. Review and refine the generated artifacts before implementation.
9. Only after artifacts are correct, implement with:
   - /opsx:apply
10. Before calling the sprint done, run:
   - /opsx:verify
11. When complete, archive with:
   - /opsx:archive

Important OpenSpec principles you must follow:
- OpenSpec uses actions, not rigid phases.
- The artifact flow is proposal -> specs -> design -> tasks -> implement.
- Artifacts may be updated during implementation if you learn new facts.
- Verification is required.
- Keep the change reviewable and small enough to reason about.

You must use these source references while planning:

1. OpenSpec workflow references:
   - /Users/erikbergi/Downloads/workflows.md
   - https://github.com/Fission-AI/OpenSpec/blob/main/docs/opsx.md
   - https://openspec.pro/workflow/

2. HTL Keycloak lecture notes repo:
   - https://github.com/htl-leonding-college/quarkus-security-lecture-notes

3. Official docs you should rely on for actual implementation details:
   - Quarkus OIDC web-app auth code flow:
     https://quarkus.io/guides/security-oidc-code-flow-authentication
   - Quarkus authorization of web endpoints:
     https://quarkus.io/guides/security-authorize-web-endpoints-reference
   - Quarkus Keycloak authorization guide:
     https://quarkus.io/guides/security-keycloak-authorization
   - Keycloak containers:
     https://www.keycloak.org/server/containers
   - Keycloak realm import/export:
     https://www.keycloak.org/server/importExport

Very important interpretation of the HTL repo:
- It contains useful concepts for Quarkus + Keycloak + roles.
- But several labs are under `outdated-and-incomplete`.
- Some examples use old Keycloak URLs with `/auth/realms/...`.
- Some examples use `jboss/keycloak:15.0.2`, which is old.
- Do NOT blindly copy old config or old container images.
- Use the HTL repo for concepts, not as a verbatim implementation template.

Project context you need to know:
- Backend: Quarkus 3, Java, PostgreSQL, Flyway, OpenSearch
- Admin frontend: static HTML/JS served by Quarkus under `META-INF/resources/admin`
- Deployment target: LeoCloud Kubernetes
- Existing admin APIs already exist and need protection
- Existing mobile/customer APIs also exist and should probably stay public for now unless there is a clear reason to protect them

Relevant existing backend routes:
- /api/admin/logs
- /api/admin/error-logs
- /api/regions
- /api/stores
- /api/beacons
- /api/stores/{storeId}/layout/*
- /api/mobile/stores
- /api/mobile/stores/by-beacon
- /api/mobile/stores/{storeId}/layout/current
- /api/products
- /api/categories
- /api/layout

Relevant existing code areas:
- backend/indooro_server/src/main/java/at/htl/resource/admin/*
- backend/indooro_server/src/main/java/at/htl/resource/mobile/MobileStoreResource.java
- backend/indooro_server/src/main/java/at/htl/admin/service/*
- backend/indooro_server/src/main/java/at/htl/admin/repository/*
- backend/indooro_server/src/main/java/at/htl/admin/entity/*
- backend/indooro_server/src/main/resources/META-INF/resources/admin/*
- backend/indooro_server/src/main/resources/db/migration/*
- backend/indooro_server/src/main/resources/application.properties
- DEPLOYMENT.md
- k8s/*

Existing business roles in the project:
- admin
- region-manager
- store-manager

Recommended architecture for this sprint unless you find a strong blocker:
- Use Quarkus OIDC Authorization Code Flow with `quarkus-oidc` and `application-type=web-app`
- Protect the Admin Platform via Quarkus login/session handling
- Use `@Authenticated` and `@RolesAllowed` on backend resources
- Use application database mapping for region/store scope, not only Keycloak attributes
- Keep mobile/customer routes public for now unless explicitly re-scoped
- Use a modern Keycloak container and realm import for dev/demo setup

Recommended domain decision for scope mapping:
Create a backend table for user access assignment with a stable Keycloak subject (`sub`) and application scope.
Suggested fields:
- id
- keycloak_subject
- username
- email
- role
- region_id nullable
- store_id nullable
- status
- created_at
- updated_at

Expected sprint outcome:
- Admin Platform requires login
- Admin APIs are protected
- Roles are enforced
- region-manager only sees assigned region
- store-manager only sees assigned store
- admin sees everything
- logged-in user info is visible in the Admin UI
- logout works
- LeoCloud deployment path is implemented or at least fully documented and tested where possible

Expected OpenSpec artifacts to produce before coding:
- proposal.md
- specs/
- design.md
- tasks.md

What the proposal must define:
- Why Keycloak is needed now
- What routes and pages are protected
- What stays public
- What roles exist
- What the sprint demo proves

What the specs must define:
- Login
- Logout
- Unauthorized behavior
- Role-based access behavior
- Region/store scope filtering
- Deployment expectations

What the design must define:
- Keycloak realm/client setup
- Quarkus OIDC strategy
- Role enforcement strategy
- DB mapping strategy for user scope
- LeoCloud deployment strategy

What the tasks must define:
- OpenSpec setup tasks
- Keycloak local setup tasks
- backend auth tasks
- backend scope tasks
- frontend admin auth tasks
- deployment tasks
- verification tasks

Important implementation caution:
Do not start with Keycloak Authorization Services / policy-enforcer unless simple role-based authorization is insufficient. The sprint should prefer maintainable Quarkus-native role annotations plus backend scope checks.

Please begin by checking whether OpenSpec is initialized, then set up the expanded OPSX workflow, then create the change `keycloak-user-management`, and then produce the planning artifacts before coding.
```

