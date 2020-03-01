#!/bin/bash

# This file follows the directions that are outlined here: 
# https://www.redhat.com/en/blog/custom-grafana-dashboards-red-hat-openshift-container-platform-4

if [ -z "$1" ]; then
    PROJECT_NAME="debezium-monitoring"
else
    PROJECT_NAME="$1"
fi

if [ -z "$2" ]; then
    ADMIN_PASSWORD="openshift"
else
    ADMIN_PASSWORD="$2"
fi

#
# Install custom grafana with connections to openshift-metrics and a custom debezium dashboard
# Dashboard is based on the one created here: https://medium.com/searce/grafana-dashboard-for-monitoring-debezium-mysql-connector-d5c28acf905b
# but that specific one was not used because it used a parameter "job=debezium" that broke all the elements of the dashboard
#

# The current operator is v2.0.0 which installs an older version of grafana.  We need version 6.3.x or above.
# see also: https://medium.com/@zhimin.wen/grafana-dashboard-in-ocp4-2-44468e5390d0
oc new-project $PROJECT_NAME --display-name="Custom Debezium Monitoring" \
    --description "A separate Grafana installation that allows the addition of custom dashboards"

oc create -f $DEMO_HOME/kube/grafana/grafana-operator/deploy/crds
oc create -f $DEMO_HOME/kube/grafana/grafana-operator/deploy/roles -n ${PROJECT_NAME}
oc create -f $DEMO_HOME/kube/grafana/grafana-operator/deploy/cluster_roles
oc create -f $DEMO_HOME/kube/grafana/grafana-operator/deploy/operator.yaml -n ${PROJECT_NAME}

# wait for grafana operator to appear
sleep 5 

# can't seem to wait on the operator itself, maybe waiting on the deployment is good enough
oc wait --for=condition=available deployment/grafana-operator --timeout=10m

# create an instance of grafana
oc process -f $DEMO_HOME/kube/grafana/grafana-instance-template.yaml PROJECT_NAME="${PROJECT_NAME}" \
    ADMIN_PASSWORD="${ADMIN_PASSWORD}" -o yaml | oc apply -f -

# grant cluster-monitoring-view to the service account that the operator created
oc adm policy add-cluster-role-to-user cluster-monitoring-view -z grafana-serviceaccount

# Create a tenant based datasource (using kube_rbac_proxy) to query openshift-monitoring
# NOTE: This will also create the configmap to mirror the GrafanaDataSource CR
oc process -f $DEMO_HOME/kube/grafana/openshift-metrics-datasource-template.yaml \
    PROJECT_NAME="${PROJECT_NAME}" DATASOURCE_NAME=Prometheus-oauth TOKEN=$(oc serviceaccounts get-token grafana-serviceaccount) | oc apply -f -

# Install the custom dashboard for debezium using the datasource name
oc process -f $DEMO_HOME/kube/grafana/grafana-dbz-dashboard.yaml DATASOURCE_NAME=Prometheus-oauth | oc apply -f -

# wait a few minutes for the deployment to appear
sleep 3

# Wait until grafana instance is deployed
oc wait --for=condition=available deployment/grafana-deployment --timeout=10m

# Print out the route to the custom grafana reference
echo "https://$(oc get route grafana-route -o jsonpath='{.spec.host}' -n ${PROJECT_NAME})/"
