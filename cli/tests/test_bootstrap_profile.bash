#!/usr/bin/env bash
# tests/test_bootstrap_profile.bash
# Verifies bootstrap.sh builds the correct HERMES_HOME for default and named profiles.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP="${SCRIPT_DIR}/../scripts/bootstrap.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }

# Test 1: default profile -> HERMES_HOME contains /home/$HERMES_USER/.hermes
grep -A1 'if \[\[ "\$HERMES_PROFILE" == "default" \]\]' "$BOOTSTRAP" | grep -q 'HERMES_HOME="/home/\$HERMES_USER/.hermes"' || fail "default HERMES_HOME not set correctly"

# Test 2: named profile -> HERMES_HOME = /home/ubuntu/.hermes-profiles/<name>
grep -q 'HERMES_PROFILES_ROOT="/home/${HERMES_USER}/.hermes-profiles"' "$BOOTSTRAP" || fail "HERMES_PROFILES_ROOT not set correctly"
grep -q 'HERMES_HOME="${HERMES_PROFILES_ROOT}/${HERMES_PROFILE}"' "$BOOTSTRAP" || fail "named profile HERMES_HOME not set correctly"

echo "PASS: bootstrap.sh profile paths are correct"
