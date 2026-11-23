ARG BUNDLE_VERSION=8.10.6
FROM camunda/connectors-bundle:${BUNDLE_VERSION}

COPY distro/*.jar /opt/custom/

