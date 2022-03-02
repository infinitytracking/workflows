#!/bin/bash

EXISTING_VERSION=$(yq '.on.workflow_call.inputs.terraform_version.default' .github/workflows/terraform.yml)

LATEST_RELEASE=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest)
LATEST_VERSION=$(echo "$LATEST_RELEASE" | tr '\r\n' ' ' | jq -r .tag_name)
LATEST_VERSION=${LATEST_VERSION//v}

if [ "$EXISTING_VERSION" != "$LATEST_VERSION" ]; then
  yq e ".on.workflow_call.inputs.terraform_version.default=\"$LATEST_VERSION\"" .github/workflows/terraform.yml > /tmp/terraform.yml.tmp
  diff -U0 -w -b --ignore-blank-lines .github/workflows/terraform.yml /tmp/terraform.yml.tmp > /tmp/terraform.diff
  patch -s .github/workflows/terraform.yml /tmp/terraform.diff
  RELEASE=$(echo "$LATEST_RELEASE" | tr '\r\n' ' ' | jq -r .html_url)

  if [[ -n "${GITHUB_ACTIONS}" ]]; then
    echo "::set-output name=EXISTING_VERSION::$EXISTING_VERSION"
    echo "::set-output name=LATEST_VERSION::$LATEST_VERSION"
    echo "::set-output name=RELEASE::$RELEASE"
  fi
fi
