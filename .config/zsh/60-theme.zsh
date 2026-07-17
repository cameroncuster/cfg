# ── theme: palette switcher for kitty + nvim ──────────────────
# kitty.conf includes theme.conf, a machine-local symlink (untracked) to one
# of the theme-<name>.conf palettes in ~/cfg. nvim reads the same symlink
# (startup + FocusGained in ui.lua), so the two always agree.

# default to dark on machines where the symlink doesn't exist yet
# (skip on boxes without kitty, e.g. headless remotes)
[[ -d "$HOME/.config/kitty" && ! -e "$HOME/.config/kitty/theme.conf" ]] &&
    ln -sf "$HOME/cfg/.config/kitty/theme-dark.conf" "$HOME/.config/kitty/theme.conf"

theme() {
    local kdir="$HOME/.config/kitty" mode="$1"
    [[ -d "$kdir" ]] || { echo "theme: no kitty on this machine" >&2; return 1; }
    case "$mode" in
        "")  # no arg: toggle to the default of the other mode
            # light themes have a light background (#dxxxxx-#fxxxxx range)
            if grep -q '^background #[d-f]' "$kdir/theme.conf" 2>/dev/null; then
                mode=dark
            else
                mode=light
            fi ;;
        *)
            if [[ ! -e "$HOME/cfg/.config/kitty/theme-$mode.conf" ]]; then
                echo "usage: theme [name]  — available:" >&2
                for f in "$HOME"/cfg/.config/kitty/theme-*.conf; do
                    echo "  ${${f:t}#theme-}" | sed 's/\.conf$//' >&2
                done
                return 1
            fi ;;
    esac
    ln -sf "$HOME/cfg/.config/kitty/theme-$mode.conf" "$kdir/theme.conf"
    # SIGUSR1 makes kitty reload its config. pgrep/pkill can't find kitty on
    # macOS (comm is the path truncated to 16 chars: "/Applications/ki"), so
    # use $KITTY_PID, falling back to ps for shells outside kitty.
    local pids="${KITTY_PID:-$(ps -eo pid,command | awk '$2 ~ /MacOS\/kitty$/ {print $1}')}"
    [[ -n "$pids" ]] && kill -USR1 $=pids 2>/dev/null
    echo "theme: $mode"
}
