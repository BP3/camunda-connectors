# An example of how to run the connectors

# Setup the image you want to run
IMAGE=bp3global/bp3-camunda-connectors:8.9.6-0

# Make sure that environment details are not committed to git
if [ -f ./env.sh ]; then
  . ./env.sh
fi

# Disabling most other connectors cleans up the logs
CONNOUTDIS=io.camunda:aws-bedrock:1,io.camunda:aws-comprehend:1,io.camunda:aws-dynamodb:1io.camunda:aws-eventbridge:1
CONNOUTDIS=$CONNOUTDIS,io.camunda:aws-lambda:1,io.camunda:aws-s3:1,io.camunda:aws-sagemaker:1,io.camunda:aws-sns:1
CONNOUTDIS=$CONNOUTDIS,io.camunda:aws-sqs:1,io.camunda:aws-textract:1,io.camunda:aws:1,io.camunda:azure-blobstorage:1
CONNOUTDIS=$CONNOUTDIS,io.camunda:box:1,io.camunda:connector-automationanywhere:1,io.camunda:connector-graphql:1
CONNOUTDIS=$CONNOUTDIS,io.camunda:connector-kafka:1,io.camunda:connector-microsoft-teams:1
CONNOUTDIS=$CONNOUTDIS,io.camunda:connector-rabbitmq:1,io.camunda:csv-connector,io.camunda:email:1
CONNOUTDIS=$CONNOUTDIS,io.camunda:embeddings-vector-database:1,io.camunda:google-drive:1,io.camunda:google-gcs:1
CONNOUTDIS=$CONNOUTDIS,io.camunda:google-gemini:1,io.camunda:google-sheets:1,io.camunda:http-json:1
CONNOUTDIS=$CONNOUTDIS,io.camunda:idp-classification-connector-template:1,io.camunda:idp-extraction-connector-template:1
CONNOUTDIS=$CONNOUTDIS,io.camunda:idp-structured-connector-template:1,io.camunda:idp-unstructured-connector-template:1
CONNOUTDIS=$CONNOUTDIS,io.camunda:http-json:1,io.camunda:sendMessage:1,io.camunda:sendgrid:1,io.camunda:slack:1
CONNOUTDIS=$CONNOUTDIS,io.camunda:soap:1,io.camunda:webhook:1,io.camunda.agenticai:aiagent-job-worker:1
CONNOUTDIS=$CONNOUTDIS,io.camunda.agenticai:a2aclient:0,io.camunda.agenticai:adhoctoolsschema:1
CONNOUTDIS=$CONNOUTDIS,io.camunda.agenticai:aiagent:1,io.camunda.agenticai:mcpremoteclient:1


# This is what you need for self-managed
#  -e CAMUNDA_GRPC_ADDRESS=https://$CAMUNDA_CLIENT_CLOUD_CLUSTERID.$CAMUNDA_CLIENT_CLOUD_REGION.zeebe.camunda.io:443 \
#  -e CAMUNDA_REST_ADDRESS=https://$CAMUNDA_CLIENT_CLOUD_REGION.zeebe.camunda.io:443/$CAMUNDA_CLIENT_CLOUD_CLUSTERID \
#  -e CAMUNDA_CLIENT_ID=$CAMUNDA_CLIENT_AUTH_CLIENTID \
#  -e CAMUNDA_CLIENT_SECRET=$CAMUNDA_CLIENT_AUTH_CLIENTSECRET \
#  -e CAMUNDA_AUTHORIZATION_SERVER_URL=https://login.cloud.camunda.io/oauth/token \
#  -e CAMUNDA_TOKEN_AUDIENCE=zeebe.camunda.io \


echo "Running image: $IMAGE"
echo CONNECTOR_OUTBOUND_DISABLED=$CONNOUTDIS
docker run -it --rm --name bundle \
  -e CAMUNDA_CLIENT_MODE=$CAMUNDA_CLIENT_MODE \
  -e CAMUNDA_CLIENT_CLOUD_REGION=$CAMUNDA_CLIENT_CLOUD_REGION \
  -e CAMUNDA_CLIENT_CLOUD_CLUSTERID=$CAMUNDA_CLIENT_CLOUD_CLUSTERID \
  -e CAMUNDA_CLIENT_AUTH_CLIENTID=$CAMUNDA_CLIENT_AUTH_CLIENTID \
  -e CAMUNDA_CLIENT_AUTH_CLIENTSECRET=$CAMUNDA_CLIENT_AUTH_CLIENTSECRET \
  -e CONNECTOR_OUTBOUND_DISABLED=$CONNOUTDIS \
    $IMAGE
