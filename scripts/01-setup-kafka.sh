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