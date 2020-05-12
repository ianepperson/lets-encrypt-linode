![Docker](https://github.com/ianepperson/lets-encrypt-linode/workflows/Docker/badge.svg)

# Lets Encrypt Linode!

This is a simple Docker container to assist in using [Let's Encrypt](https://letsencrypt.org/) with a [Linode NodeBalancer](https://www.linode.com/products/nodebalancers/) to upgrade an HTTP connection to HTTPS.

## Background

Every website should use HTTPS (HTTP Secure) instead of HTTP to ensure a secure connection for visitors. However, setting up the appropriate certificates can be
difficult, and sometimes expensive.

[Let's Encrypt](https://letsencrypt.org/) provides free TLS certificates required for HTTPS, but the certificates are fairly short and expire every 90 days. In order to effectively use
it, you really should have some kind of automated way to refresh and install an updated certificate. There are simple to use tools to do this with a single webserver,
but most serious websites want to scale well, and therefore should use a load balancer to distribute connections to a group of servers. Instead of setting up the
HTTPS encryption for each web server, it's best to set up the HTTPS encryption on the load balancer itself.

Linode's [NodeBalancer](https://www.linode.com/products/nodebalancers/) can be that endpoint. The simplest way to use it is to provide the SSL certificate directly
within their web UI, but that means when the certificate expires (every 90 days) you'll again have to copy/paste the cert into the web UI. Linode provides a command
line utility to automate service setup - which means that with a bit of magic, the certificate can be auto-updated.

Finally, your website should redirect HTTP traffic to HTTPS to ensure your visitors are getting a secure connection. This is a fairly strait-forward setup within most
web servers, but it still needs to be set up properly.

## Let's Encrypt Linode

That's where this package comes in. The idea is that this Docker container spins up a minimal web server (Nginx) which redirects almost all HTTP traffic to HTTPS.
The only traffic that it doesn't redirect, is the traffic necessary for the Let's Encrypt client to create the certificate. When the certificate updates, this
container will automatically update the NodeBalancer for a seamless experience.

## Usage

docker run -it --rm lets-encrypt-linode /bin/ash

store your token in an environment variable named LINODE_CLI_TOKEN

need the NodeBalancerID and ConfigID from Linode
need the domain name for the acme.sh


### Required Variables

 * DOMAIN_NAME
 * LINODE_CLI_TOKEN
 * NODEBALANCER_ID
 * CONFIG_ID

### Optional Variables

The Docker image allows defining a couple of ways to give feedback about the status. This is derived from (here)[https://github.com/acmesh-official/acme.sh/wiki/notify]

#### Mailgun

```
 #The api key in your account.
 MAILGUN_API_KEY="xxxxxxxx"
 
 #The api domain, you can use the sandbox domain in your account.
 MAILGUN_API_DOMAIN="xxxxxx.com"
 
 #Optional,  the mail from address. it must be user@MAILGUN_API_DOMAIN
 MAILGUN_FROM="xxx@xxxxxx.com"
 
 #The mail to address, which is to receive the notification.
 MAILGUN_TO="yyyy@gmail.com"
 
 #Optional, if your mailgun account is in eu region, you must set MAILGUN_REGION
 MAILGUN_REGION="us|eu"          #optional, use "us" as default
```


#### Sendgrid

```
 SENDGRID_API_KEY="xxxxxxxxxx"
 SENDGRID_FROM="xxxx@cccc.com"
 SENDGRID_TO="xxxx@xxx.com"
```

#### Slack

Set up your (webhook)[https://slack.com/apps/A0F7XDUAZ-incoming-webhooks], then set this

```
 SLACK_WEBHOOK_URL="..."
 SLACK_CHANNEL="..."     # overwrites Slack Webhook channel
 SLACK_USERNAME="..."    # overwrites Slack Webhook username
```

#### If This Then That

Send notification via IFTTT Webhooks so that you can make this work with tons of IFTTT services.

Firstly, connect our IFTTT to Webhooks service at https://ifttt.com/maker_webhooks and click "Documentation" in the top right corner to get the API key.

Secondly, create our IFTTT applet with Webhooks as this' and whatever as that', we'll setup the event name(e.g. acme_status) for this applet trigger.

Now we can set up the notification hook:

```
 #The API key.
 IFTTT_API_KEY="xxxx"
 
 #Our event name, this should be same as the setting of your applet.
 IFTTT_EVENT_NAME="acme_status"
 
 #Optional: the key of notification subject, available values are "value1", "value2", "value3", default "value1"
 IFTTT_SUBJECT_KEY="value1"
 
 #Optional: the key of notification content, available values are "value1", "value2", "value3", default "value2"
 IFTTT_CONTENT_KEY="value2"
```
 
