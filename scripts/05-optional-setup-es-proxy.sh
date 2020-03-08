#!/bin/bash

if [ -z "$1" ]; then
    PROJECT_NAME="debezium-cdc"
else
    PROJECT_NAME="$1"
fi

# Find the token secret for default account for this project
SECRET_NAME=$(oc get sa default -o jsonpath='{.secrets[0].name}' -n ${PROJECT_NAME})

# Make that default account cluster admin  
# FIXME: Instead of cluster admin, need to find another role that has access to dump 
# information into a transaction
oc adm policy add-cluster-role-to-user cluster-admin -z default -n ${PROJECT_NAME}

# create a configmap from virtserv.conf
CONFIG_MAP_NAME="es-proxy-config"
oc create configmap ${CONFIG_MAP_NAME} --from-file=${DEMO_HOME}/kube/elasticsearch-proxy/conf.d

# process the template
oc process -f ${DEMO_HOME}/kube/elasticsearch-proxy/elastic-search-proxy-template.yaml \
    PROJECT_NAME=${PROJECT_NAME} CONFIG_MAP_NAME=${CONFIG_MAP_NAME} SECRET_NAME=${SECRET_NAME} \
    | oc apply -f - -n ${PROJECT_NAME} 

# deployment should rollout automatically
echo "Waiting up to 5 minutes for deployment to complete"
oc wait --for=condition=available dc/elasticsearch-proxy --timeout=5m
echo "deployment complete"

# Add a service to map to the template (port 8080)
oc apply -f kube/elasticsearch-proxy/service-elasticsearch-proxy.yaml -n ${PROJECT_NAME}