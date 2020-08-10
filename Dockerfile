FROM nginx:stable-alpine

# based on https://github.com/Docker-Hub-frolvlad/docker-alpine-python3/blob/master/Dockerfile
# This hack is widely applied to avoid python printing issues in docker containers.
# See: https://github.com/Docker-Hub-frolvlad/docker-alpine-python3/pull/13
ENV PYTHONUNBUFFERED=1
VOLUME /data

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
    /root/.acme.sh/acme.sh --uninstall-cronjob && \
    echo "**** setup health file ****" && \
    mkdir -p    /usr/share/nginx/html/.well-known/acme-challenge && \
    echo "ok" > /usr/share/nginx/html/.well-known/acme-challenge/__ok__.txt

ENV OK_FILE="/usr/share/nginx/html/.well-known/acme-challenge/__ok__.txt"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY serve.sh install_cert.sh /

EXPOSE 80

CMD /serve.sh
