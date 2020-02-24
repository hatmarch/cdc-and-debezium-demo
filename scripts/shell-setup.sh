#!/bin/bash

CUR_DIR=`pwd`
SCRIPT_DIR=$(dirname $0)
DEMO_HOME=$SCRIPT_DIR/..
cd $DEMO_HOME
export DEMO_HOME=`pwd`
cd $CUR_DIR

# Clean up variables
SCRIPT_DIR=
CUR_DIR=
