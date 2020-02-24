#!/bin/bash

# create a S2I build but set as binary so that we can upload our local directory instead of having to checkin
# (this is what the --binary flag does)
oc new-app --docker-image=quay.io/quarkus/ubi-quarkus-native-s2i:19.0.2 --name "quarkus-transaction-crud" --binary
oc patch bc/quarkus-transaction-crud -p '{"spec":{"resources":{"limits":{"cpu":"5", "memory":"6Gi"}}}}'
oc start-build bc/quarkus-transaction-crud --from-dir=$DEMO_HOME/demo-crud-app --follow

# wait for the application to actually be deployed
oc wait --for=condition=available dc/quarkus-transaction-crud

oc expose svc/quarkus-transaction-crud

export TRANS_APP=$(oc get route quarkus-transaction-crud -n debezium-cdc -o jsonpath='{.spec.host}')
echo "Transaction generating application can be found at http://${TRANS_APP}/"