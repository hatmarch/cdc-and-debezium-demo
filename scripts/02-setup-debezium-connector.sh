#!/bin/bash

SCRIPT_DIR=$(dirname $0)
DEMO_HOME=$SCRIPT_DIR/..

# build the connector
oc start-build my-connect-cluster-connect --from-dir=$DEMO_HOME/kube/kafka/connect-plugins --follow

# wait until the cluster is deployed
oc wait --for=condition=available dc/my-connect-cluster-connect

# expose the connect API service
oc expose svc my-connect-cluster-connect-api

# record the route
DBZ_CONNECTOR=$(oc get route my-connect-cluster-connect-api -o jsonpath='{.spec.host}')

# check the the service is up
echo "Checking that the connector is online:"
curl -H "Accept:application/json" $DBZ_CONNECTOR/
echo "\ndone."

# Configure the connector by calling through to its API
# The values therein are coming from values set from the previous script and yaml files
curl -X PUT -H "Content-Type: application/json" \
-d '{ 
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "tasks.max": "1",
    "database.hostname": "mysql", 
    "database.port": "3306", 
    "database.user": "root", 
    "database.password": "password", 
    "database.server.id": "184054",
    "database.server.name": "sampledb", 
    "database.whitelist": "sampledb",
    "database.history.kafka.bootstrap.servers": "my-cluster-kafka-bootstrap:9092", 
    "database.history.kafka.topic": "changes-topic",
    "decimal.handling.mode" : "double",
    "transforms": "route",
    "transforms.route.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.route.regex": "([^.]+)\\.([^.]+)\\.([^.]+)",
    "transforms.route.replacement": "$3"
}' \
    http://$DBZ_CONNECTOR/connectors/debezium-connector-mysql/config

echo "Checking that the mysql connector has been initialized:"
curl -H "Accept:application/json" $DBZ_CONNECTOR/connectors
echo "\ndone."