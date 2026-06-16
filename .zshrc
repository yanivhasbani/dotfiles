# ZSH

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh


_configure_terminal_format_and_colors() {
	# Terminal cmd colors and format

	# Add Version Control System info
	autoload -Uz vcs_info
	precmd() { vcs_info }

	zstyle ':vcs_info:git:*' formats '%F{magenta}git:(%f%F{red}%b%f%F{magenta})%f '
	setopt PROMPT_SUBST

	_prompt_icon() {
		[[ -n "${vcs_info_msg_0_}" ]] && echo -n '🔨' || echo -n '📁'
	}

	PROMPT='😈 %F{green}%*%f %F{123}%~%f ${vcs_info_msg_0_}$(_prompt_icon) '
}

_configure_terminal_format_and_colors


alias reload='source ~/.zshrc'
alias ls='ls -laG'
alias rc='subl ~/.zshrc'

# Git

alias gl='git log --oneline --decorate --graph'
alias gs='git status'
alias gb='git branch'
alias gclone='git clone --recursive'

