#!/bin/bash

cd web-app && \
    echo "Installing web app dependencies, this might take a few minutes..." && \
    # npm install && \
    echo "Building web app..." && \
    # npm run build && \
    tar -zcf app.tar.gz dist && \
    mv app.tar.gz $1 && \
    exit 0
