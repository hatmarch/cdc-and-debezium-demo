#!/bin/bash

SCRIPT_DIR=$(dirname $0)
DEMO_HOME=$SCRIPT_DIR/..


USER=$1
PASSWORD="$2"

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

echo "Waiting for operator to be copied to the debezium-cdc project"
sleep 60

# create a cluster in Debezium-cdc project
oc apply -f $DEMO_HOME/kube/kafka/kafka.yaml
oc apply -f $DEMO_HOME/kube/kafka/kafka-topic.yaml

# Create a secret for the registry the kafkaconnects2i depends on
# redhat.registry.io 
oc create secret docker-registry connects2i \
    --docker-server=registry.redhat.io \
    --docker-username="$USER" \
    --docker-password="$PASSWORD" \
    --docker-email=mhildenb@redhat.com

# wait until the cluster is deployed
# FIXME: my-cluster is assumed to be the name of the cluster for the demo
echo "Waiting up to 6 minutes for kafka cluster to be ready"
oc wait --for=condition=Ready kafka/my-cluster --timeout=360s
echo "Kafka cluster is ready."

# create an connect S2I cluster
oc apply -f $DEMO_HOME/kube/kafka/kafkaconnects2i-my-connect-cluster.yaml
