FROM ciscocloud/consul-cli:0.3.1

ENV CONSUL_HTTP_ADDR=
ENV CONSUL_TOKEN=
ENV VAULT_ADDR=
ENV VAULT_TOKEN=
ENV CONF_LIST=

COPY store.sh /usr/local/bin/store.sh
COPY vault_0.6.2_SHA256SUMS /usr/local/bin/vault_0.6.2_SHA256SUMS

RUN apk add --update-cache curl unzip \

  && cd /usr/local/bin \

  && curl -L https://releases.hashicorp.com/vault/0.6.2/vault_0.6.2_linux_amd64.zip -o vault_0.6.2_linux_amd64.zip \
  && sha256sum -c vault_0.6.2_SHA256SUMS \
  && unzip vault_0.6.2_linux_amd64.zip \
  && rm vault_0.6.2_linux_amd64.zip vault_0.6.2_SHA256SUMS \

  && apk del curl unzip && rm -rf /var/cache/apk/*

ENTRYPOINT store.sh
