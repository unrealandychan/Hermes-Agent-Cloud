#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if grep -R -nE 'roles/(owner|editor)' "${ROOT_DIR}/terraform/gcp" "${ROOT_DIR}/lib/gcp_catalog.sh"; then
  echo "FAIL: broad GCP IAM roles detected." >&2
  exit 1
fi

if grep -R -n --include="*.tf" '0.0.0.0/0' "${ROOT_DIR}/terraform/gcp"; then
  echo "FAIL: open GCP firewall rule detected." >&2
  exit 1
fi

echo "GCP IAM and firewall policy checks passed."
