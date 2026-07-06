_configure_terminal_format_and_colors() {
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
