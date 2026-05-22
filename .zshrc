# Augment dev environment — modular config.
# All real config lives in ~/.config/zsh/*.zsh, sourced in numeric order.
# Add machine-local overrides (uncommitted) to ~/.zshrc.local.

for f in "$HOME"/.config/zsh/[0-9]*.zsh; do
    [[ -r "$f" ]] && source "$f"
done

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
