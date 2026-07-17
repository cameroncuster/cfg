# ── Completion system ─────────────────────────────────────────
autoload -Uz compinit && compinit

# ── fzf configuration ───────────────────────────────────────────
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

# ── fzf shell integration ───────────────────────────────────────
# Must be sourced BEFORE fzf-tab, because fzf's completion widget
# rebinds ^I (TAB) and would otherwise clobber fzf-tab.
if command -v fzf >/dev/null 2>&1; then
    for _fzf in /opt/homebrew/opt/fzf /usr/local/opt/fzf \
        "${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}/opt/fzf"; do
        if [[ -r $_fzf/shell/completion.zsh && -r $_fzf/shell/key-bindings.zsh ]]; then
            source "$_fzf/shell/completion.zsh" 2>/dev/null
            source "$_fzf/shell/key-bindings.zsh" 2>/dev/null
            break
        fi
    done
    unset _fzf

    # Fall back to fzf's built-in loader (fzf >= 0.48) when no static
    # install path matched (e.g. Linux boxes with a bare fzf binary).
    (( $+widgets[fzf-cd-widget] )) || source <(fzf --zsh) 2>/dev/null

    # Only bind custom keys if fzf actually loaded the widgets.
    (( $+widgets[fzf-cd-widget] )) && bindkey '^O' fzf-cd-widget
fi

# ── fzf-tab integration ───────────────────────────────────────
# Must be loaded after compinit and after fzf's ^I binding, but before
# plugins that wrap widgets like zsh-autosuggestions or
# fast-syntax-highlighting.
for _ft in \
    /usr/local/share/zsh/plugins/fzf-tab/fzf-tab.zsh \
    /opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh \
    /opt/homebrew/share/zsh-fzf-tab/fzf-tab.plugin.zsh \
    "${HOMEBREW_PREFIX:-/home/linuxbrew/.linuxbrew}/share/fzf-tab/fzf-tab.zsh" \
    "$HOME/.local/share/fzf-tab/fzf-tab.zsh" \
    "$HOME/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.zsh"; do
    [[ -r $_ft ]] && source $_ft && break
done
unset _ft

# ── fzf-tab configuration ─────────────────────────────────────
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always --icons $realpath'
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza --color=always --icons $realpath'
zstyle ':fzf-tab:complete:eza:*' fzf-preview 'eza --color=always --icons $realpath'
zstyle ':fzf-tab:complete:cat:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath'
zstyle ':fzf-tab:complete:bat:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath'
zstyle ':fzf-tab:complete:vim:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath'
zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath'
zstyle ':fzf-tab:*' fzf-min-height 20

# ── zoxide (smarter cd) ────────────────────────────────────────
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# ── eza (modern ls) ────────────────────────────────────────────
# NOTE: pass --icons=auto (with `=`) rather than bare --icons. Bare --icons
# leaves a dangling argument in the alias, so zsh's _eza completion offers
# `always auto automatic never` instead of filenames at the trailing TAB.
alias ls='eza --color=always --icons=auto'
alias ll='eza -la --icons=auto --git'
alias la='eza -a --icons=auto'
alias lt='eza --tree --level=2 --icons=auto'

# ── grep ───────────────────────────────────────────────────────
alias grep='grep --color=auto'
