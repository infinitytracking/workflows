#!/bin/bash
EXISTING_VERSION=$(yq '.on.workflow_call.inputs.terraform_version.default' .github/workflows/terraform.yml)

LATEST_RELEASE=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest)
LATEST_VERSION=$(echo "$LATEST_RELEASE" | tr '\r\n' ' ' | jq -r .tag_name)
LATEST_VERSION=${LATEST_VERSION//v}

if [ "$EXISTING_VERSION" != "$LATEST_VERSION" ]; then
  # Using diff & patch retains currently structure of terraform.yml
  # Without this, yq will try and reformat & reorder the yaml file
  yq e ".on.workflow_call.inputs.terraform_version.default=\"$LATEST_VERSION\"" .github/workflows/terraform.yml > /tmp/terraform.yml.tmp
  diff -U0 -w -b --ignore-blank-lines .github/workflows/terraform.yml /tmp/terraform.yml.tmp > /tmp/terraform.diff
  patch -s .github/workflows/terraform.yml /tmp/terraform.diff

  RELEASE_URL=$(echo "$LATEST_RELEASE" | tr '\r\n' ' ' | jq -r .html_url)

  # Format release notes to support multi-line output in GitHub Actions
  RELEASE_NOTES=$(echo "$LATEST_RELEASE" | tr '\r\n' ' ' | jq -r .body)
  RELEASE_NOTES="${RELEASE_NOTES//'%'/'%25'}"
  RELEASE_NOTES="${RELEASE_NOTES//$'\n'/'%0A'}"
  RELEASE_NOTES="${RELEASE_NOTES//$'\r'/'%0D'}"

  # If script ran in a GitHub Action, set GA outputs
  if [[ -n "${GITHUB_ACTIONS}" ]]; then
    echo "::set-output name=EXISTING_VERSION::$EXISTING_VERSION"
    echo "::set-output name=LATEST_VERSION::$LATEST_VERSION"
    echo "::set-output name=RELEASE_URL::$RELEASE_URL"
    echo "::set-output name=RELEASE_NOTES::$RELEASE_NOTES"
  fi
fi
