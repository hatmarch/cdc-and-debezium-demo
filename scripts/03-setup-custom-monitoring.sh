#!/bin/bash

# This file follows the directions that are outlined here: 
# https://www.redhat.com/en/blog/custom-grafana-dashboards-red-hat-openshift-container-platform-4

oc project debezium-cdc

# Setup central monitoring
oc apply -f $DEMO_HOME/kube/setup/cluster-monitoring-config.yaml

# NOTE: Stateful sets do not have a condition that we can oc wait on as there is no Condition: field when you run
# the oc desc statefulset prometheus-user-workload

while true; do
    NUM_REPLICAS=$(oc get statefulset prometheus-user-workload -o jsonpath='{.status.readyReplicas}' -n openshift-user-workload-monitoring 2>/dev/null)
    if [ -z $NUM_REPLICAS ]; then
        NUM_REPLICAS=0
    fi

    if [ $NUM_REPLICAS -gt 1 ]; then
        echo "Found at least one pod in ready state."
        break
    fi
 
    echo "Waiting for user workload pods to start..."
    sleep 5
done


echo $'done.\nDeploying service monitor....'
# deploy service monitor to scrape metrics into central prometheus monitoring
oc apply -f $DEMO_HOME/kube/prometheus/service-monitor-debezium-connector.yaml -n debezium-cdc
echo $'done.\n'
