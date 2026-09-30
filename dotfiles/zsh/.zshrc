# Common interactive zsh setup for wslc-dev-base.

# Locale / editor -------------------------------------------------------------
if locale -a 2>/dev/null | grep -qi '^ja_JP\.utf8$'; then
  export LANG=ja_JP.UTF-8
  export LC_ALL=ja_JP.UTF-8
else
  export LANG=${LANG:-C.UTF-8}
  export LC_ALL=${LC_ALL:-C.UTF-8}
fi

export EDITOR=${EDITOR:-vim}
export VISUAL=${VISUAL:-$EDITOR}
export PAGER=${PAGER:-less}
export LESS=${LESS:--FRX}
export PATH="$HOME/.local/bin:$PATH"

# History ---------------------------------------------------------------------
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt append_history
setopt inc_append_history
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks

# Shell behavior --------------------------------------------------------------
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt prompt_subst

# Completion ------------------------------------------------------------------
autoload -Uz compinit
compinit -u
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
if [[ -n "${LS_COLORS:-}" ]]; then
  zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
fi

# fzf -------------------------------------------------------------------------
if command -v fzf >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/*' 2>/dev/null"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_DEFAULT_OPTS=${FZF_DEFAULT_OPTS:-'--height 40% --layout=reverse --border'}

  # Ubuntu/Debian fzf packages have used a few different install paths.
  for fzf_bindings in \
    /usr/share/doc/fzf/examples/key-bindings.zsh \
    /usr/share/fzf/key-bindings.zsh \
    /usr/share/fzf/shell/key-bindings.zsh \
    "$HOME/.fzf/shell/key-bindings.zsh" \
    "$HOME/.fzf.zsh"
  do
    if [[ -r "$fzf_bindings" ]]; then
      source "$fzf_bindings"
      break
    fi
  done

  for fzf_completion in \
    /usr/share/doc/fzf/examples/completion.zsh \
    /usr/share/fzf/completion.zsh \
    /usr/share/fzf/shell/completion.zsh \
    "$HOME/.fzf/shell/completion.zsh"
  do
    if [[ -r "$fzf_completion" ]]; then
      source "$fzf_completion"
      break
    fi
  done

  if ! bindkey '^R' 2>/dev/null | grep -q fzf; then
    fzf-history-widget() {
      local selected fzf_status
      selected=$(fc -rl 1 | awk '{$1=""; sub(/^ +/, ""); if (!seen[$0]++) print}' | fzf --query "$LBUFFER" --tac +s)
      fzf_status=$?
      zle reset-prompt
      zle -R
      (( fzf_status == 0 )) || return $fzf_status
      LBUFFER=$selected
      zle reset-prompt
      zle -R
    }
    zle -N fzf-history-widget
    bindkey '^R' fzf-history-widget
  fi
fi

# Prompt ----------------------------------------------------------------------
PROMPT=$'%{\e[1;31m%}%n@%m%{\e[0m%} %# '
RPROMPT=$'%{\e[1;93m%}[%~]%{\e[0m%}'

# Aliases ---------------------------------------------------------------------
alias l='ls -a'
alias ll='eza -al --group-directories-first --git'
alias la='eza -a --group-directories-first'
alias lt='eza --tree --level=2 --group-directories-first'
alias ls='ls --color=auto -F'
alias grep='grep --color=auto -n'
alias cat='bat'
alias less='less -R'
alias cp='cp -p'

alias gst='git status --short --branch'
alias gl='git log --oneline --decorate --graph --all'
alias gd='git diff'
alias gds='git diff --staged'
alias gc='git commit'
alias gco='git checkout'
alias gb='git branch'

alias -g L='| less'
alias -g H='| head'
alias -g T='| tail'

# Optional personal/local config ---------------------------------------------
# Put machine-specific paths, tokens, SDK managers, ssh-agent/keychain setup,
# Windows integration aliases, and project aliases in these ignored files.
for local_zsh in \
  "$HOME/.config/wslc-dev-base/zshrc.local" \
  "$HOME/.zshrc.local"
do
  [[ -r "$local_zsh" ]] && source "$local_zsh"
done

# Optional personal environment. This file is intentionally ignored by Git.
for env_file in "$PWD/.env" "$HOME/.config/wslc-dev-base/env"; do
  if [[ -r "$env_file" ]]; then
    set -a
    source "$env_file"
    set +a
  fi
done

if command -v setup-git-identity >/dev/null 2>&1; then
  setup-git-identity >/dev/null 2>&1 || true
fi
