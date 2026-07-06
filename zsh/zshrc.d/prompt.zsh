_configure_terminal_format_and_colors() {
	# relays on setup_mac_env repo to pre-install autosuggest/complete
	source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
	source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh

	autoload -Uz vcs_info
	precmd() { vcs_info }

	zstyle ':vcs_info:git:*' formats '%F{magenta}git:(%f%F{red}%b%f%F{magenta})%f '
	setopt PROMPT_SUBST

	_prompt_icon() {
		[[ -n "${vcs_info_msg_0_}" ]] && echo -n '🔨' || echo -n '📁'
	}

	PROMPT='😈 %F{green}%*%f %F{123}%~%f ${vcs_info_msg_0_}$(_prompt_icon) '

	export LS_COLORS="di=36:ex=38;5;166:ln=36:pi=33:so=35:bd=34;46:cd=34;43"
	export LSCOLORS="gxfxcxdxbxegedabagacad"
}

_configure_terminal_format_and_colors
