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

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class InstanceMetadataApplicationTest {
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
        when(processInstanceFuture.join()).thenReturn(new ProcessInstanceImpl(new ProcessInstanceResult()));
        when(camundaClient.newSetVariablesCommand(anyLong())).thenReturn(setVariablesCommand);
        when(setVariablesCommand.variable(any(), any())).thenReturn(setVariablesCommand);
        when(setVariablesCommand.send()).thenReturn(setVariablesFuture);
        when(setVariablesFuture.join()).thenReturn(setVariablesResponse);
    }

    @Test
    public void testAsConnector() throws Exception {
        when(context.getJobContext())
            .thenReturn(
                new TestJobContext(() -> Map.of("elementTemplateId", "io.camunda.example.template.v1"), () -> null)
            );
        Response response = connector.execute(context);
        assertNotNull(response);
        verify(camundaClient, never()).newSetVariablesCommand(anyLong());
    }

    @Test
    public void testAsJobWorker() throws Exception {
        when(context.getJobContext())
            .thenReturn(
                new TestJobContext(Map::of, () -> null)
            );
        Response response = connector.execute(context);
        assertNotNull(response);
        verify(camundaClient).newSetVariablesCommand(anyLong());
    }

    @Test
    public void testFetchFailureIsEnrichedWithProcessInstanceKey() {
        when(context.getJobContext())
            .thenReturn(
                new TestJobContext(() -> Map.of("elementTemplateId", "io.camunda.example.template.v1"), () -> null)
            );
        when(processInstanceFuture.join()).thenThrow(new RuntimeException("Zeebe unavailable"));

        RuntimeException exception = assertThrows(RuntimeException.class, () -> connector.execute(context));
        assertTrue(exception.getMessage().startsWith("Failed to fetch metadata for process instance "));
        assertNotNull(exception.getCause());
    }

    @Test
    public void testSetVariablesFailureIsEnrichedWithProcessInstanceKey() {
        when(context.getJobContext())
            .thenReturn(
                new TestJobContext(Map::of, () -> null)
            );
        when(setVariablesFuture.join()).thenThrow(new RuntimeException("Zeebe unavailable"));

        RuntimeException exception = assertThrows(RuntimeException.class, () -> connector.execute(context));
        assertTrue(exception.getMessage().startsWith("Failed to set metadata variable for process instance "));
        assertNotNull(exception.getCause());
    }
}
