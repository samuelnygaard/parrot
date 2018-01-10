#!/bin/bash

OUTPUT_DIR="$(pwd)/dist"
WEB_APP_FILENAME="web-app-static.tar.gz"
API_APP_FILENAME="parrot-api-app"

mkdir -p $OUTPUT_DIR && \
    ./build/build-webapp.sh "$OUTPUT_DIR/$WEB_APP_FILENAME" && \
    mkdir -p "$OUTPUT_DIR/static" && \
    tar -xzf "$OUTPUT_DIR/$WEB_APP_FILENAME" -C "$OUTPUT_DIR/static" --strip 1 && \
    ./build/build-api.sh "$OUTPUT_DIR/$API_APP_FILENAME"
