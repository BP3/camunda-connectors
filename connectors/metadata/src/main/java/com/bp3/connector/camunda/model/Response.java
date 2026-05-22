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
package com.bp3.connector.camunda.model;

import java.util.Set;

public record Response(
        Long processInstanceKey,
        String processDefinitionId,
        String processDefinitionName,
        Integer processDefinitionVersion,
        String processDefinitionVersionTag,
        Long processDefinitionKey,
        Long parentProcessInstanceKey,
        Long parentElementInstanceKey,
        String tenantId,
        Set<String> tags
) {
}
