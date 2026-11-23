# BUNDLE_VERSION has no default on purpose: it must match versionCamundaConnectors
# in gradle.properties, which CI passes in. For a local build:
#   docker build --build-arg BUNDLE_VERSION=$(grep '^versionCamundaConnectors=' gradle.properties | cut -d= -f2) .
ARG BUNDLE_VERSION
FROM camunda/connectors-bundle:${BUNDLE_VERSION}

COPY distro/*.jar /opt/custom/
