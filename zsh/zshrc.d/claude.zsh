# Give every concurrent Claude session its own iTerm2 colour, so sessions are
# distinguishable at a glance in a terminal and in the /resume picker.
#
# A profile is claimed by the shell that launches Claude and released when that
# shell exits, so colours are recycled as tabs close. The matching swatch is
# appended to the session name because escape-sequence colours never reach the
# mobile app, while the name does.
#
# The profile pool is read from the repo's own definitions rather than hardcoded,
# so this stays correct if profiles are added or renamed there. When the file is
# absent — a machine that has not linked it into iTerm2 yet — colouring is
# skipped entirely rather than selecting profiles that do not exist.

CLAUDE_PROFILES_FILE="${CLAUDE_PROFILES_FILE:-$DOTFILES_DIR/iterm2/DynamicProfiles/sessions.json}"

claude() {
  local -a pool
  if [[ $TERM_PROGRAM == iTerm.app && -r $CLAUDE_PROFILES_FILE ]]; then
    pool=(${(f)"$(sed -n 's/.*"Name": "\([^"]*\)".*/\1/p' $CLAUDE_PROFILES_FILE)"})
  fi

  if (( $#pool )); then
    local dir=$HOME/.claude/session-colors; mkdir -p $dir
    local -A swatch=(Umber 🟫 "Deep Sea" 🟦 Aubergine 🟪 Lagoon 🟩 Frost ⬜)
    local pick owner
    for cand in $pool; do
      owner=$(<$dir/${cand// /_}) 2>/dev/null
      if [[ -z $owner ]] || ! kill -0 $owner 2>/dev/null; then pick=$cand; break; fi
    done
    [[ -z $pick ]] && pick=$pool[$((RANDOM % $#pool + 1))]
    print $$ > $dir/${pick// /_}
    printf '\033]1337;SetProfile=%s\a' "$pick"
    # Leave a user-supplied name untouched; only name the session when it has none.
    if [[ " $* " != *" -n "* && " $* " != *" --name "* ]]; then
      command claude -n "${PWD:t} ${swatch[$pick]:-⬜}" "$@"; return
    fi
  fi
  command claude "$@"
}
