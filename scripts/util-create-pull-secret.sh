#!/bin/bash

USER=$1
PASSWORD="$2"
SECRET_NAME=$3
PROJECT_NAME=$4

if [ -z "$USER" ]; then
    echo "Must specify a user for registry.redhat.io"
    exit 1
fi

if [ -z "$PASSWORD" ]; then
    echo "Must specify a password for registry.redhat.io"
    exit 1
fi

if [ -z "${SECRET_NAME}" ]; then
    SECRET_NAME="redhat-registry-pull"
fi

if [ -z "${PROJECT_NAME}" ]; then
    # use the current project
    PROJECT_NAME=$(oc project -q)
fi

echo "Using user: $USER and password: $PASSWORD for secret $SECRET_NAME in project ${PROJECT_NAME}"

# Create a pull secret in the current project redhat.registry.io 
oc create secret docker-registry $SECRET_NAME \
    --docker-server=registry.redhat.io \
    --docker-username="$USER" \
    --docker-password="$PASSWORD" \
    --docker-email=mhildenb@redhat.com -n $PROJECT_NAME

oc secrets link default $SECRET_NAME


