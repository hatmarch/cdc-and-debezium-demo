#!/bin/bash

SCRIPT_DIR=$(dirname $0)
DEMO_HOME=$SCRIPT_DIR/..


USER=$1
PASSWORD=$2

if [ -z "$USER" ]; then
    echo "Must specify a user for registry.redhat.io"
    exit 1
fi

if [ -z "$PASSWORD" ]; then
    echo "Must specify a password for registry.redhat.io"
    exit 1
fi

echo "Using user: $USER and password: $PASSWORD"

# subscribe to AMQ Streams operator
oc apply -f $DEMO_HOME/kube/setup/redhat-operators-csc.yaml
oc apply -f $DEMO_HOME/kube/setup/subscription.yaml 

# FIXME: Wait for operator to be copied to the debezium-cdc project

# create a cluster in Debezium-cdc project
oc apply -f $DEMO_HOME/kube/kafka/kafka.yaml
oc apply -f $DEMO_HOME/kube/kafka/kafka-topic.yaml

# wait until the cluster is deployed
# FIXME: my-cluster is assumed to be the name of the cluster for the demo
echo "Waiting up to 6 minutes for kafka cluster to be ready"
oc wait --for=condition=Ready kafka/my-cluster --timeout=360
echo "Kafka cluster is ready."

# FIXME: Create a secret for the registry the kafkaconnects2i depends on
# redhat.registry.io 
oc create secret docker-registry connects2i \
    --docker-server=registry.redhat.io \
    --docker-username=$USER \
    --docker-password=$PASSWORD \
    --docker-email=mhildenb@redhat.com

# create an connect S2I cluster
oc apply -f $DEMO_HOME/kube/kafka/kafkaconnects2i-my-connect-cluster.yaml

# build config should appear immediately if it doesn't have trouble pulling the image

# build the connector
oc start-build my-connect-cluster-connect --from-dir=$DEMO_HOME/kube/kafka/connect-plugins --follow

# expose the connect API service
oc expose svc my-connect-cluster-connect-api

# Configure the connector
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
    "database.history.kafka.bootstrap.servers": "my-cluster-kafka-bootstrap.svc:9092", 
    "database.history.kafka.topic": "changes-topic",
    "decimal.handling.mode" : "double",
    "transforms": "route",
    "transforms.route.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.route.regex": "([^.]+)\\.([^.]+)\\.([^.]+)",
    "transforms.route.replacement": "$3"
}' \
    http://$(oc get route my-connect-cluster-connect-api -o jsonpath='{.spec.host}')/connectors/debezium-connector-mysql/config
