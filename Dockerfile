ARG BUNDLE_VERSION=8.9.4
FROM camunda/connectors-bundle:${BUNDLE_VERSION}

COPY distro/*.jar /opt/app

