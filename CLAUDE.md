# CLAUDE.md

BP3's custom connectors for Camunda 8. They ship as a Docker image that adds our connector jars on top of
Camunda's `camunda/connectors-bundle` image. Today there is one connector: **Instance Metadata**
(`connectors/metadata`), which returns the running process instance's metadata.

## Layout

- `connectors/metadata/`: the Instance Metadata connector (Java 21, Gradle). It works both as an outbound
  connector and as an execution listener, under the same type `com.bp3:instance-metadata:1`. See its README.
- `Dockerfile`: `FROM camunda/connectors-bundle:${BUNDLE_VERSION}` (passed in, see Versions), then copies
  `distro/*.jar` into `/opt/custom/`.
- `integration-tests/`: shell + docker-compose tests that run a built image against `camunda/camunda`.
- `run.sh`: example of running a published image locally against SaaS (secrets go in an untracked `env.sh`).
- `.github/workflows/`: CI and release (see below).
- `renovate.json`: Renovate dependency updates (see below).

## Build and test

```bash
./gradlew build
```

- This needs a **JDK 21** toolchain. Gradle won't download one, so builds fail if none is installed.
  CI runs Gradle on JDK 25 and uses the 21 toolchain.
- `build` runs unit tests, Checkstyle, and a **90% JaCoCo coverage gate** (`check` depends on it).
- `build` copies the thin connector jar into the top-level `distro/`, which the Dockerfile picks up.
- Integration tests need a built image: `integration-tests/test-runner.sh <image-tag>`. They pull
  `ghcr.io/bp3/camunda-connectors:<tag>` and use `versionCamundaServer` from the root `gradle.properties`
  for the `camunda/camunda` image.

## Conventions

- Every Java file starts with the BP3 copyright header that `config/checkstyle/copyright.header` enforces;
  copy it from an existing file. Shell scripts use the same text in `#` comments.
- Package `com.bp3.connector.camunda`. The Spring auto-configuration is registered in
  `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`.
- The jar is **thin**. Spring is `compileOnly` because the bundle provides it at runtime. Don't change
  Spring to `implementation` or ship it in the jar.

## Versions: one property drives the bundle

`versionCamundaConnectors` in the root `gradle.properties` is the `camunda/connectors-bundle` release we build
on, and it is the only place that version is set:

- **Libraries:** `connectors/metadata/build.gradle` imports `io.camunda.connector:connector-parent:${versionCamundaConnectors}`
  as a Gradle platform, so every library (Spring, Jackson, camunda-client, logback, test libraries) resolves
  to the version that bundle ships. **Declare dependencies without versions.** Don't add version properties
  or pin a library above the bundle's version.
- **Docker base image:** the Dockerfile's `ARG BUNDLE_VERSION` has no default. CI passes
  `versionCamundaConnectors` as `--build-arg`. For a local build:
  `docker build --build-arg BUNDLE_VERSION=$(grep '^versionCamundaConnectors=' gradle.properties | cut -d= -f2) .`

`versionCamundaServer` is separate. It is the `camunda/camunda` image the integration tests run against and
can be a newer patch release than the bundle.

## CI and release

- Pull requests (`branch-build.yml`) and pushes to `main` (`main-build.yml`) both call `build-image.yml`.
  It builds the jar, builds the image, pushes `ghcr.io/bp3/camunda-connectors:<branch-name>`, then runs
  the integration tests against that image.
- Test results are reported even when tests fail. A `report-tests` job publishes unit and integration test
  results (JUnit XML; `test-runner.sh` writes `integration-tests/build/test-results/`) as a "Test results"
  check and a PR comment. JaCoCo coverage goes to the run summary and a "Code coverage" PR comment, and the HTML
  report is uploaded as the `coverage-html` artifact. PRs from forks only get the summary page.
- **Releases** (`release.yaml`) run when a GitHub release is published. They don't build anything. They
  retag the current `ghcr.io/bp3/camunda-connectors:main` image as the release tag and as
  `bp3global/bp3-camunda-connectors:<tag>` and `:latest` on Docker Hub. **Always wait for the main build of
  the commit you're releasing to finish before publishing**, or `latest` will be the previous image.
- Release tags are `<bundle version>-<n>`, e.g. `8.9.20-0`; bump `n` for our own changes on the same bundle.
  The release title looks like `v8.9.20-0 - <summary>`.

## Renovate and security notices

- Renovate runs **before 6am on Mondays (Europe/London)** and opens at most 5 PRs. Check the Dependency
  Dashboard issue for what's pending.
- Renovate does **not** see vulnerabilities in the upstream Docker image. Watch Camunda's security notices
  (https://docs.camunda.io/docs/reference/notices/). When one affects Connectors, move `versionCamundaConnectors`
  to the fixed patch on the current minor line and cut a release.
