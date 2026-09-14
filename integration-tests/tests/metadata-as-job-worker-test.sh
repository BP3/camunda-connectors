#!/bin/sh -e

############################################################################
#
# Licensed Materials - Property of BP3
#
#  Connector Bundle
#
# Copyright © BP3 Global Inc. 2025. All Rights Reserved.
# This software is subject to copyright protection under
# the laws of the United States and other countries.
#
############################################################################

export TESTNAME=`basename $0 .sh`
export BPMN_FILE_NAME=bpmn/metadata-as-job-worker.bpmn

# Load reusable functions
. ./core-functions.sh

_setup() {
  :
}

_teardown() {
  :
}

Given() {
    echo "$TESTNAME: Given ${BPMN_FILE_NAME} is deployed..."
    response=$(curl -X POST 'http://localhost:8080/v2/deployments' -H 'Content-Type: multipart/form-data' -H 'Accept: application/json' \
	    -F "resources=@${BPMN_FILE_NAME}" 2>/dev/null)
}

When() {
    echo "$TESTNAME: When a process instance is started..."
    response=$(curl -X POST 'http://localhost:8080/v2/process-instances' -H 'Content-Type: application/json' -H 'Accept: application/json' \
	    -d '{
    		"processDefinitionId": "metadata-as-job-worker-process",
		    "processDefinitionVersion": -1,
		    "variables": {}
	    }' 2>/dev/null)
    processInstanceKey=$(echo $response | jq -r ".processInstanceKey")
    # give the process a chance to complete...
    sleep 10
}

Then() {
    echo "$TESTNAME: Then the process should be completed"
    body=$(echo  "{
      \"filter\": {
        \"processInstanceKey\": \"${processInstanceKey}\"
      }
    }")
    response=$(curl -X POST 'http://localhost:8080/v2/process-instances/search' \
	    -H 'Content-Type: application/json' \
	    -H 'Accept: application/json' \
	    -d "${body}" 2>/dev/null )
    status=$(echo $response | jq -r ".items[0].state")
    assert_string_equals ${status} COMPLETED

    echo "$TESTNAME: And the metadata process variable should be set"
    body=$(echo  "{
      \"filter\": {
        \"processInstanceKey\": \"${processInstanceKey}\",
        \"name\": \"meta\"
      }
    }")
    response=$(curl -X POST 'http://localhost:8080/v2/variables/search' \
	    -H 'Content-Type: application/json' \
	    -H 'Accept: application/json' \
	    -d "${body}" 2>/dev/null )
	  processVar=$(echo $response | jq -r ".items[0]")
    assert_not_empty processVar $processVar
    processVar_ProcessInstanceKey=$(echo $processVar | jq -r ".processInstanceKey")
    assert_string_equals $processVar_ProcessInstanceKey $processInstanceKey
}

############################################################################
# Run the test

_setup

  Given
  When
  Then

_teardown
