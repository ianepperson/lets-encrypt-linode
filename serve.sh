#!/bin/sh

# Exit on any error
set -e

# If we don't have a DOMAIN_NAME set, complain and exit
if [ -z "$DOMAIN_NAME" ];
then
    echo "Error: DOMAIN_NAME variable not set."
    exit 1
fi;

# If we don't have a LINODE_CLI_TOKEN set, complain and exit
if [ -z "$LINODE_CLI_TOKEN" ];
then
    echo Error: LINODE_CLI_TOKEN not set.
    echo To get a token for this image, please visit
    echo https://cloud.linode.com/profile/tokens then add a \"Personal Access Token\".
    echo Ensure that this token can only \"read/write\" the NodeBalancer configuration
    echo and that the token never expires.
    echo You must copy the resulting key and pass it into this image.
    exit 1
fi;

# If we don't have a NODEBALANCER_ID, list the available ones and exit
if [ -z "$NODEBALANCER_ID" ];
then
    echo No NODEBALACER_ID set. Set it from the list below.
    linode-cli nodebalancers list
    exit 1
fi;

# If we don't have a CONFIG_ID, list the available ones and exit
if [ -z "$CONFIG_ID" ];
then
    echo No CONFIG_ID set. Set it from the list below.
    linode-cli nodebalancers configs-list $NODEBALANCER_ID
    exit 1
fi;

# Verify that the NODEBALANCER_ID and CONFIG_ID are valid
linode-cli nodebalancers config-view $NODEBALANCER_ID $CONFIG_ID

# Where the acme.sh command is located
export ACME=/root/.acme.sh/acme.sh

# for notifications, see https://github.com/acmesh-official/acme.sh/wiki/notify
# the --notify-hook updates the config file with the contents of the env variables
export NOTIFY_HOOK=

if [ -n "$MAILGUN_API_KEY" ];
then
    echo Setting up for Mailgun
    NOTIFY_HOOK="$NOTIFY_HOOK --notify-hook mailgun"
fi;

if [ -n "$SENDGRID_API_KEY" ];
then
    echo Setting up for Sendgrid
    NOTIFY_HOOK="$NOTIFY_HOOK --notify-hook sendgrid"
fi;

if [ -n "$SLACK_WEBHOOK_URL" ];
then
    echo Setting up for Slack
    NOTIFY_HOOK="$NOTIFY_HOOK --notify-hook slack"
fi;

if [ -n "$IFTTT_API_KEY" ];
then
    echo Setting up for IfTTT
    NOTIFY_HOOK="$NOTIFY_HOOK --notify-hook ifttt"
fi;

# Build the full notify hook parameter
if [ -n "$NOTIFY_HOOK" ];
then
    NOTIFY_HOOK="--set-notify $NOTIFY_HOOK"
fi;

# Start the web server in the background
nginx

# Run the cert using nginx
$ACME --issue -d $DOMAIN_NAME \
      -w /usr/share/nginx/html \
      --reloadcmd "/install_cert.sh" \
      --pre-hook "rm $OK_FILE" \
      $NOTIFY_HOOK \
      --cert-file /root/cert.pem \
      --key-file /root/key.pem \
      --force

# Expected log files
touch /root/.acme.sh/acme.sh.log
touch /var/log/nginx/access.log
touch /var/log/nginx/error.log

# Tail the log files to keep the container alive
tail -f /var/log/nginx/error.log -f /var/log/nginx/access.log -f /root/.acme.sh/acme.sh.log
