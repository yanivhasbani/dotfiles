alias gl='git log --oneline --decorate --graph'
alias gs='git status'
alias gb='git branch'
alias gd='git difftool'
alias gc='git checkout'
alias gclone='git clone --recursive'

_git_unstaged_files() {
	git status --porcelain | grep -E '^(\?\?| [MADRCU])' | cut -c4-
}

_git_stage_files_interactively() {
	_staged_files=()
	for file in "$@"; do
		read -r "answer?Add '$file'? [y/n] "
		if [[ "$answer" =~ ^[Yy]$ ]]; then
			git add "$file"
			_staged_files+=("$file")
		fi
	done
}

_git_infer_module_name() {
	local dirs=()
	for f in "$@"; do
		local dir=$(dirname "$f")
		local top_dir="${dir%%/*}"
		[[ "$top_dir" != "." ]] && dirs+=("$top_dir")
	done

	if [[ ${#dirs[@]} -gt 0 ]]; then
		printf '%s\n' "${dirs[@]}" | sort | uniq -c | sort -rn | awk 'NR==1{print $2}'
	else
		basename "$(git rev-parse --show-toplevel)"
	fi
}

_git_prompt_commit_message() {
	local module_name="$1"; shift
	local tmpfile=$(mktemp /tmp/commit_msg_XXXXXX)

	{
		echo "${module_name}: add"
		echo ""
		echo "# Files to be committed:"
		printf '#   %s\n' "$@"
		echo "# Lines starting with '#' will be ignored."
	} > "$tmpfile"

	subl --wait "$tmpfile"

	grep -v '^#' "$tmpfile" | sed '/^[[:space:]]*$/d'
	rm -f "$tmpfile"
}


add_and_commit() {
	if ! git rev-parse --git-dir &>/dev/null 2>&1; then
		echo "Not a git repository."
		return 1
	fi

	local unstaged_files=("${(@f)$(_git_unstaged_files)}")
	if [[ ${#unstaged_files[@]} -eq 0 ]]; then
		echo "No unstaged files found."
		return 0
	fi

	_git_stage_files_interactively "${unstaged_files[@]}"
	local staged_files=("${_staged_files[@]}")
	if [[ ${#staged_files[@]} -eq 0 ]]; then
		echo "No files staged. Aborting."
		return 0
	fi

	local module_name=$(_git_infer_module_name "${staged_files[@]}")
	local commit_msg=$(_git_prompt_commit_message "$module_name" "${staged_files[@]}")
	if [[ -z "$commit_msg" ]]; then
		echo "Empty commit message. Aborting."
		return 1
	fi

	git commit -m "$commit_msg"
}
