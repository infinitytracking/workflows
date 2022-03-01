#!/bin/bash

EXISTING_VERSION=$(yq '.on.workflow_call.inputs.terraform_version.default' .github/workflows/terraform.yml)

LATEST_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r .tag_name)
LATEST_VERSION=${LATEST_VERSION//v}

if [ "$EXISTING_VERSION" != "$LATEST_VERSION" ]; then
  yq e ".on.workflow_call.inputs.terraform_version.default=\"$LATEST_VERSION\"" .github/workflows/terraform.yml > /tmp/terraform.yml.tmp
  diff -U0 -w -b --ignore-blank-lines .github/workflows/terraform.yml /tmp/terraform.yml.tmp > /tmp/terraform.diff
  patch -s .github/workflows/terraform.yml /tmp/terraform.diff
fi
