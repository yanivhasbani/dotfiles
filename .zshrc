DOTFILES_DIR="${${(%):-%x}:A:h}"

source "$DOTFILES_DIR/zshrc.d/plugins.zsh"
source "$DOTFILES_DIR/zshrc.d/prompt.zsh"
source "$DOTFILES_DIR/zshrc.d/aliases.zsh"
source "$DOTFILES_DIR/zshrc.d/git.zsh"
