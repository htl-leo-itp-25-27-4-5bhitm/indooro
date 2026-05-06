## ADDED Requirements

### Requirement: Local development stack is reproducible
The project SHALL provide a reproducible local development path for Quarkus, PostgreSQL, OpenSearch, OpenSearch Dashboards, and Keycloak.

#### Scenario: Developer starts local services
- **WHEN** a developer follows the documented local setup
- **THEN** the required backing services are available with the configured hostnames, ports, indexes, realm, and credentials needed by the backend

#### Scenario: Developer runs Quarkus locally
- **WHEN** the backend runs locally without deployment overrides
- **THEN** it uses local defaults for datasource, OpenSearch, and OIDC where documented

### Requirement: LeoCloud deployment target is explicit
The project SHALL document LeoCloud as the current deployment target with namespace `student-it220209` and public host `it220209.cloud.htl-leonding.ac.at`.

#### Scenario: Operator deploys to LeoCloud
- **WHEN** an operator applies Kubernetes manifests for Indooro
- **THEN** they use the documented namespace and host unless a future deployment change updates them

#### Scenario: Public URL is tested
- **WHEN** a deployed route is verified
- **THEN** the verification uses the public host `https://it220209.cloud.htl-leonding.ac.at` where applicable

### Requirement: Kubernetes manifests define runtime components
The deployment SHALL define Kubernetes resources for PostgreSQL, OpenSearch, OpenSearch Dashboards, Keycloak, and the Indooro backend where those services are part of the LeoCloud runtime.

#### Scenario: Cluster resources are inspected
- **WHEN** an operator checks the Indooro namespace
- **THEN** the expected deployments, services, routes/ingress resources, config maps, and secrets can be traced back to files under `k8s/`

#### Scenario: Component fails readiness
- **WHEN** a runtime component fails readiness or startup checks
- **THEN** the operator can inspect the corresponding Kubernetes deployment, pod logs, and service configuration

### Requirement: Backend image rollout is traceable
The project SHALL deploy backend changes through a traceable container image and Kubernetes rollout process.

#### Scenario: Backend image is updated
- **WHEN** a backend runtime change is built and pushed
- **THEN** the image tag or digest and the rollout command are documented or visible in the deployment workflow

#### Scenario: Rollout is restarted
- **WHEN** the backend deployment is restarted after a new image push
- **THEN** the operator can verify the new pod is running and serving expected endpoints

### Requirement: Secrets and environment overrides are externalized
The deployment SHALL externalize database, OpenSearch, Keycloak, OIDC client, and other sensitive runtime settings through Kubernetes secrets, config maps, or environment variables rather than hardcoding production secrets in source code.

#### Scenario: Backend starts in LeoCloud
- **WHEN** the backend pod starts in LeoCloud
- **THEN** it receives datasource, OpenSearch, and OIDC settings from deployment configuration

#### Scenario: Secret changes
- **WHEN** a secret such as the OIDC client secret changes
- **THEN** the backend can be redeployed or restarted with the new secret without changing Java source code

### Requirement: Deployment verification covers public and protected behavior
Every deployment-affecting change SHALL verify representative public routes, protected admin routes, authentication behavior, and key backing-service connectivity.

#### Scenario: Public mobile route is tested
- **WHEN** deployment verification runs
- **THEN** at least one public mobile route is checked without Admin Platform login

#### Scenario: Protected admin route is tested
- **WHEN** deployment verification runs
- **THEN** at least one protected admin route or page is checked for login/authorization behavior

### Requirement: Operational commands are concrete
Deployment documentation SHALL provide concrete commands or command patterns for applying manifests, restarting deployments, checking rollout status, reading logs, and testing URLs.

#### Scenario: Operator follows docs
- **WHEN** an operator follows the deployment documentation
- **THEN** they can run the commands without needing to infer namespace, deployment names, or public host from unrelated files

#### Scenario: Verification fails
- **WHEN** a verification command fails
- **THEN** the documented operational workflow gives the operator enough context to inspect pods, logs, and service configuration

### Requirement: Runtime documentation separates local and cloud behavior
The project SHALL clearly distinguish local development URLs and credentials from LeoCloud URLs, Kubernetes secrets, and production-like deployment settings.

#### Scenario: Local Keycloak URL is used
- **WHEN** a developer runs the backend locally
- **THEN** local OIDC configuration points to the local Keycloak realm, not the LeoCloud public realm

#### Scenario: LeoCloud Keycloak URL is used
- **WHEN** the backend runs in LeoCloud
- **THEN** OIDC configuration points to the LeoCloud Keycloak realm under the public host and `/keycloak` path
