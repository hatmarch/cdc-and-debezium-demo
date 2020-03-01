#!/bin/bash

# This file follows the directions that are outlined here: 
# https://www.redhat.com/en/blog/custom-grafana-dashboards-red-hat-openshift-container-platform-4

oc project debezium-cdc

# Setup central monitoring
oc apply -f $DEMO_HOME/kube/grafana/cluster-monitoring-config.yaml

# wait for user workload pods to come up in new project
sleep 5
oc -n openshift-user-workload-monitoring wait --for=condition=available po/prometheus-user-workload-0 --timeout 10m

# deploy service monitor to scrape metrics into central prometheus monitoring
oc apply -f $DEMO_HOME/kube/grafana/service-monitor-debezium-connector.yaml -n debezium-cdc

