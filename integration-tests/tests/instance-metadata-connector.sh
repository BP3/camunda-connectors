#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../functions.sh
source "${SCRIPT_DIR}/../functions.sh"

BPMN_FILE="${SCRIPT_DIR}/../../connectors/metadata/src/test/resources/bpmn/operation-connector-test-process.bpmn"
PROCESS_ID="operation-connector-test-process"

echo "--- Given: the test process is deployed ---"
deploy_response=$(curl -sf -X POST -F "resources=@${BPMN_FILE}" "${ZEEBE_REST}/v2/deployments")
echo "Deploy response: ${deploy_response}"
deployed_id=$(echo "$deploy_response" | jq -r '.deployments[0].processDefinition.processDefinitionId')
assert_equals "$deployed_id" "$PROCESS_ID" "deployed process definition id"

echo "--- When: a process instance is started and awaited to completion ---"
instance_response=$(curl -sf -X POST \
  -H "Content-Type: application/json" \
  -d "{\"processDefinitionId\":\"${PROCESS_ID}\",\"awaitCompletion\":true,\"requestTimeout\":60000,\"fetchVariables\":[\"result\"]}" \
  "${ZEEBE_REST}/v2/process-instances")
echo "Process instance response: ${instance_response}"

process_instance_key=$(echo "$instance_response" | jq -r '.processInstanceKey')
assert_not_empty "$process_instance_key" "process instance key"

echo "--- Then: the connector wrote back correct instance metadata ---"
result=$(echo "$instance_response" | jq -c '.variables.result')
assert_not_empty "$result" "'result' variable set by the connector"

result_process_definition_id=$(echo "$result" | jq -r '.processDefinitionId')
assert_equals "$result_process_definition_id" "$PROCESS_ID" "result.processDefinitionId"

result_process_instance_key=$(echo "$result" | jq -r '.processInstanceKey')
assert_equals "$result_process_instance_key" "$process_instance_key" "result.processInstanceKey matches the started instance"

echo "PASSED: instance-metadata-connector"
