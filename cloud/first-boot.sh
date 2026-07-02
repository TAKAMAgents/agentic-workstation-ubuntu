#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
AGENTIC_PROFILE="${AGENTIC_PROFILE:-coding-agent}"
REPO_URL="${AGENTIC_WORKSTATION_REPO:-https://github.com/TAKAMAgents/agentic-workstation-ubuntu.git}"
TARGET_DIR="${AGENTIC_WORKSTATION_DIR:-/opt/agentic-workstation/repo}"
REF="${AGENTIC_BOOTSTRAP_REF:-main}"

apt-get update -y
apt-get install -y git curl ca-certificates

if [[ ! -d "${TARGET_DIR}/.git" ]]; then
  mkdir -p "$(dirname "$TARGET_DIR")"
  git clone "$REPO_URL" "$TARGET_DIR"
fi

git -C "$TARGET_DIR" fetch --all --tags --prune
git -C "$TARGET_DIR" checkout "$REF"
"${TARGET_DIR}/install-agentic-tools.sh" --profile "$AGENTIC_PROFILE" --resume
