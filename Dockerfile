ARG BUNDLE_VERSION=8.9.10
FROM camunda/connectors-bundle:${BUNDLE_VERSION}

COPY distro/*.jar /opt/custom/

