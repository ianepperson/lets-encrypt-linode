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
The only traffic that it doesn't redirect is the traffic necessary for the Let's Encrypt client to create the certificate. When the certificate updates, this
container will automatically update the NodeBalancer for a seamless experience.

## Security

If you have strict security requirements, you should probably not use this package nor this approach to securing web traffic. You must trust this package, Github, Docker, Letsencrypt, acme.sh and Linode (and likely more).

Traffic to the NodeBalancer will be encrypted, but traffic between the NodeBalancer and the Linode instances *will not* be encrypted. That means that unencrypted web traffic could be intercepted by someone who has access to Linode's data center's switch network. However, such an attack is difficult and not normally possible without physical access.

A more secure configuration would be to install the certs on each web server (and update them in lockstep) and pass traffic through the NodeBalander without decrypting it. That configuration is beyond the scope of this project.

## Usage

You may want to use this package as part of a docker-compose setup. For simple usage, you can pull and launch the container without too much fuss.

You need to be able to update your DNS record for your domain name.

Ensure [Docker](https://docs.docker.com/get-docker/) is installed on one of your Linode instances.

Copy the [sample.env](https://github.com/ianepperson/lets-encrypt-linode/raw/master/sample.env) file to your Linode instance and update the varaibles within.

It's handy to have [Linode-cli](https://www.linode.com/docs/platform/api/linode-cli/) installed to discover the ID of your NodeBalancer and Config. It's a good idea to set it up on your local development machine.

## NodeBalancer

You need a single NodeBalancer with two configs:

- 80/http which forwards to the lets-encrypt-linode Docker container.
- 443/https which will be updated by the Docker container, and forwards to your web server.

You will need to know the NodeBalancer's ID and the 443/https config's ID. This can be determined through the Linode-cli.

## Getting Started

Set up a new [Linode NodeBalancer](https://www.linode.com/docs/platform/nodebalancer/getting-started-with-nodebalancers/).

When creating the NodeBalancer, you'll create two nodes - one to route HTTP traffic and one to route HTTPS traffic.
At the top of the NodeBalancer configuration, you'll be setting up the first node. Make it an HTTP node listening on port 80. This will be directed to the
lets-encrypt-linode image, which will then redirect almost all traffic back through the HTTPS node. If you're running this image on a Linode instance that's
already running an instance of your web server, you can direct it to a different port when setting up the "NodeBalander configurations" a bit later down the page.

For my setup, I set my NodeBalancer port 80 to go to my first Linode instance's port 88. (Then I run the Docker image on port 88 instead of 80). It's very important
that there only be a single backend server for this configuration - that of the lets-encrypt-linode docker image.

Add the second configuration and set it to port 443 with HTTPS. It will require a certificate - and keep in mind that whatever certificate you provide will be replaced
once the docker image is up and running.  You can create a self-signed temporary certificate to continue - [this website](https://www.selfsignedcertificate.com/) can generate
one for you, but DO NOT TRUST IT LONG-TERM! Set the Backend nodes of this 443/HTTPS config to forward traffic to your webserver(s).

If you had to add a "private IP" to your Linode instance to complete the above step, make sure the instance gets rebooted to pick up the new IP address.

Now, log into the Linode instance that will receive your 80/http traffic (where the lets-encrypt-linode Docker image will run) and pull the image and configuration file.

```
> docker pull docker.pkg.github.com/ianepperson/lets-encrypt-linode/lets-encrypt-linode:latest

> wget https://github.com/ianepperson/lets-encrypt-linode/raw/master/sample.env
```

Rename the sample.env file to something more appropriate, perhaps "lets-encrypt-linode.env".

```
> mv sample.env lets-encrypt-linode.env
```

For the next few steps, you'll be gathering the variables that need to go into that env file. Edit the file with your favorite editor (or nano if you don't have one)

```
> nano lets-encrypt-linode.env
```

Put in your domain name (without any http:// prefix or path suffix)

Go to the Linode website and create an API token to allow the Docker image to edit the NodeBalancer configuration. In the [Linode interface](https://cloud.linode.com/profile/tokens), add a "Personal Access Token". Ensure that this token can only "read/write" the NodeBalancer configuration and that the token never expires. You must copy the resulting key and add that to the env variables file.

If you have the linode-cli installed, use it to find the NodeBalancer id (using `linode-cli nodebalancers list`) and NodeBalancer Config id (using `linode-cli nodebalancers configs-list <nodebalancer-id>`). If you don't have linode-cli setup, you can do the following:

Save the lets-encrypt-linode.env file and exit back to the command line. Run the container with the partial variables and it should show you what need to add in.

```
> $ docker run --rm --env-file ./lets-encrypt-linode.env docker.pkg.github.com/ianepperson/lets-encrypt-linode/lets-encrypt-linode

No NODEBALACER_ID set. Set it from the list below.
┌───────┬────────────┬─────────┬───────────────────────────────────────────────────┬──────┐
│ id    │ label      │ region  │ hostname                                          │ ...  │
├───────┼────────────┼─────────┼───────────────────────────────────────────────────┼──────┤
│ 00001 │ mybalancer │ xxxxxxx │ _________________________.nodebalancer.linode.com │      │
└───────┴────────────┴─────────┴───────────────────────────────────────────────────┴──────┘
```

Reopen the `lets-encrypt-linode.env` file, and add in the NODEBALANCER_ID field from the provided table. (The table might look skewed in your terminal - the important thing is the first number on the line, the ID.) Save the file and exit, then re-run the command:

```
> $ docker run --rm --env-file ./lets-encrypt-linode.env docker.pkg.github.com/ianepperson/lets-encrypt-linode/lets-encrypt-linode

No CONFIG_ID set. Set it from the list below.
┌───────┬──────┬──────────┬────────────┬────────────┬─────┐
│ id    │ port │ protocol │ algorithm  │ stickiness │ ... │
├───────┼──────┼──────────┼────────────┼────────────┼─────┤
│ 00010 │ 80   │ http     │ .......... │ .....      │     │
│ 00011 │ 443  │ https    │ .......... │ .....      │     │
└───────┴──────┴──────────┴────────────┴────────────┴─────┘
```

Find the ID for the 443/https configuration and note it. Reopen the `lets-encrypt-linode.env` file, and add in the CONFIG_ID field from the provided table.


Now, let's start up the service. If you're forwarding the HTTP traffic through the load balancer to a port other than 88, then change the `-p 88:80` as necessary. (ie, if you've set it to use 8080, use `-p 8080:80`.)

```
> docker run -p 88:80 -d --env-file ./lets-encrypt-linode.env --mount='type=volume,src=lets-encrypt-linode,dst=/data' docker.pkg.github.com/ianepperson/lets-encrypt-linode/lets-encrypt-linode
```

Use `docker ps` to see your running containers. If there was an error and your container didn't start it will not be listed; leave off the `-d` to see the output on your console.

Potential problems might be:

 - The NodeBalancer isn't routing http/80 traffic to this Linode instance (check the NodeBalancer config for http/80).
 - Your domain name isn't resolving to the NodeBalancer (ensure that you have an DNS "A" record pointing to the NodeBalancer's IP address).

To see the logged output, use `docker logs <the container id>` - which should show the service listing the old linode configuration, getting a new cert, then updating the linode configuration with a new SSL fingerprint. Nginx's logs are tail'd to this output as well - you should see any access the HTTP/80 server.

Congratulations! Now navigate to your domain name via http (`http://my_domain.com` or whatever) and you should be immediately redirected to a valid https connection (`https://my_domain.com`). As long as the container is running, it will refresh the certificate every 60 days. Every time the container restarts the certificate will be renewed. To generate a new certificate or to change the domain name, stop the container, delete the `lets-encrypt-linode` volume and restart the container.

## Volumes

The images stores its data (`key.pem`, `cert.pem` and more) in the `/data` volume. The simplest usage is to create a Docker volume and mount it. This is reasonably secure as the data is only visible to the host `root` user and anyone who can use Docker to mount the volume.

More complex mount solutions (and more secure volumes) are beyond the scope of this documentation.

## Monitoring

You can use the NodeBalancer's passive health checks to verify that the container is still running.

A text file with the contents of `ok` is written to `http://<your domain>/.well-known/acme-challenge/__ok__.txt` after a new certificate is successfully installed in the NodeBalancer. That path will return a 404 while the new certificate is being generated and will continue returning a 404 if it does not successfully install.

If you configure the optional notifications (via additional environment variables) status will be reported through those services.

## Updating

When this Docker image is updated and you want to start using it, or if you want to change your configuration, you're going to have to stop the container and start up a new one. During this transition period, some functionality will be lost - specifically, http traffic that comes into your site will receive a 500 error instead of being redirected to https. However, https traffic will not be effected. For all visitors who have already been redirected or those coming in via an https link, there will be no downtime.

## Required Variables

 * DOMAIN_NAME
 * LINODE_CLI_TOKEN
 * NODEBALANCER_ID
 * CONFIG_ID

Note that if you change the DOMAIN_NAME you've been using, you'll have to delete and recreate the volume as well to prevent the attempted automatic renewal of the old name.

## Optional Variables

The Docker image allows defining a couple of ways to give feedback about the status. This is derived from [the ansi.sh tool](https://github.com/acmesh-official/acme.sh/wiki/notify),
but note that this image does not support every alert mechanism that ansi.sh supports. (If you need a supported method added, feel free to file a pull request.)

### Mailgun

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


### Sendgrid

```
 SENDGRID_API_KEY="xxxxxxxxxx"
 SENDGRID_FROM="xxxx@cccc.com"
 SENDGRID_TO="xxxx@xxx.com"
```

### Slack

Set up your [webhook](https://slack.com/apps/A0F7XDUAZ-incoming-webhooks), then set this

```
 SLACK_WEBHOOK_URL="..."
 SLACK_CHANNEL="..."     # overwrites Slack Webhook channel
 SLACK_USERNAME="..."    # overwrites Slack Webhook username
```

### If-This-Then-That

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
