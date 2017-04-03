FROM alpine:edge

ENV VAULT_VERSION=0.7.0
ENV VAULT_SHA256=c6d97220e75335f75bd6f603bb23f1f16fe8e2a9d850ba59599b1a0e4d067aaa

ENV CONSUL_CLI_VERSION=0.3.1
ENV CONSUL_CLI_SHA256=037150d3d689a0babf4ba64c898b4497546e2fffeb16354e25cef19867e763f1

RUN \
  apk add --no-cache --virtual .build-deps curl unzip \

  && echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
  && apk add --no-cache perl perl-string-random@testing \

  && cd /usr/local/bin \
  && curl -L https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip -o vault_${VAULT_VERSION}_linux_amd64.zip \
  && echo -n "$VAULT_SHA256  vault_${VAULT_VERSION}_linux_amd64.zip" | sha256sum -c - \
  && unzip vault_${VAULT_VERSION}_linux_amd64.zip \
  && rm vault_${VAULT_VERSION}_linux_amd64.zip \

  && curl -L https://github.com/CiscoCloud/consul-cli/releases/download/v${CONSUL_CLI_VERSION}/consul-cli_${CONSUL_CLI_VERSION}_linux_amd64.tar.gz -o /tmp/consul-cli_${CONSUL_CLI_VERSION}_linux_amd64.tar.gz \
  && echo -n "$CONSUL_CLI_SHA256  /tmp/consul-cli_${CONSUL_CLI_VERSION}_linux_amd64.tar.gz" | sha256sum -c - \
  && mkdir -p /tmp/consul-cli \
  && tar xzvf /tmp/consul-cli_${CONSUL_CLI_VERSION}_linux_amd64.tar.gz -C /tmp/consul-cli \
  && cp /tmp/consul-cli/consul-cli_${CONSUL_CLI_VERSION}_linux_amd64/consul-cli /usr/local/bin \
  && rm -rf /tmp/consul-cli \
  && rm /tmp/consul-cli_${CONSUL_CLI_VERSION}_linux_amd64.tar.gz \

  && apk del --force .build-deps

ENV CONSUL_HTTP_ADDR=
ENV CONSUL_TOKEN=
ENV VAULT_ADDR=
ENV VAULT_TOKEN=
ENV CONF_LIST=

COPY store.sh /usr/local/bin/store.sh
COPY random_regex.pl /usr/local/bin/random_regex.pl

CMD ["/usr/local/bin/store.sh"]
