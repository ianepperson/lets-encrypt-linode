#!/bin/sh

linode-cli nodebalancers config-update $NODEBALANCER_ID $CONFIG_ID --ssl_cert /root/cert.pem --ssl_key /root/key.pem && \
echo "ok" > $OK_FILE
