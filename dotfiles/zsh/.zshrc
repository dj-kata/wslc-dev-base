# Common interactive zsh setup for wslc-dev-base.

export LANG="${LANG:-C.UTF-8}"
export LC_ALL="${LC_ALL:-C.UTF-8}"
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export LESS="${LESS:--FRX}"

HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt append_history
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt inc_append_history

autoload -Uz compinit
compinit
zstyle ":completion:*" menu select
zstyle ":completion:*" matcher-list "m:{a-zA-Z}={A-Za-z}"

if [ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi
if [ -r /usr/share/doc/fzf/examples/completion.zsh ]; then
  source /usr/share/doc/fzf/examples/completion.zsh
fi

if command -v fzf >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/*' 2>/dev/null"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

alias ll="eza -al --group-directories-first --git"
alias la="eza -a --group-directories-first"
alias lt="eza --tree --level=2 --group-directories-first"
alias cat="bat"
alias grep="rg"
alias gst="git status --short --branch"
alias gl="git log --oneline --decorate --graph --all"
alias gd="git diff"
alias gds="git diff --staged"
alias gc="git commit"
alias gco="git checkout"
alias gb="git branch"

if [ -r /usr/share/zsh/plugins/git/git.plugin.zsh ]; then
  source /usr/share/zsh/plugins/git/git.plugin.zsh
fi

# Optional personal environment. This file is intentionally ignored by Git.
for env_file in "$PWD/.env" "$HOME/.config/wslc-dev-base/env"; do
  if [ -r "$env_file" ]; then
    set -a
    source "$env_file"
    set +a
  fi
done

if command -v setup-git-identity >/dev/null 2>&1; then
  setup-git-identity >/dev/null 2>&1 || true
fi
