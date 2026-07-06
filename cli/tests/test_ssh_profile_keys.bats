#!/usr/bin/env bats
# tests/test_ssh_profile_keys.bats
# Unit tests for profile-aware SSH key upload helpers in cli/lib/ssh.sh

setup() {
  TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  CLI_DIR="$(dirname "$TEST_DIR")"

  # Create an isolated fake HOME for each test
  export FAKE_HOME="$(mktemp -d)"
  export HOME="$FAKE_HOME"

  # Source only the helpers we need, stubbing dependencies
  source "$CLI_DIR/lib/ssh.sh"

  # Stub gum/warn/success to no-ops so tests run headless
  gum() { :; }
  warn() { :; }
  success() { :; }
  error() { echo "ERROR: $*" >&2; }
}

teardown() {
  rm -rf "$FAKE_HOME"
}

@test "_ssh_active_profile returns default when profile_get_active is unavailable" {
  # Ensure profile_get_active is NOT defined in this subshell
  unset -f profile_get_active 2>/dev/null || true
  run bash -c 'source "'$CLI_DIR'/lib/ssh.sh"; _ssh_active_profile'
  [ "$status" -eq 0 ]
  [ "$output" = "default" ]
}

@test "_ssh_local_env_file returns ~/.hermes/.env for default profile" {
  run bash -c 'source "'$CLI_DIR'/lib/ssh.sh"; _ssh_local_env_file default'
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.hermes/.env" ]
}

@test "_ssh_local_env_file returns ~/.hermes-profiles/<name>/.env for named profile" {
  run bash -c 'source "'$CLI_DIR'/lib/ssh.sh"; _ssh_local_env_file work'
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.hermes-profiles/work/.env" ]
}

@test "ssh_upload_profile_keys warns when local .env is missing" {
  run bash -c '
    source "'$CLI_DIR'/lib/ssh.sh"
    ssh_upload_profile_keys 127.0.0.1 ubuntu /tmp/nonexistent
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"no local .env file"* ]]
}

@test "ssh_upload_profile_keys extracts known keys from local .env" {
  mkdir -p "$HOME/.hermes"
  cat > "$HOME/.hermes/.env" <<EOF
OPENROUTER_API_KEY=sk-or-test
OPENAI_API_KEY=sk-openai-test
ANTHROPIC_API_KEY=sk-anthropic-test
GEMINI_API_KEY=sk-gemini-test
EOF

  # Stub ssh_upload_env to echo its arguments so we can verify them
  ssh_upload_env() {
    echo "ssh_upload_env called with profile=$4 or=$5 oa=$6 an=$7 ge=$8"
  }
  export -f ssh_upload_env

  run bash -c '
    source "'$CLI_DIR'/lib/ssh.sh"
    ssh_upload_profile_keys 127.0.0.1 ubuntu /tmp/nonexistent
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"profile=default"* ]]
  [[ "$output" == *"or=sk-or-test"* ]]
  [[ "$output" == *"oa=sk-openai-test"* ]]
  [[ "$output" == *"an=sk-anthropic-test"* ]]
  [[ "$output" == *"ge=sk-gemini-test"* ]]
}
