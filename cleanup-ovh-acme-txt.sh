#!/bin/sh
set -eu

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <OVH_ZONE_DOMAIN> [OVH_CONFIG_FILE]" >&2
  exit 1
fi

ZONE_DOMAIN="$1"                       # e.g. example.com
OVH_CFG_FILE="${2:-/root/.ovhapi}"    # same file Certbot uses

python - "$ZONE_DOMAIN" "$OVH_CFG_FILE" <<'PY'
import sys

if len(sys.argv) < 3:
    sys.exit("Usage: script <zone_domain> <ovh_cfg_file>")

zone = sys.argv[1]
cfg_path = sys.argv[2]
print(f"[cleanup] Zone={zone}, cfg={cfg_path}")

cfg = {}
with open(cfg_path) as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = [p.strip() for p in line.split("=", 1)]
        cfg[k] = v

import ovh

client = ovh.Client(
    endpoint=cfg.get("dns_ovh_endpoint", "ovh-eu"),
    application_key=cfg["dns_ovh_application_key"],
    application_secret=cfg["dns_ovh_application_secret"],
    consumer_key=cfg["dns_ovh_consumer_key"],
)

record_ids = client.get(f"/domain/zone/{zone}/record", fieldType="TXT")
print(f"[cleanup] Found {len(record_ids)} TXT records in zone {zone}")

to_delete = []
for rid in record_ids:
    rec = client.get(f"/domain/zone/{zone}/record/{rid}")
    sub = rec.get("subDomain", "")
    print(f"[cleanup] TXT id={rid}, subDomain={sub}")
    if sub == "_acme-challenge" or sub.startswith("_acme-challenge."):
        to_delete.append(rid)

if not to_delete:
    print("[cleanup] No _acme-challenge TXT records to delete")
else:
    print(f"[cleanup] Deleting {len(to_delete)} _acme-challenge TXT record(s)")
    for rid in to_delete:
        client.delete(f"/domain/zone/{zone}/record/{rid}")
    client.post(f"/domain/zone/{zone}/refresh")
PY || echo "[cleanup] OVH cleanup failed (see traceback above, but continuing)"