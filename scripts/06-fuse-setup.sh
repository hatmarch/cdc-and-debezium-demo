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

# create a fuse online instance
oc apply -f $DEMO_HOME/kube/fuse/syndesis.yaml

# state check on Syndesis CR is based on documentation of states here: 
# https://github.com/syndesisio/syndesis/tree/master/install/operator#available-fields
while true do
    CURRENT_STATUS=$(oc get syndesis app -o jsonpath='{.status.phase}' -n debezium-cdc)
    if [ $CURRENT_STATUS eq "Installed" ]; then
        break
    fi

    if [ $CURRENT_STATUS eq "StartupFailed" ]; then
        "Failed to install FuseOnline.  Try reinstalling the Syndesis CR"
        exit 1
    fi

    if [ $CURRENT_STATUS eq "UpgradeFailed" ]; then
        "Failed to install or upgrade FuseOnline.  Try reinstalling the Syndesis CR"
        exit 1
    fi
    echo "Waiting for FuseOnline instance to install.  Current status is: $CURRENT_STATUS..."
    sleep 5
done

echo "Finished installing FuseOnline instance"

echo "Find the fuse route here:"
echo "http://$(oc get route syndesis -o jsonpath='{.spec.host}')"