#!/bin/bash

# NOTE: account that runs this script needs the run as root priviledge (scc anyuid)

# Create a new project
oc new-project debezium-cdc
oc new-app --name=mysql debezium/example-mysql:1.1 \
                        -e MYSQL_ROOT_PASSWORD=password \
                        -e MYSQL_USER=testUser \
                        -e MYSQL_PASSWORD=password \
                        -e MYSQL_DATABASE=sampledb

echo "waiting for mysql database to be deployed..."

# wait until all pods are completed by checking that the dc is now available
oc wait --for=condition=Available dc/mysql --timeout 1m

echo "waiting 5 seconds"

sleep 5

# find the first mysql pod and execute this command
MYSQL_POD=$(oc get pods -l deploymentconfig=mysql --no-headers=true -o jsonpath='{.items[0].metadata.name}' -n debezium-cdc)

echo "MYSQL Pod is: $MYSQL_POD"

oc exec -n debezium-cdc -i "${MYSQL_POD}" -- bash -c 'mysql -u root -ppassword -h mysql sampledb -e "CREATE TABLE transaction (transaction_id serial PRIMARY KEY,userId integer NOT NULL, amount integer NOT NULL,last_login TIMESTAMP);"'

oc exec  -n debezium-cdc -i "${MYSQL_POD}" -- bash -c 'mysql -A -u root -ppassword -h mysql sampledb -e "select count(*) from transaction;"'

echo "done"
