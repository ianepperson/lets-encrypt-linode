#!/bin/sh

# Exit on any error
set -e

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
nginx -g 'daemon off;' &

# Run the cert using nginx
$ACME --issue -d $DOMAIN_NAME \
      -w /usr/share/nginx/html \
      --reloadcmd "/install_cert.sh" \
      --pre-hook "rm $OK_FILE" \
      --cert-file /root/cert.pem \
      --key-file /root/key.pem

# Bring the web server back to the foreground
fg
