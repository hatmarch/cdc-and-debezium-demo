#!/bin/bash

if [ -z "$1" ]; then
    PROJECT_NAME="debezium-cdc"
else
    PROJECT_NAME="$1"
fi

# Find the token secret for default account for this project
# NOTE: regexp of the JSONPATH specifications (see: https://github.com/json-path/JsonPath) are not yet available in 
# kubernetes as per here: https://github.com/kubernetes/kubernetes/issues/61406
# This would have allowed us to only use the jsonpath to return the necessary secret name.  
SECRET_NAME=$(oc get sa default -o jsonpath='{.secrets[*].name}' -n $PROJECT_NAME | tr " " "\n" | grep -i token )

# Make that default account cluster admin  
# FIXME: Instead of cluster admin, need to find another role that has access to dump 
# information into a transaction
oc adm policy add-cluster-role-to-user cluster-admin -z default -n ${PROJECT_NAME}

# create a configmap from virtserv.conf
CONFIG_MAP_NAME="es-proxy-config"
oc create configmap ${CONFIG_MAP_NAME} --from-file=${DEMO_HOME}/kube/elasticsearch-proxy/conf.d -n ${PROJECT_NAME}

# process the template
oc process -f ${DEMO_HOME}/kube/elasticsearch-proxy/elastic-search-proxy-template.yaml \
    PROJECT_NAME=${PROJECT_NAME} CONFIG_MAP_NAME=${CONFIG_MAP_NAME} SECRET_NAME=${SECRET_NAME} \
    | oc apply -f - -n ${PROJECT_NAME} 

# deployment should rollout automatically
echo "Waiting up to 5 minutes for deployment to complete"
oc wait --for=condition=available dc/elasticsearch-proxy -n $PROJECT_NAME --timeout=5m
echo "deployment complete"

# Add a service to map to the template (port 8080)
oc apply -f kube/elasticsearch-proxy/service-elasticsearch-proxy.yaml -n ${PROJECT_NAME}