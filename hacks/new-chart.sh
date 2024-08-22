#!/bin/bash

# Get module name
if [ $# -ne 1 ]; then
  echo "Usage: $0 <module-name>"
  exit 1
fi

CHART_NAME="$1"

# Validate chart name
if ! [[ $CHART_NAME =~ ^[a-zA-Z0-9-]+$ ]]; then
  echo "Error: Chart name can only contain lower case alphanumeric characters and dashes."
  exit 1
fi

# Get the git repo root
REPO_ROOT=$(git rev-parse --show-toplevel)
if [ $? -ne 0 ]; then
  echo "Error: Not in a git repository."
  exit 1
fi

# Check if the chart directory already exists
CHART_PATH="$REPO_ROOT/charts/$CHART_NAME"
if [ -d "$CHART_PATH" ]; then
  echo "Error: Chart directory already exists: $CHART_PATH"
  exit 1
fi

# Create chart
helm create $CHART_PATH
if [ $? -ne 0 ]; then
  echo "Error: Failed to create chart."
  exit 1
fi

# Update release-please-config.json
CONFIG_FILE="$REPO_ROOT/release-please-config.json"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: release-please-config.json not found at $CONFIG_FILE"
  exit 1
fi

# Use jq to add the new module to the config file
jq --arg chart "$CHART_NAME" \
  '.packages += {
    "charts/\($chart)": {
      "component": $chart,
      "release-type": "helm",
      "changelog-path": "CHANGELOG.md",
      "bump-minor-pre-major": false,
      "bump-patch-for-minor-pre-major": false,
      "draft": false,
      "prerelease": false
    }
  }' \
  "$CONFIG_FILE" >"$CONFIG_FILE.tmp" &&
  mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
if [ $? -ne 0 ]; then
  echo "Error: Failed to update release-please-config.json"
  exit 1
fi

echo "Module $CHART_NAME created, you should create a new branch and commit these initial changes now

git switch -c new/chart/$CHART_NAME
git add charts/$CHART_NAME
git add release-please-config.json
git commit -m \"feat: add new chart $CHART_NAME\"

As the next step, you should check out the \`#TODO:\` comments created in the files
Continue development, add more commits and push the branch when ready

git push -u origin new/chart/$CHART_NAME
"
