# ── Git worktree helpers (~/augment bare-repo layout) ──────────

# wt <name>: create a new worktree under ~/augment/cam/<name>
wt() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: wt <name>" >&2
        return 1
    fi
    local name="$1"
    local branch="cam/$name"
    local dir="$HOME/augment/cam/$name"

    if [[ -e "$dir" ]]; then
        echo "wt: $dir already exists" >&2
        return 1
    fi

    git -C "$HOME/augment/main" fetch origin main || return 1
    mkdir -p "${dir:h}"
    git -C "$HOME/augment" worktree add "$dir" -b "$branch" origin/main || return 1
    cd "$dir"
}

# dev [name]: open/attach a tmux session with nvim (left, 65%) + auggie (right, 35%)
dev() {
    local dir="$PWD"
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        name="${dir:t}"
        name="${name//[^[:alnum:]_-]/_}"
    fi

    if ! tmux has-session -t "$name" 2>/dev/null; then
        tmux new-session -d -s "$name" -c "$dir" -n work "nvim ."
    fi
    if [[ "$(tmux list-panes -t "${name}:work" 2>/dev/null | wc -l)" -lt 2 ]]; then
        tmux split-window -h -t "${name}:work" -l 28% -c "$dir" \
            "auggie; echo; echo '[auggie exited — press enter to close]'; read"
    fi
    tmux select-pane -t "${name}:work" -L

    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$name"
    else
        tmux attach -t "$name"
    fi
}

# pr-review <pr>: fetch PR, open tmux session with nvim+diffview + auggie
pr-review() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: pr-review <pr-number>" >&2
        return 1
    fi
    local pr="$1"
    local dir="$HOME/augment/pr-$pr"
    local ref="pr-$pr"
    local session="pr-$pr"

    local json
    json="$(gh -R augmentcode/augment pr view "$pr" --json baseRefName,title 2>/dev/null)"
    if [[ -z "$json" ]]; then
        echo "pr-review: failed to fetch PR #$pr" >&2
        return 1
    fi
    local base
    base="$(echo "$json" | jq -r .baseRefName)"

    git -C "$HOME/augment/.bare" fetch origin || return 1

    if [[ ! -d "$dir" ]]; then
        # Safe to update the local ref since nothing has it checked out
        git -C "$HOME/augment/.bare" fetch -f origin "pull/$pr/head:$ref" || return 1
        git -C "$HOME/augment" worktree add "$dir" "$ref" || return 1
    else
        # Worktree has $ref checked out — fetch into FETCH_HEAD and reset in place
        git -C "$dir" fetch origin "pull/$pr/head" || return 1
        git -C "$dir" reset --hard FETCH_HEAD || return 1
    fi

    if ! tmux has-session -t "$session" 2>/dev/null; then
        tmux new-session -d -s "$session" -c "$dir" -n review \
            "nvim -c 'DiffviewOpen origin/$base...HEAD' ."
    fi
    if [[ "$(tmux list-panes -t "${session}:review" 2>/dev/null | wc -l)" -lt 2 ]]; then
        tmux split-window -h -t "${session}:review" -l 28% -c "$dir" \
            "auggie; echo; echo '[auggie exited — press enter to close]'; read"
    fi
    tmux select-pane -t "${session}:review" -L

    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$session"
    else
        tmux attach -t "$session"
    fi
}

# wt-rm [--force] <name>: remove worktree, its branch, and its tmux session
wt-rm() {
    local force=0
    local args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force) force=1; shift ;;
            --)         shift; args+=("$@"); break ;;
            *)          args+=("$1"); shift ;;
        esac
    done

    if [[ ${#args[@]} -lt 1 ]]; then
        echo "Usage: wt-rm [--force] <name>" >&2
        return 1
    fi
    local name="${args[1]}"

    local dir=""
    for candidate in "$HOME/augment/cam/$name" "$HOME/augment/$name"; do
        if [[ -d "$candidate" ]]; then dir="$candidate"; break; fi
    done
    if [[ -z "$dir" ]]; then
        echo "wt-rm: no worktree found for '$name'" >&2
        return 1
    fi

    local branch
    branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD)"
    local is_pr=0
    [[ "$dir" == "$HOME/augment/pr-"* ]] && is_pr=1

    if [[ $force -eq 0 ]]; then
        if [[ -n "$(git -C "$dir" status --porcelain)" ]]; then
            echo "wt-rm: $dir has uncommitted changes (use --force)" >&2
            return 1
        fi
        if [[ $is_pr -eq 0 && "$branch" != "HEAD" ]]; then
            local base="origin/$branch"
            git -C "$dir" rev-parse --verify --quiet "$base" >/dev/null 2>&1 || base="origin/main"
            local ahead
            ahead="$(git -C "$dir" rev-list --count "$base..HEAD" 2>/dev/null)"
            if [[ -n "$ahead" && "$ahead" != "0" ]]; then
                echo "wt-rm: branch '$branch' has $ahead commit(s) not in $base (use --force)" >&2
                return 1
            fi
        fi
    fi

    [[ "$PWD" == "$dir"* ]] && cd ~

    # Bazel keys its output base on md5(workspace_path). Shut down any
    # server for this worktree, then nuke its output base.
    local hash
    hash="$(printf '%s' "$dir" | md5sum | awk '{print $1}')"
    local outbase="$HOME/.cache/bazel/_bazel_$(whoami)/$hash"
    if [[ -d "$outbase" ]]; then
        (cd "$dir" && bazel shutdown) >/dev/null 2>&1
        chmod -R u+w "$outbase" 2>/dev/null
        rm -rf "$outbase"
    fi

    if [[ $force -eq 1 ]]; then
        git -C "$HOME/augment" worktree remove --force "$dir" || return 1
    else
        git -C "$HOME/augment" worktree remove "$dir" || return 1
    fi
    [[ "$branch" != "HEAD" ]] && git -C "$HOME/augment" branch -D "$branch" >/dev/null 2>&1
    tmux kill-session -t "$name" 2>/dev/null
    echo "wt-rm: removed $dir (branch $branch, session $name)"
}
