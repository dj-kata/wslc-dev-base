#!/usr/bin/env bash
set -euo pipefail

find_dotfiles_dir() {
  for dir in \
    "${PWD}/dotfiles" \
    "/workspaces/wslc-dev-base/dotfiles" \
    "/workspace/dotfiles" \
    "/usr/local/share/wslc-dev-base/dotfiles"
  do
    if [[ -d "$dir" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
  done
  return 1
}

dotfiles_dir="$(find_dotfiles_dir || true)"
if [[ -z "${dotfiles_dir}" ]]; then
  echo "install-dotfiles: dotfiles directory not found" >&2
  exit 0
fi

install_file() {
  local src="$1"
  local dst="$2"
  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
  fi
}

install_file "${dotfiles_dir}/zsh/.zshrc" "${HOME}/.zshrc"
install_file "${dotfiles_dir}/tmux/.tmux.conf" "${HOME}/.tmux.conf"
