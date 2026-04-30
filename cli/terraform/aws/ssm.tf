# ssm.tf — AWS SSM Parameter Store for Hermes Agent
#
# API keys are NO LONGER injected at deploy time.
# Hermes Agent's own first-run setup (hermes config) handles key configuration
# after the instance is provisioned.
#
# This file is intentionally minimal. You may use it in the future to add
# other SSM parameters (e.g. custom model endpoints, org tokens).
