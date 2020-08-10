#!/bin/sh

# Exit on any error
set -e

linode-cli nodebalancers config-update \
    --ssl_cert /data/cert.pem \
    --ssl_key /data/key.pem \
    $NODEBALANCER_ID $CONFIG_ID \
    --no-defaults

echo "ok" > $OK_FILE
