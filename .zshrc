# Resolve the dotfiles repo root, even when ~/.zshrc is a symlink.
# (%) enables prompt expansion; %x expands to the path of this file (like __file__ in Python).
# ${(%):-...} uses the default-value operator to evaluate %x as a prompt escape inside ${...}.
# :A resolves symlinks to an absolute real path.
# :h strips the filename, returning the parent directory.
DOTFILES_DIR="${${(%):-%x}:A:h}"
BIN_DIR="$HOME/.bin"
export PATH="$BIN_DIR:$PATH"

source "$DOTFILES_DIR/zsh/zshrc.d/prompt.zsh"
source "$DOTFILES_DIR/zsh/zshrc.d/aliases.zsh"
source "$DOTFILES_DIR/zsh/zshrc.d/git.zsh"
source "$DOTFILES_DIR/zsh/zshrc.d/iterm2.zsh"
source "$DOTFILES_DIR/zsh/zshrc.d/claude.zsh"
