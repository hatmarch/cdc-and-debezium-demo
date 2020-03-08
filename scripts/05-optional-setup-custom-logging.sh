
# create the namespace for redhat-operators
oc apply -f $DEMO_HOME/kube/logging/eo-namespace.yaml

# create operator group
oc apply -f $DEMO_HOME/kube/logging/eo-operator-group.yaml

# create subscription for elasticsearch operator
oc apply -f $DEMO_HOME/kube/logging/eo-subscription.yaml

oc project openshift-operators-redhat

oc apply -f $DEMO_HOME/kube/logging/eo-prometheus-rbac.yaml

# wait until the elastic search subscription is available in all namespaces before going on 
# to custom logging
NUM_PROJECTS=$(oc get projects --no-headers=true | wc -l)
while true; do
    NUM_ES_SUBS=$(oc get csv --all-namespaces --no-headers=true | grep -i elasticsearch-operator | grep Succeeded | wc -l)
    if [ $NUM_PROJECTS -eq $NUM_ES_SUBS ]; then
        echo "ElasticSearch operator propagated"
        break
    fi
    echo "$NUM_ES_SUBS of $NUM_PROJECTS deployed."
    sleep 5
done

echo "Installing Custom Logging"

# create openshift logging namespace
oc apply -f $DEMO_HOME/kube/logging/customlogging-namespace.yaml

# custom logging operator group
oc apply -f $DEMO_HOME/kube/logging/customlogging-operator-group.yaml

# create subscription
oc apply -f $DEMO_HOME/kube/logging/customlogging-subscription.yaml

# wait for subscription to engage
sleep 5

# create custom-logging CR instance
oc apply -f $DEMO_HOME/kube/logging/customlogging-instance.yaml

# wait for the cluster logging operator
sleep 5
oc wait --for=condition=Available deployment/cluster-logging-operator --timeout=5m -n openshift-logging

# once the logging operator is available, wait for it to spawn other deployments
sleep 5

# wait until all deployments in the project are ready
while true; do
    # depending upon when we query, new deployments may appear, so look for them at every iteration
    NUM_DEPLOYMENTS=$(oc get deployments --no-headers=true -n openshift-logging | wc -l)

    # wait until at least 1 deployment is ready from each deployment
    NUM_READY_DEPLOYMENTS=$(oc get deployments -o custom-columns=READY:.status.readyReplicas --no-headers=true -n openshift-logging | grep -v \<none\> | wc -l)
    if [ $NUM_DEPLOYMENTS -eq $NUM_READY_DEPLOYMENTS ]; then
        echo "All Deployments are ready"
        break
    fi
    echo "$NUM_READY_DEPLOYMENTS of $NUM_DEPLOYMENTS ready..."
    sleep 5
done

# print the kibana route
echo "Kibana route is:"
echo "https://$(oc get route kibana -o jsonpath='{.spec.host}' -n openshift-logging)/"