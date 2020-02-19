#!/bin/bash

echo "Downloading plugins into $(pwd)..."

# Build a Debezium image
export DEBEZIUM_VERSION=1.0.1.Final
for PLUGIN in {mongodb,mysql,postgres}; do \
    curl https://repo1.maven.org/maven2/io/debezium/debezium-connector-$PLUGIN/$DEBEZIUM_VERSION/debezium-connector-$PLUGIN-$DEBEZIUM_VERSION-plugin.tar.gz | tar xz; \
done 
