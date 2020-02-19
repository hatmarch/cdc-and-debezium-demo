#!/bin/bash

SCRIPT_DIR=$(dirname $0)
DEMO_HOME=$SCRIPT_DIR/..

# subscribe to AMQ Streams operator
oc apply -f $DEMO_HOME/kube/setup/redhat-operators-csc.yaml
oc apply -f $DEMO_HOME/kube/setup/subscription.yaml 

# FIXME: Wait for operator to be copied to the debezium-cdc project

# create a cluster in Debezium-cdc project
oc apply -f $DEMO_HOME/kube/kafka/kafka.yaml
oc apply -f $DEMO_HOME/kube/kafka/kafka-topic.yaml

# wait until the cluster is deployed
# FIXME: my-cluster is assumed to be the name of the cluster for the demo
oc wait --for=condition=Ready kafka/my-cluster

# create an connect S2I cluster
oc apply -f $DEMO_HOME/kube/kafka/kafkaconnects2i-my-connect-cluster.yaml

# build the connector
oc start-build my-connect-cluster-connect --from-dir=$DEMO_HOME/kube/kafka/connect-plugins --follow
