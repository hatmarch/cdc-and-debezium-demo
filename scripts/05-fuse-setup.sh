#!/bin/bash

oc project debezium-cdc

# install Fuse operator and subscription
oc apply -f $DEMO_HOME/kube/fuse/fuse-operator-subscription.yaml
# oc apply -f $DEMO_HOME/fuse/fuse-csv-7.5.0.yaml

# NOTE: This uses the same docker-registry secret as created in 01-setup-kafka.sh
if [ -z $(oc get secret connects2i --no-headers=true 2>/dev/null) ]; then
    echo "Need to create pull-secret for registry.io"
    exit 1
fi

# link the operator to the secret
oc secrets link syndesis-operator connects2i --for=pull

#FIXME: Install a Syndesis custom resource and wait for its setup to complete.
# NOTE: This link implies it won't work: https://github.com/syndesisio/syndesis/issues/7808

