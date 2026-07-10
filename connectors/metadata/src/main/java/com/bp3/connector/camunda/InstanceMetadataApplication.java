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

import com.bp3.connector.camunda.model.Response;

import io.camunda.client.CamundaClient;
import io.camunda.client.api.search.response.ProcessInstance;
import io.camunda.connector.api.annotation.OutboundConnector;
import io.camunda.connector.api.outbound.JobContext;
import io.camunda.connector.api.outbound.OutboundConnectorContext;
import io.camunda.connector.api.outbound.OutboundConnectorFunction;
import io.camunda.connector.generator.java.annotation.ElementTemplate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.URI;

@OutboundConnector(name = "Instance Metadata", type = "com.bp3:instance-metadata:1")
@ElementTemplate(
    id = "com.bp3.connector.instance-metadata.v1",
    name = "Instance Metadata Connector",
    version = 1,
    description = "Retrieves metadata about the current process instance.",
    icon = "bp3-icon.png",
    documentationRef = "https://"
)
public class InstanceMetadataApplication implements OutboundConnectorFunction {
    public static final String DEFAULT_PROCESS_VARIABLE = "metadata";
    public static final String REST_URL = System.getProperty("CAMUNDA_CLIENT_RESTADDRESS", "http://zeebe:8080");
    public static final String GRPC_URL = System.getProperty("CAMUNDA_CLIENT_GRPCADDRESS", "http://zeebe:26500");

    private static final Logger LOGGER = LoggerFactory.getLogger(InstanceMetadataApplication.class);

    private final CamundaClient camundaClient;

    public InstanceMetadataApplication() {
        LOGGER.debug("CONSTRUCTING INSTANCE METADATA CONNECTOR");
        this.camundaClient = createCamundaClient();
    }

    protected CamundaClient createCamundaClient() {
        return CamundaClient
                .newClientBuilder()
                .preferRestOverGrpc(true)
                .grpcAddress(URI.create(GRPC_URL))
                .restAddress(URI.create(REST_URL))
                .applyEnvironmentVariableOverrides(true)
                .build();
    }

    @Override
    public Response execute(final OutboundConnectorContext context) throws Exception {
        LOGGER.debug("RUNNING getInstanceMetadata()");

        JobContext job = context.getJobContext();
        long processInstanceKey = job.getProcessInstanceKey();

        // get process instance metadata
        ProcessInstance processInstance;
        try {
            processInstance = this.camundaClient
                .newProcessInstanceGetRequest(processInstanceKey)
                .send()
                .join();
        } catch (Exception e) {
            throw new RuntimeException(
                "Failed to fetch metadata for process instance " + processInstanceKey, e);
        }

        // convert process instance metadata into our response object
        Response response = new Response(
            processInstance.getProcessInstanceKey(),
            processInstance.getProcessDefinitionId(),
            processInstance.getProcessDefinitionName(),
            processInstance.getProcessDefinitionVersion(),
            processInstance.getProcessDefinitionVersionTag(),
            processInstance.getProcessDefinitionKey(),
            processInstance.getParentProcessInstanceKey(),
            processInstance.getParentElementInstanceKey(),
            processInstance.getTenantId(),
            processInstance.getTags()
        );

        // if connector is being called as a job worker then we have to return the metadata using the camunda client
        if (job.getCustomHeaders().isEmpty()) {
            try {
                this.camundaClient.newSetVariablesCommand(processInstanceKey)
                    .variable(DEFAULT_PROCESS_VARIABLE, response)
                    .send()
                    .join();
            } catch (Exception e) {
                throw new RuntimeException(
                    "Failed to set metadata variable for process instance " + processInstanceKey, e);
            }
        }

        LOGGER.debug("FINISHED getInstanceMetadata()");

        return response;
    }
}
