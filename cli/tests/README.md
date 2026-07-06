# CLI Tests

This directory contains unit and integration-style tests for the `hermes-agent-cloud` CLI.

## Test Types

| File | Framework | Purpose |
|------|-----------|---------|
| `test_ssh_profile_keys.bats` | [Bats](https://bats-core.readthedocs.io/) | Verifies profile-aware `.env` path resolution and key extraction |
| `test_ebs_destroy.bats` | Bats | Verifies EBS `prevent_destroy` removal and destroy confirmation behavior |
| `test_bootstrap_profile.bash` | Bash | Verifies `bootstrap.sh` uses the correct `HERMES_HOME` for default and named profiles |

## Running Tests

```bash
# Install Bats (macOS)
brew install bats-core

# Run all Bats tests
bats cli/tests

# Run a single test file
bats cli/tests/test_ssh_profile_keys.bats

# Run the bash-only test
bash cli/tests/test_bootstrap_profile.bash
```

## CI

The existing `.github/workflows/ci.yml` runs `shellcheck` and `terraform validate`. Consider adding a Bats step once Bats is installed in CI.

