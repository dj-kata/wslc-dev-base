#!/usr/bin/env bash
set -euo pipefail

codex_home=/home/vscode/.codex
host_codex_home=/mnt/host-codex

copy_if_exists() {
  local src="$1"
  local dst="$2"
  if [[ -e "$src" ]]; then
    cp -a "$src" "$dst"
  fi
}

if [[ -d /home/vscode ]]; then
  mkdir -p "$codex_home"

  # Keep CODEX_HOME on a Linux volume for SQLite/runtime state, but seed user
  # config/auth from the host Codex home when it is mounted read-only.
  if [[ -d "$host_codex_home" ]]; then
    shopt -s nullglob
    for file in "$host_codex_home"/config.toml "$host_codex_home"/*.config.toml "$host_codex_home"/auth.json "$host_codex_home"/hooks.json; do
      copy_if_exists "$file" "$codex_home/"
    done
    for dir in "$host_codex_home"/rules "$host_codex_home"/skills; do
      copy_if_exists "$dir" "$codex_home/"
    done
    shopt -u nullglob
  fi

  chown -R vscode:vscode "$codex_home" || true

  if [[ -d /home/vscode/.ssh ]]; then
    chown -R vscode:vscode /home/vscode/.ssh || true
    chmod 0700 /home/vscode/.ssh || true
    find /home/vscode/.ssh -type f -name 'known_hosts*' -exec chmod 0644 {} + 2>/dev/null || true
    find /home/vscode/.ssh -type f -name '*.pub' -exec chmod 0644 {} + 2>/dev/null || true
    find /home/vscode/.ssh -type f ! -name '*.pub' ! -name 'known_hosts*' ! -name 'config' -exec chmod 0600 {} + 2>/dev/null || true
    [[ -f /home/vscode/.ssh/config ]] && chmod 0600 /home/vscode/.ssh/config || true
  fi
fi

exec "$@"
