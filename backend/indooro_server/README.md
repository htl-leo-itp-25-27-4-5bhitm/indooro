# indooro_server

This project uses Quarkus, the Supersonic Subatomic Java Framework.

If you want to learn more about Quarkus, please visit its website: <https://quarkus.io/>.

## Running the application in dev mode

You can run your application in dev mode that enables live coding using:

```shell script
./mvnw quarkus:dev
```

> **_NOTE:_**  Quarkus now ships with a Dev UI, which is available in dev mode only at <http://localhost:8080/q/dev/>.

## Backend Java coverage

The backend uses JaCoCo to generate report-only Java coverage for Maven test runs. From this directory, run:

```shell script
./mvnw test
```

If the wrapper is not executable on your local checkout, use `sh ./mvnw test`.

The generated reports are:

- HTML: `target/site/jacoco/index.html`
- XML: `target/site/jacoco/jacoco.xml`

The first coverage integration is intentionally non-blocking. It uses Quarkus JaCoCo support for `@QuarkusTest` tests and the JaCoCo Maven agent for regular unit tests. It does not enforce coverage thresholds and does not fail the build because a percentage is below a target. Test failures still fail the Maven run.

JaCoCo measures Java bytecode executed by the backend Maven tests. For Indooro, coverage review should focus on behavior-heavy packages such as:

- `at.htl.resource`
- `at.htl.resource.mobile`
- `at.htl.resource.admin`
- `at.htl.admin.service`
- `at.htl.service`
- repositories or utilities that contain custom query, transformation, or validation logic

The report excludes low-signal Java artifacts that would otherwise distort the first baseline:

- pure DTO/record containers under `at.htl.DTO` and `at.htl.admin.dto`
- JPA/entity classes under `at.htl.admin.entity`
- simple model classes under `at.htl.model`
- simple config classes under `at.htl.config`
- the Quarkus template `ExampleResource`

Repositories are not excluded as a package because some of them contain custom query methods that are useful to keep visible.

JaCoCo does not measure Swift, Admin JavaScript, Playwright tests, httpYac/manual API checks, Flyway SQL migrations, static resources, Docker/Kubernetes manifests, or deployed production usage. It also does not prove test quality, functional correctness, dead-code status, mutation resistance, or OpenSpec requirement coverage.

Future threshold enforcement should be handled as a separate OpenSpec change after reviewing the generated Indooro baseline. A conservative follow-up can start with low bundle/package thresholds and only later raise expectations for critical services such as recipe, upsell, product/search, and admin access boundary code.

## Packaging and running the application

The application can be packaged using:

```shell script
./mvnw package
```

It produces the `quarkus-run.jar` file in the `target/quarkus-app/` directory.
Be aware that it’s not an _über-jar_ as the dependencies are copied into the `target/quarkus-app/lib/` directory.

The application is now runnable using `java -jar target/quarkus-app/quarkus-run.jar`.

If you want to build an _über-jar_, execute the following command:

```shell script
./mvnw package -Dquarkus.package.jar.type=uber-jar
```

The application, packaged as an _über-jar_, is now runnable using `java -jar target/*-runner.jar`.

## Creating a native executable

You can create a native executable using:

```shell script
./mvnw package -Dnative
```

Or, if you don't have GraalVM installed, you can run the native executable build in a container using:

```shell script
./mvnw package -Dnative -Dquarkus.native.container-build=true
```

You can then execute your native executable with: `./target/indooro_server-1.0-SNAPSHOT-runner`

If you want to learn more about building native executables, please consult <https://quarkus.io/guides/maven-tooling>.

## Provided Code

### REST

Easily start your REST Web Services

[Related guide section...](https://quarkus.io/guides/getting-started-reactive#reactive-jax-rs-resources)
