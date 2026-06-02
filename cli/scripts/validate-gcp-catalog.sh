#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../lib/enums.sh
source "${ROOT_DIR}/lib/enums.sh"
# shellcheck source=../lib/gcp_catalog.sh
source "${ROOT_DIR}/lib/gcp_catalog.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local label="$3"

  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL: ${label}" >&2
    echo "  expected: ${expected}" >&2
    echo "  actual:   ${actual}" >&2
    exit 1
  fi
  echo "PASS: ${label}"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"

  if ! grep -q "$needle" <<< "$haystack"; then
    echo "FAIL: ${label}" >&2
    echo "  missing: ${needle}" >&2
    exit 1
  fi
  echo "PASS: ${label}"
}

assert_eq "$(gcp_catalog_merge_pack_csv minimal "")" "" "minimal preset stays core-only"
assert_eq "$(gcp_catalog_merge_pack_csv data-agent "")" "storage,bigquery,pubsub,scheduler" "data-agent preset packs"
assert_eq "$(gcp_catalog_merge_pack_csv ai-agent "pubsub")" "secretmanager,storage,pubsub,artifactregistry,logging,monitoring,vertexai" "ai-agent merges extra packs"

assert_contains "$(gcp_catalog_collect_apis "storage,bigquery")" "storage.googleapis.com" "storage API present"
assert_contains "$(gcp_catalog_collect_apis "storage,bigquery")" "bigquery.googleapis.com" "bigquery API present"
assert_contains "$(gcp_catalog_collect_roles "secretmanager,vertexai")" "roles/secretmanager.admin" "secretmanager role present"
assert_contains "$(gcp_catalog_collect_roles "secretmanager,vertexai")" "roles/aiplatform.user" "vertex ai role present"

echo "GCP catalog checks passed."
