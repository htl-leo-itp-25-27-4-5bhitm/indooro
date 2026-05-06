## ADDED Requirements

### Requirement: Hosted web surfaces are explicit
The LeoCloud deployment SHALL serve the landing page, Admin Platform, layout editor, server-log page, and customer web page through the backend public host.

#### Scenario: Public host is used
- **GIVEN** the LeoCloud ingress routes to the backend
- **WHEN** a user opens the documented hosted paths
- **THEN** `/`, `/admin/`, `/admin/editor/`, `/admin/server-logs/`, and `/customer/` resolve according to their auth boundaries

#### Scenario: Admin page is requested
- **GIVEN** Keycloak auth is active
- **WHEN** an anonymous user opens an admin hosted path
- **THEN** the request follows the Admin Platform login boundary

### Requirement: Mobile app API base URL is environment-specific
The iOS app SHALL use the LeoCloud API base URL for deployed/demo backend access and local `localhost` API base URLs only for local development.

#### Scenario: App targets LeoCloud
- **GIVEN** the app is configured for the deployed backend
- **WHEN** it calls Indooro APIs
- **THEN** its base URL points to `https://it220209.cloud.htl-leonding.ac.at/api`

#### Scenario: App targets local development
- **GIVEN** a developer runs the backend locally
- **WHEN** the app is configured for local testing
- **THEN** it uses the local backend URL intentionally rather than accidentally shipping it as the demo target

### Requirement: Java 24 build flag is documented
The project SHALL document the Byte Buddy experimental flag required for this Quarkus version when local Java 24 builds/tests need it.

#### Scenario: Developer builds with Java 24
- **GIVEN** a developer uses Java 24 with the current Quarkus stack
- **WHEN** they run Maven package or tests
- **THEN** the build path includes `-Dnet.bytebuddy.experimental=true` through `.mvn/jvm.config` or explicit command flags

#### Scenario: CI/runtime Java changes
- **GIVEN** a future change updates Java or Quarkus versions
- **WHEN** the flag is no longer needed or changes behavior
- **THEN** the change updates deployment/build documentation and OpenSpec context

### Requirement: Product data import is part of deployment verification
Deployment verification SHALL distinguish backend health from catalog readiness by checking whether product data has been imported when product search is part of the demo.

#### Scenario: Backend is healthy but catalog is empty
- **GIVEN** the backend health check succeeds
- **WHEN** no product bulk import has populated OpenSearch
- **THEN** the deployment is not considered catalog-demo-ready

#### Scenario: Demo catalog is imported
- **GIVEN** a demo product JSON file is available
- **WHEN** the operator posts it to `/api/products/bulk`
- **THEN** product list/search verification can confirm usable catalog data

### Requirement: Deployment leftovers are tracked as open points
The project SHALL keep known deployment inconsistencies visible until fixed, including old image names, obsolete volume manifests, and `latest` image rollout behavior.

#### Scenario: Backend image is rebuilt with `latest`
- **GIVEN** the backend image is pushed using the `latest` tag
- **WHEN** the cluster does not pull a new pod automatically
- **THEN** the operator uses a documented rollout restart or future digest/tag strategy

#### Scenario: Old manifest is reviewed
- **GIVEN** a manifest such as an obsolete volume claim appears unused
- **WHEN** a cleanup change is proposed
- **THEN** it verifies current cluster/resource usage before removal
