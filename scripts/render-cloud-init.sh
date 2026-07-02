#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

USER_NAME="ubuntu"
SSH_KEY_FILE=""
SSH_KEY_VALUE=""
PROFILE="agent-runner"
REPO_URL="https://github.com/TAKAMAgents/agentic-workstation-ubuntu.git"
REF="main"
TEMPLATE="${REPO_DIR}/cloud/cloud-init.yaml.tmpl"
WORKSPACE_REPO=""
WORKSPACE_REF="main"
WORKSPACE_TARGET=""

usage() {
  cat <<'USAGE'
Usage:
  scripts/render-cloud-init.sh --ssh-key PATH [options]

Options:
  --user NAME       Linux user to create. Default: ubuntu
  --ssh-key PATH    SSH public key file.
  --ssh-key-value   SSH public key string.
  --profile NAME    Installer profile. Default: agent-runner
  --repo URL        Agentic Workstation Git URL.
  --ref REF         Git ref to checkout. Prefer a tag or commit for images.
  --workspace-repo URL
                    Workspace Git repo to hydrate during install.
  --workspace-ref REF
                    Workspace ref. Default: main
  --workspace-target PATH
                    Workspace target path.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)
      USER_NAME="$2"
      shift 2
      ;;
    --ssh-key)
      SSH_KEY_FILE="$2"
      shift 2
      ;;
    --ssh-key-value)
      SSH_KEY_VALUE="$2"
      shift 2
      ;;
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --repo)
      REPO_URL="$2"
      shift 2
      ;;
    --ref)
      REF="$2"
      shift 2
      ;;
    --workspace-repo)
      [[ $# -ge 2 ]] || {
        echo "--workspace-repo requires a value" >&2
        exit 1
      }
      WORKSPACE_REPO="$2"
      shift 2
      ;;
    --workspace-ref)
      [[ $# -ge 2 ]] || {
        echo "--workspace-ref requires a value" >&2
        exit 1
      }
      WORKSPACE_REF="$2"
      shift 2
      ;;
    --workspace-target)
      [[ $# -ge 2 ]] || {
        echo "--workspace-target requires a value" >&2
        exit 1
      }
      WORKSPACE_TARGET="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -n "$SSH_KEY_FILE" ]]; then
  SSH_KEY_VALUE="$(<"$SSH_KEY_FILE")"
fi

if [[ -z "$SSH_KEY_VALUE" ]]; then
  echo "provide --ssh-key or --ssh-key-value" >&2
  exit 2
fi

if [[ "$REF" == "main" ]]; then
  echo "warning: --ref main is not reproducible; prefer a tag or commit" >&2
fi

shell_quote() {
  local value="$1"

  printf "'"
  while [[ "$value" == *"'"* ]]; do
    printf "%s%s" "${value%%\'*}" "'\\''"
    value="${value#*\'}"
  done
  printf "%s'" "$value"
}

sed_escape_replacement() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//&/\\&}"
  value="${value//|/\\|}"
  printf '%s' "$value"
}

workspace_exports() {
  if [[ -z "$WORKSPACE_REPO" ]]; then
    printf ''
    return 0
  fi

  printf '      export WORKSPACE_REPO=%s\n' "$(shell_quote "$WORKSPACE_REPO")"
  printf '      export WORKSPACE_REF=%s\n' "$(shell_quote "$WORKSPACE_REF")"
  if [[ -n "$WORKSPACE_TARGET" ]]; then
    printf '      export WORKSPACE_TARGET=%s\n' "$(shell_quote "$WORKSPACE_TARGET")"
  fi
}

WORKSPACE_EXPORTS="$(workspace_exports)"
PROFILE_SH="$(shell_quote "$PROFILE")"
REPO_SH="$(shell_quote "$REPO_URL")"
REF_SH="$(shell_quote "$REF")"

sed \
  -e "s|__USER__|$(sed_escape_replacement "$USER_NAME")|g" \
  -e "s|__SSH_KEY__|$(sed_escape_replacement "$SSH_KEY_VALUE")|g" \
  -e "s|__PROFILE_SH__|$(sed_escape_replacement "$PROFILE_SH")|g" \
  -e "s|__REPO_SH__|$(sed_escape_replacement "$REPO_SH")|g" \
  -e "s|__REF_SH__|$(sed_escape_replacement "$REF_SH")|g" \
  "$TEMPLATE" |
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "__WORKSPACE_EXPORTS__" ]]; then
      printf '%s' "$WORKSPACE_EXPORTS"
    else
      printf '%s\n' "$line"
    fi
  done
