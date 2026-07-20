# ── theme: palette switcher for kitty + nvim ──────────────────
# kitty.conf includes theme.conf, a machine-local symlink (untracked) to one
# of the theme-<name>.conf palettes in ~/cfg. nvim reads the same symlink
# (startup + FocusGained in ui.lua), so the two always agree.

# default to hacker on machines where the symlink doesn't exist yet
# (skip on boxes without kitty, e.g. headless remotes)
[[ -d "$HOME/.config/kitty" && ! -e "$HOME/.config/kitty/theme.conf" ]] &&
    ln -sf "$HOME/cfg/.config/kitty/theme-hacker.conf" "$HOME/.config/kitty/theme.conf"

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
