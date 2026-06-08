ARG BUNDLE_VERSION=8.9.5
FROM camunda/connectors-bundle:${BUNDLE_VERSION}

COPY distro/*.jar /opt/app

