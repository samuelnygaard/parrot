#!/bin/bash

GO_WORKSPACE="$GOPATH/src/github.com/anthonynsimon/parrot"

echo "Copying API sources to GOPATH workspace" && \
    rm -rf $GO_WORKSPACE && mkdir -p $GO_WORKSPACE && \
    cp -R parrot-api $GO_WORKSPACE/ && \
    cd $GO_WORKSPACE/parrot-api && \
    echo "Building Parrot API..." && \
    go get ./... && \
    go build && \
    cp parrot-api $1 && \
    exit 0
