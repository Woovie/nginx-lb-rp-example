#!/bin/bash

CONFIG_FILE="nginx-load-balancer.conf"
MAX_ATTEMPTS=10
DELAY=2
ATTEMPT=0

while [[ ! -f $CONFIG_FILE && $ATTEMPT -lt $MAX_ATTEMPTS ]]; do
    echo "Waiting for $CONFIG_FILE to be available... Attempt $((ATTEMPT+1))/$MAX_ATTEMPTS"
    sleep $DELAY
    ATTEMPT=$((ATTEMPT + 1))
done

if [[ ! -f $CONFIG_FILE ]]; then
    echo "Error: $CONFIG_FILE not found after waiting. Exiting."
    exit 1
fi

cp -v nginx-load-balancer.conf nginx.conf
docker build -t nginx-load-balancer -f Dockerfile-load-balancer .

cp -v nginx-reverse-proxy.conf nginx.conf
docker build -t nginx-reverse-proxy -f Dockerfile-reverse-proxy .

rm -v nginx.conf