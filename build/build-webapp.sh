#!/bin/bash

cd web-app && \
    echo "Installing dependencies, this might take a few minutes..." && \
    npm install && \
    echo "Building web app..." && \
    npm run build && \
    exit 0
