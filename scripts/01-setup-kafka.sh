#!/bin/bash

SCRIPT_DIR=$(dirname $0)
DEMO_HOME=$SCRIPT_DIR/..

$SCRIPT_DIR/util-create-pull-secret $1 $2 connects2i

# subscribe to AMQ Streams operator
oc apply -f $DEMO_HOME/kube/setup/redhat-operators-csc.yaml
oc apply -f $DEMO_HOME/kube/setup/subscription.yaml 

echo "Waiting for operator to be copied to the debezium-cdc project"
sleep 60

# create a cluster in Debezium-cdc project
oc apply -f $DEMO_HOME/kube/kafka/kafka.yaml
oc apply -f $DEMO_HOME/kube/kafka/kafka-topic.yaml

# wait until the cluster is deployed
# FIXME: my-cluster is assumed to be the name of the cluster for the demo
echo "Waiting up to 6 minutes for kafka cluster to be ready"
oc wait --for=condition=Ready kafka/my-cluster --timeout=360s
echo "Kafka cluster is ready."

# create an connect S2I cluster
oc apply -f $DEMO_HOME/kube/kafka/kafkaconnects2i-my-connect-cluster.yaml
