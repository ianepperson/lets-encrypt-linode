#!/bin/sh

# Exit on any error
set -e

linode-cli nodebalancers config-update \
    --ssl_cert /root/cert.pem \
    --ssl_key /root/key.pem \
    $NODEBALANCER_ID $CONFIG_ID \
    --no-defaults

echo "ok" > $OK_FILE
