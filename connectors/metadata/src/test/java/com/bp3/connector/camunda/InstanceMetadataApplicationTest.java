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
import io.camunda.client.api.CamundaFuture;
import io.camunda.client.api.fetch.ProcessInstanceGetRequest;
import io.camunda.client.api.response.SetVariablesResponse;
import io.camunda.client.api.search.response.ProcessInstance;
import io.camunda.client.impl.command.SetVariablesCommandImpl;
import io.camunda.client.impl.search.response.ProcessInstanceImpl;
import io.camunda.client.protocol.rest.ProcessInstanceResult;
import io.camunda.connector.api.outbound.OutboundConnectorContext;
import io.camunda.connector.runtime.test.outbound.TestJobContext;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class InstanceMetadataApplicationTest {
    // Known metadata the mocked Camunda client returns, so tests can assert the
    // Response is populated from it rather than merely non-null.
    private static final long PROCESS_INSTANCE_KEY = 12345L;
    private static final String PROCESS_DEFINITION_ID = "Process_BP3TestProcess";
    private static final String PROCESS_DEFINITION_NAME = "BP3 Test Process";
    private static final int PROCESS_DEFINITION_VERSION = 3;
    private static final String PROCESS_DEFINITION_VERSION_TAG = "2026-01";
    private static final long PROCESS_DEFINITION_KEY = 67890L;
    private static final long PARENT_PROCESS_INSTANCE_KEY = 11111L;
    private static final long PARENT_ELEMENT_INSTANCE_KEY = 22222L;
    private static final String TENANT_ID = "bp3-tenant";
    private static final Set<String> TAGS = Set.of("priority", "eu-region");

    @Mock
    private OutboundConnectorContext context;
    @Mock
    private ProcessInstanceGetRequest processInstanceGetRequest;
    @Mock
    private CamundaFuture<ProcessInstance> processInstanceFuture;
    @Mock
    private SetVariablesCommandImpl setVariablesCommand;
    @Mock
    private CamundaFuture<SetVariablesResponse> setVariablesFuture;
    @Mock
    private SetVariablesResponse setVariablesResponse;

    private CamundaClient camundaClient;
    private InstanceMetadataApplication connector;

    @BeforeEach
    void setUp() {
        camundaClient = Mockito.mock(CamundaClient.class);
        connector = new InstanceMetadataApplication() {
            @Override
            protected CamundaClient createCamundaClient() {
                return camundaClient;
            }
        };
        when(camundaClient.newProcessInstanceGetRequest(anyLong())).thenReturn(processInstanceGetRequest);
        when(processInstanceGetRequest.send()).thenReturn(processInstanceFuture);
        when(processInstanceFuture.join()).thenReturn(new ProcessInstanceImpl(knownProcessInstanceResult()));
        when(camundaClient.newSetVariablesCommand(anyLong())).thenReturn(setVariablesCommand);
        when(setVariablesCommand.variable(any(), any())).thenReturn(setVariablesCommand);
        when(setVariablesCommand.send()).thenReturn(setVariablesFuture);
        when(setVariablesFuture.join()).thenReturn(setVariablesResponse);
    }

    private static ProcessInstanceResult knownProcessInstanceResult() {
        ProcessInstanceResult result = new ProcessInstanceResult();
        result.setProcessInstanceKey(Long.toString(PROCESS_INSTANCE_KEY));
        result.setProcessDefinitionId(PROCESS_DEFINITION_ID);
        result.setProcessDefinitionName(PROCESS_DEFINITION_NAME);
        result.setProcessDefinitionVersion(PROCESS_DEFINITION_VERSION);
        result.setProcessDefinitionVersionTag(PROCESS_DEFINITION_VERSION_TAG);
        result.setProcessDefinitionKey(Long.toString(PROCESS_DEFINITION_KEY));
        result.setParentProcessInstanceKey(Long.toString(PARENT_PROCESS_INSTANCE_KEY));
        result.setParentElementInstanceKey(Long.toString(PARENT_ELEMENT_INSTANCE_KEY));
        result.setTenantId(TENANT_ID);
        result.setTags(TAGS);
        return result;
    }

    private static void assertMatchesKnownMetadata(final Response response) {
        assertThat(response).isNotNull();
        assertThat(response.processInstanceKey()).isEqualTo(PROCESS_INSTANCE_KEY);
        assertThat(response.processDefinitionId()).isEqualTo(PROCESS_DEFINITION_ID);
        assertThat(response.processDefinitionName()).isEqualTo(PROCESS_DEFINITION_NAME);
        assertThat(response.processDefinitionVersion()).isEqualTo(PROCESS_DEFINITION_VERSION);
        assertThat(response.processDefinitionVersionTag()).isEqualTo(PROCESS_DEFINITION_VERSION_TAG);
        assertThat(response.processDefinitionKey()).isEqualTo(PROCESS_DEFINITION_KEY);
        assertThat(response.parentProcessInstanceKey()).isEqualTo(PARENT_PROCESS_INSTANCE_KEY);
        assertThat(response.parentElementInstanceKey()).isEqualTo(PARENT_ELEMENT_INSTANCE_KEY);
        assertThat(response.tenantId()).isEqualTo(TENANT_ID);
        assertThat(response.tags()).containsExactlyInAnyOrderElementsOf(TAGS);
    }

    @Test
    public void testAsConnector() throws Exception {
        when(context.getJobContext())
            .thenReturn(
                new TestJobContext(() -> Map.of("elementTemplateId", "io.camunda.example.template.v1"), () -> null)
            );
        Response response = connector.execute(context);
        assertMatchesKnownMetadata(response);
        verify(camundaClient, never()).newSetVariablesCommand(anyLong());
    }

    @Test
    public void testAsJobWorker() throws Exception {
        when(context.getJobContext())
            .thenReturn(
                new TestJobContext(Map::of, () -> null)
            );
        Response response = connector.execute(context);
        assertMatchesKnownMetadata(response);
        verify(camundaClient).newSetVariablesCommand(anyLong());
    }
}
