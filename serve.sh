#!/bin/sh

# Exit on any error
set -e

# If we don't have a NODEBALANCER_ID, list the available ones and exit
if [ -z "$NODEBALANCER_ID" ];
  then
      echo "No NODEBALACER_ID set. Set it from the list below."
      linode-cli nodebalancers list
      exit 1
fi;

# If we don't have a CONFIG_ID, list the available ones and exit
if [ -z "$CONFIG_ID" ];
  then
      echo "No CONFIG_ID set. Set it from the list below."
      linode-cli nodebalancers configs-list $NODEBALANCER_ID
      exit 1
fi;

# Verify that the NODEBALANCER_ID and CONFIG_ID are valid
linode-cli nodebalancers config-view $NODEBALANCER_ID $CONFIG_ID

# Where the acme.sh command is located
export ACME=/root/.acme.sh/acme.sh

# for notifications, see https://github.com/acmesh-official/acme.sh/wiki/notify
# the --notify-hook updates the config file with the contents of the env variables

if [ -n "$MAILGUN_API_KEY" ];
  then $ACME --set-notify  --notify-hook mailgun
fi;

if [ -n "$SENDGRID_API_KEY" ];
  then $ACME --set-notify  --notify-hook sendgrid
fi;

if [ -n "$SLACK_WEBHOOK_URL" ];
  then $ACME --set-notify  --notify-hook slack
fi;

if [ -n "$IFTTT_API_KEY" ];
  then $ACME --set-notify  --notify-hook ifttt
fi;

# Start the web server in the background
nginx

# Run the cert using nginx
$ACME --issue -d $DOMAIN_NAME \
      -w /usr/share/nginx/html \
      --reloadcmd "/install_cert.sh" \
      --pre-hook "rm $OK_FILE" \
      --cert-file /root/cert.pem \
      --key-file /root/key.pem

# Tail the nginx log files to keep the container alive
tail -f /var/log/nginx/error.log -f /var/log/nginx/access.log
