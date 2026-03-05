FROM certbot/dns-ovh:v5.1.0

# Ensure we include dns-lexicon release with OVH TXT fix
RUN pip install --no-cache-dir "dns-lexicon>=3.23.2" "ovh>=1.0.0"
RUN apk update && apk add --no-cache curl

RUN curl -LO https://dl.k8s.io/release/v1.24.16/bin/linux/amd64/kubectl \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

COPY cleanup-ovh-acme-txt.sh /usr/local/bin/cleanup-ovh-acme-txt.sh
RUN chmod +x /usr/local/bin/cleanup-ovh-acme-txt.sh

ENTRYPOINT []