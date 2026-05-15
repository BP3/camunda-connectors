# BP3 Camunda Instance Metadata Connector

This connector for Camunda returns the metadata of the running process instance.


## Installation
TO BE COMPLETED.

## Usage
Add an activity to your diagram and from the context menu select, "Change element". Then choose Instance Metadata Connector. 

You only need to specify a result variable or result expression. If you only supply a result variable, you will get the full response payload in that variable, for example:

```
{
  "processInstanceKey": "2251799813697933",
  "processDefinitionId": "Process_0dnf8x0",
  "processDefinitionName": "Process_0dnf8x0",
  "processDefinitionVersion": 9,
  "processDefinitionVersionTag": null,
  "processDefinitionKey": "2251799813697144",
  "parentProcessInstanceKey": null,
  "parentElementInstanceKey": null,
  "tags": [],
}
```

If you only want to return a single field, you can use the Result expression parameter: 

```
{
  myProcessInstanceId: response.processInstanceKey
}
```
Note that the connector requires that the process instance details have been sent from Zeebe to secondary storage (e.g. ElasticSearch).
If the connector is placed at the beginning of a BPMN process definition the data may not have reached secondary storage and the connector will throw an exception.
To work around this potential issue the default retry backoff for the connector is 5 seconds, which should allow enough time for the data to become available.

The connector can also be invoked as an event listener by specifying ```com.bp3:instance-metadata:1``` as the listener type.  The process instance metadata will then be injected into the process as a variable named ```metadata```.

Note that when invoking the connector from an event listener you cannot specify a retry backoff period, so this should not be done before the process instance metadata has had a chance to reach secondary storage.

## Support
TBC.

## License
TBC.
