# ── theme: palette switcher for kitty + nvim ──────────────────
# kitty.conf includes theme.conf, a machine-local symlink (untracked) to one
# of the theme-<name>.conf palettes in ~/cfg. nvim reads the same symlink
# (startup + FocusGained in ui.lua), so the two always agree.

# default to hacker on machines where the symlink doesn't exist yet
# (skip on boxes without kitty, e.g. headless remotes)
[[ -d "$HOME/.config/kitty" && ! -e "$HOME/.config/kitty/theme.conf" ]] &&
    ln -sf "$HOME/cfg/.config/kitty/theme-hacker.conf" "$HOME/.config/kitty/theme.conf"

# Cache of the active theme name (~/.cache/kitty-theme). Every machine reads it
# on shell startup into LC_KITTY_THEME, which nvim's ui.lua uses to pick the
# colorscheme. On kitty boxes `theme` writes it locally AND pushes it to the
# headless remotes below (which have no kitty, so no theme.conf to read); on
# those remotes the file is the only source of truth, so nvim matches the local
# theme. File-based (not ssh env forwarding) to survive tmux/ControlMaster.
_kitty_theme_cache="$HOME/.cache/kitty-theme"

# hosts to keep in sync with the local theme (best-effort, reuse ssh sockets)
_kitty_theme_hosts=(cam-homepod)

# Seed LC_KITTY_THEME for this shell: prefer the live kitty symlink, else the
# cache file (the remote path).
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
    # record locally so new shells here pick it up
    mkdir -p "${_kitty_theme_cache:h}" && print -r -- "$mode" >| "$_kitty_theme_cache"
    export LC_KITTY_THEME="$mode"
    # push the name to headless remotes so their nvim matches. Best-effort and
    # backgrounded: reuse the existing ssh control socket, never block the
    # prompt, stay silent if a host is unreachable. New remote shells/panes read
    # ~/.cache/kitty-theme on startup (see above), so this "just works" there.
    local _h
    for _h in $_kitty_theme_hosts; do
        ( ssh -o BatchMode=yes -o ConnectTimeout=2 "$_h" \
            "mkdir -p ~/.cache && printf '%s\n' ${(q)mode} > ~/.cache/kitty-theme" \
            >/dev/null 2>&1 & ) 2>/dev/null
    done
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
