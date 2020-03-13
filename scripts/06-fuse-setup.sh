#!/bin/bash

PROJECT_NAME=debezium-cdc

oc project $PROJECT_NAME

# NOTE: This uses the same docker-registry secret as created in 01-setup-kafka.sh
if [ -z "$(oc get secret connects2i --no-headers=true 2> /dev/null)" ]; then
    echo "Need to create pull-secret for registry.io"
    exit 1
fi

# install Fuse operator and subscription
oc apply -f $DEMO_HOME/kube/fuse/fuse-operator-subscription.yaml

# install operator group
oc apply -f $DEMO_HOME/kube/fuse/fuse-operator-group.yaml

# link the operator to the secret above
oc secrets link syndesis-operator connects2i --for=pull

# link the builder to the secret for when it comes time to build our integrations
oc secrets link builder connects2i --for=pull

# looks like there may be a bug and the builder needs the pullsecret listsed as
# a generic secret
oc secrets link builder connects2i

# wait for syndesis operator deployment
sleep 5
oc wait --for=condition=available deployment/syndesis-operator --timeout=5m

# create a fuse online instance
oc apply -f $DEMO_HOME/kube/fuse/syndesis.yaml

# state check on Syndesis CR is based on documentation of states here: 
# https://github.com/syndesisio/syndesis/tree/master/install/operator#available-fields
while true; do
    CURRENT_STATUS=$(oc get syndesis app -o jsonpath='{.status.phase}' -n $PROJECT_NAME)
    if [ "$CURRENT_STATUS" = "Installed" ]; then
        break
    fi

    if [ "$CURRENT_STATUS" = "StartupFailed" ]; then
        "Failed to install FuseOnline.  Try reinstalling the Syndesis CR"
        exit 1
    fi

    if [ "$CURRENT_STATUS" = "UpgradeFailed" ]; then
        "Failed to install or upgrade FuseOnline.  Try reinstalling the Syndesis CR"
        exit 1
    fi
    echo "Waiting for FuseOnline instance to install.  Current status is: $CURRENT_STATUS..."
    sleep 5
done

echo "Finished installing FuseOnline instance"

echo "Find the fuse route here:"
echo "http://$(oc get route syndesis -o jsonpath='{.spec.host}' -n $PROJECT_NAME)"