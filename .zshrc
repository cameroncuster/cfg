# ── Path ────────────────────────────────────────────────────────
export PATH=$HOME/.local/bin:$PATH

# ── Oh My Zsh ──────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # disabled — using starship instead
plugins=(git fzf-tab)
source $ZSH/oh-my-zsh.sh

# ── History ─────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY APPEND_HISTORY

# ── fzf-tab previews ───────────────────────────────────────────
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always --icons $realpath'
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza --color=always --icons $realpath'
zstyle ':fzf-tab:complete:cat:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath'
zstyle ':fzf-tab:complete:bat:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath'
zstyle ':fzf-tab:complete:vim:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath'
zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath'
zstyle ':fzf-tab:*' fzf-min-height 20

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

# ── Editor ──────────────────────────────────────────────────────
export VISUAL=vim
export EDITOR="$VISUAL"

# ── Prompt (starship) ──────────────────────────────────────────
eval "$(starship init zsh)"

# ── SSH ─────────────────────────────────────────────────────────
# Run `ssh-add` to add your key and identity for ForwardAgent to work.
if [[ -z $(ssh-add -L) ]]
then
  ssh-add ~/.ssh/id_github
fi

# ── Google Cloud SDK ────────────────────────────────────────────
source "/Applications/google-cloud-sdk/path.zsh.inc"
source "/Applications/google-cloud-sdk/completion.zsh.inc"

# ── fzf ─────────────────────────────────────────────────────────
eval "$(fzf --zsh)"

bindkey '^O' fzf-cd-widget

export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'

export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border --info=inline"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"

_fzf_compgen_path() {
  fd --hidden --no-follow --exclude .git . "$1"
}

_fzf_compgen_dir() {
  fd --type d --hidden --no-follow --exclude .git . "$1"
}

# ── zoxide (smarter cd) ────────────────────────────────────────
eval "$(zoxide init zsh)"

# ── eza (modern ls) ────────────────────────────────────────────
alias ls='eza --color=always --icons'
alias ll='eza -la --icons --git'
alias la='eza -a --icons'
alias lt='eza --tree --level=2 --icons'

# ── grep ────────────────────────────────────────────────────────
alias grep='grep --color=auto'
