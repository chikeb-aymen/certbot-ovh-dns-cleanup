## certbot-ovh-dns-cleanup

Kubernetes-ready Certbot + OVH DNS image that:
- Uses a patched `dns-lexicon` for OVH TXT handling.
- Runs a post-issuance cleanup script to delete stale `_acme-challenge.*` TXT records via the OVH API.

### Why

OVH changed how TXT records are returned (wrapped in quotes), which broke TXT cleanup in some `dns-lexicon` / Certbot versions. See:
- [dns-lexicon PR #65](https://github.com/dns-lexicon/dns-lexicon/pull/65)
- [certbot/certbot#10492](https://github.com/certbot/certbot/issues/10492)

This repo shows a practical workaround:
- Custom Certbot-dns-ovh image with updated `dns-lexicon`.
- Small Python/OVH script to delete `_acme-challenge.*` TXT records after successful issuance.

### Usage

1. Build and push the image:

```bash
docker build -t your-registry.example.com/certbot-ovh-dns-cleanup:latest .
docker push your-registry.example.com/certbot-ovh-dns-cleanup:latest
```

2. Create a Kubernetes secret with your OVH API credentials:

```ini
# file content mounted as /root/.ovhapi
dns_ovh_endpoint=ovh-eu
dns_ovh_application_key=...
dns_ovh_application_secret=...
dns_ovh_consumer_key=...
```

3. Apply the example CronJob (see `k8s-cronjob-example.yaml`), adjusting:

- Image name (`your-registry.example.com/certbot-ovh-dns-cleanup:latest`)
- Email address
- Domain names (`example.com`, `*.example.com`)

The cleanup script will run after a successful issuance and remove any `_acme-challenge.*` TXT records in the specified OVH zone.