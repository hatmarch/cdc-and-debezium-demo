#!/bin/bash

# NOTE: account that runs this script needs the run as root priviledge (scc anyuid)
oc adm policy add-scc-to-user anyuid $(oc whoami)

# Create a new project
oc new-project debezium-cdc

# Create a database (that is setup with necessary binlog)
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


# create a S2I build but set as binary so that we can upload our local directory instead of having to checkin
# (this is what the --binary flag does)
oc new-app --docker-image=quay.io/quarkus/ubi-quarkus-native-s2i:19.0.2 --name "quarkus-transaction-crud" --binary
oc patch bc/quarkus-transaction-crud -p '{"spec":{"resources":{"limits":{"cpu":"4", "memory":"6Gi"}}}}'
oc start-build bc/quarkus-transaction-crud --from-dir=$DEMO_HOME/demo-crud-app --follow --wait

# wait for the application to actually be deployed
oc wait --for=condition=available dc/quarkus-transaction-crud --timeout=20m

oc expose svc/quarkus-transaction-crud

export TRANS_APP=$(oc get route quarkus-transaction-crud -n debezium-cdc -o jsonpath='{.spec.host}')
echo "Transaction generating application can be found at http://${TRANS_APP}/"