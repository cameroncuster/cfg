# ── Path & Homebrew (must be first) ─────────────────────────────
export PATH=$HOME/.npm-global/bin:$HOME/.local/bin:$PATH
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# ── nvm ─────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# ── Google Cloud SDK ────────────────────────────────────────────
[ -f '/home/ccuster/google-cloud-sdk/path.zsh.inc' ] && . '/home/ccuster/google-cloud-sdk/path.zsh.inc'
[ -f '/home/ccuster/google-cloud-sdk/completion.zsh.inc' ] && . '/home/ccuster/google-cloud-sdk/completion.zsh.inc'

# ── Augment workspace ───────────────────────────────────────────
export BUILD_USER_NAMESPACE="dev-cam"

# enable remote bazel execution (consumed by the augment repo bazel wrapper)
export BAZEL_RBE_TOKEN=1
