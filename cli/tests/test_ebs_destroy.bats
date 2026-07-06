#!/usr/bin/env bats
# tests/test_ebs_destroy.bats
# Unit tests for AWS EBS destroy behavior

setup() {
  TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  CLI_DIR="$(dirname "$TEST_DIR")"

  export FAKE_HOME="$(mktemp -d)"
  export HOME="$FAKE_HOME"
  export HERMES_DEPLOY_HOME="$HOME/.hermes-agent-cloud"
  mkdir -p "$HERMES_DEPLOY_HOME"

  # Minimal config stubs
  source "$CLI_DIR/lib/config.sh"
  gum() { :; }
  warn() { :; }
  success() { :; }
  error() { echo "ERROR: $*" >&2; }
  spinner() { shift; "$@"; }
}

teardown() {
  rm -rf "$FAKE_HOME"
}

@test "ebs.tf no longer contains prevent_destroy" {
  run grep -R "prevent_destroy" "$CLI_DIR/terraform/aws/ebs.tf" "$CLI_DIR/../modules/aws/ebs.tf"
  [ "$status" -ne 0 ] || [ -z "$output" ]
}

@test "aws_destroy aborts when user declines EBS deletion" {
  config_set "tf_dir" "/tmp/fake-tf"
  config_set "ebs_enabled" "true"

  # Override gum to simulate user declining the confirmation
  gum() {
    if [[ "$1" == "confirm" ]]; then
      return 1
    fi
    return 0
  }
  export -f gum

  source "$CLI_DIR/lib/aws.sh"

  run aws_destroy
  [ "$status" -eq 0 ]
  [[ "$output" == *"Aborted"* ]] || [[ "$output" == *"Detach"* ]]
}
