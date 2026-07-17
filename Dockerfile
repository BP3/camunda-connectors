ARG BUNDLE_VERSION=8.9.5
FROM camunda/connectors-bundle:${BUNDLE_VERSION}

# The bundle launches with `java -cp /opt/app/* PropertiesLauncher` and sets
# `-Dloader.path=/opt/custom/`. Custom connector jars MUST go in /opt/custom so
# they are loaded by the PropertiesLauncher classloader that can see the runtime
# classes inside the bundle fat jar. Placing them in /opt/app puts their SPI
# service file on the bare system classpath, where OutboundConnectorFunction is
# not visible -> NoClassDefFoundError crashes the whole bundle at startup.
COPY distro/*.jar /opt/custom/

