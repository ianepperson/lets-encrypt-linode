FROM nginx:stable-alpine

# based on https://github.com/Docker-Hub-frolvlad/docker-alpine-python3/blob/master/Dockerfile
# This hack is widely applied to avoid python printing issues in docker containers.
# See: https://github.com/Docker-Hub-frolvlad/docker-alpine-python3/pull/13
ENV PYTHONUNBUFFERED=1

RUN echo "**** install OpenSSL ****" && \
    apk add --no-cache openssl && \
    echo "**** install Python ****" && \
    apk add --no-cache python3 && \
    if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi && \
    \
    echo "**** install pip ****" && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --no-cache --upgrade pip setuptools wheel && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    echo "**** install linode-cli ****" && \
    pip3 install --no-cache linode-cli && \
    echo "**** install acme.sh ****" && \
    curl https://get.acme.sh | sh && \
    echo "**** setup health file ****" && \
    mkdir -p    /usr/share/nginx/html/.well-known/acme-challenge && \
    echo "ok" > /usr/share/nginx/html/.well-known/acme-challenge/__ok__

ENV OK_FILE="/usr/share/nginx/html/.well-known/acme-challenge/__ok__"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY serve.sh install_cert.sh /

ENV DOMAIN_NAME="changeme.com"

# from linode:
ENV LINODE_CLI_TOKEN="change-me"
ENV NODEBALANCER_ID=""
ENV CONFIG_ID=""

EXPOSE 80

CMD /serve.sh
