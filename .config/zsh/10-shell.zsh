# ── Editor ──────────────────────────────────────────────────────
export VISUAL=nvim
export EDITOR="$VISUAL"

# ── History ─────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY APPEND_HISTORY

# ── Vi mode ─────────────────────────────────────────────────────
bindkey -v
bindkey 'kj' vi-cmd-mode
export KEYTIMEOUT=20

# ── Prefix search (↑/↓ and Ctrl+P/Ctrl+N) ──────────────────────
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^P' up-line-or-beginning-search
bindkey '^N' down-line-or-beginning-search

# ── Prompt (starship) ──────────────────────────────────────────
eval "$(starship init zsh)"
