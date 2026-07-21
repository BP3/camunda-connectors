/*================================================================================
 =
 = Licensed Materials - Property of BP3 Global
 =
 =  Instance Metadata Connector
 =
 = Copyright © BP3 Global Inc 2026. All Rights Reserved.
 = This software is subject to copyright protection under
 = the laws of the United States, United Kingdom and other countries.
 =
 =================================================================================*/

package com.bp3.connector.camunda;

import io.camunda.client.CamundaClient;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.context.annotation.Bean;

/**
 * Registers the Instance Metadata connector as a Spring bean in the connectors
 * runtime so it can be autowired with the runtime's own {@link CamundaClient}.
 *
 * <p>The connectors-bundle's main application only component-scans
 * {@code io.camunda.*}, so this connector (in {@code com.bp3.*}) is not picked
 * up by scanning. Instead this class is registered as an auto-configuration via
 * {@code META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports},
 * which Spring Boot loads from every jar on the classpath — including this jar
 * dropped into {@code /opt/custom}. Registering the connector as a bean (rather
 * than via the {@code META-INF/services} SPI file) is what lets it receive the
 * runtime-configured client through constructor injection.
 */
@AutoConfiguration
public class InstanceMetadataConnectorAutoConfiguration {
    @Bean
    public InstanceMetadataApplication instanceMetadataConnector(final CamundaClient camundaClient) {
        return new InstanceMetadataApplication(camundaClient);
    }
}
