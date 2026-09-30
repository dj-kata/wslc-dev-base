#!/usr/bin/env bash
set -euo pipefail

load_env_file() {
  local env_file="$1"
  if [[ -r "$env_file" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
  fi
}

load_env_file "${PWD}/.env"
load_env_file "${HOME}/.config/wslc-dev-base/env"

if ! git config --global --get user.name >/dev/null 2>&1; then
  if [[ -n "${GIT_USER_NAME:-}" ]]; then
    git config --global user.name "$GIT_USER_NAME"
  fi
fi

if ! git config --global --get user.email >/dev/null 2>&1; then
  if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
    git config --global user.email "$GIT_USER_EMAIL"
  fi
fi
