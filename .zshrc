DOTFILES_DIR="${${(%):-%x}:A:h}"

source "$DOTFILES_DIR/zsh/zshrc.d/plugins.zsh"
source "$DOTFILES_DIR/zsh/zshrc.d/prompt.zsh"
source "$DOTFILES_DIR/zsh/zshrc.d/aliases.zsh"
source "$DOTFILES_DIR/zsh/zshrc.d/git.zsh"
