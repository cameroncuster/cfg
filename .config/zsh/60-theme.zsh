# ── theme: palette switcher for kitty + nvim ──────────────────
# kitty.conf includes theme.conf, a machine-local symlink (untracked) to one
# of the theme-<name>.conf palettes in ~/cfg. nvim reads the same symlink
# (startup + FocusGained in ui.lua), so the two always agree.

# default to hacker on machines where the symlink doesn't exist yet
# (skip on boxes without kitty, e.g. headless remotes)
[[ -d "$HOME/.config/kitty" && ! -e "$HOME/.config/kitty/theme.conf" ]] &&
    ln -sf "$HOME/cfg/.config/kitty/theme-hacker.conf" "$HOME/.config/kitty/theme.conf"

# Cache of the active theme name, so headless remotes (no kitty, so no
# theme.conf) can still learn the current theme. `theme` writes it; the export
# below reads it into LC_KITTY_THEME, which ssh forwards (LC_* is in the
# server's AcceptEnv) so remote nvim can pick the matching real colorscheme.
_kitty_theme_cache="$HOME/.cache/kitty-theme"

# If a kitty theme.conf exists, trust it as the source of truth; otherwise fall
# back to the cache. Export as LC_KITTY_THEME so `SendEnv LC_KITTY_THEME` (see
# ~/.ssh/config) carries it to remotes on every new connection.
if [[ -e "$HOME/.config/kitty/theme.conf" ]]; then
    _kt_link="$(readlink "$HOME/.config/kitty/theme.conf" 2>/dev/null)"
    _kt_name="${${_kt_link:t}#theme-}"; _kt_name="${_kt_name%.conf}"
    [[ -n "$_kt_name" ]] && export LC_KITTY_THEME="$_kt_name"
elif [[ -r "$_kitty_theme_cache" ]]; then
    export LC_KITTY_THEME="$(<"$_kitty_theme_cache")"
fi
unset _kt_link _kt_name

theme() {
    local kdir="$HOME/.config/kitty" mode="$1"
    [[ -d "$kdir" ]] || { echo "theme: no kitty on this machine" >&2; return 1; }
    if [[ -z "$mode" || ! -e "$HOME/cfg/.config/kitty/theme-$mode.conf" ]]; then
        echo "usage: theme <name>  — available:" >&2
        for f in "$HOME"/cfg/.config/kitty/theme-*.conf; do
            echo "  ${${f:t}#theme-}" | sed 's/\.conf$//' >&2
        done
        return 1
    fi
    ln -sf "$HOME/cfg/.config/kitty/theme-$mode.conf" "$kdir/theme.conf"
    # record + export so new ssh sessions forward the active theme name
    mkdir -p "${_kitty_theme_cache:h}" && print -r -- "$mode" >| "$_kitty_theme_cache"
    export LC_KITTY_THEME="$mode"
    # push only the colors over each instance's remote-control socket
    # (listen_on in kitty.conf); a SIGUSR1 config reload would also reset
    # interactive font-size changes. `(N=)` = nullglob, sockets only.
    local sock
    for sock in /tmp/kitty-*(N=); do
        kitten @ --to "unix:$sock" set-colors --all --configured \
            "$kdir/theme.conf" 2>/dev/null
    done
    echo "theme: $mode"
}
