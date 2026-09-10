# Give every concurrent Claude session its own iTerm2 colour, so sessions are
# distinguishable at a glance in a terminal and in the /resume picker.
#
# A fresh interactive session picks its colour here, before claude starts — the
# one step a hook can't do, since it needs the terminal before claude takes it
# over. Everything else — applying a profile, the pool bookkeeping, the
# name<->swatch map, and recolouring a resumed session — lives in
# iterm2/session_color.sh, shared with the Claude Code SessionStart hook and the
# Pi extension (both in the yh-skills repo).
#
# Resumed sessions (-r/--resume, -c/--continue) and non-interactive runs (-p) are
# left alone here; the SessionStart hook recolours them from the swatch emoji
# carried in the session name.

CLAUDE_PROFILES_FILE="${CLAUDE_PROFILES_FILE:-$DOTFILES_DIR/iterm2/DynamicProfiles/sessions.json}"
CLAUDE_SESSION_COLORS_DIR="${CLAUDE_SESSION_COLORS_DIR:-$HOME/.claude/session-colors}"
CLAUDE_SESSION_COLOR_SH="${CLAUDE_SESSION_COLOR_SH:-$DOTFILES_DIR/iterm2/session_color.sh}"
export CLAUDE_PROFILES_FILE CLAUDE_SESSION_COLORS_DIR CLAUDE_SESSION_COLOR_SH

claude() {
  if [[ ! -x $CLAUDE_SESSION_COLOR_SH ]]; then
    command claude "$@"
    return
  fi

  local invocation=" $* "
  case $invocation in
    *" -r "* | *" --resume "* | *" -c "* | *" --continue "* | *" -p "* | *" --print "* | *" --from-pr "* | *" --teleport "*)
      command claude "$@"
      return
      ;;
  esac

  local profile
  profile=$("$CLAUDE_SESSION_COLOR_SH" pick)
  if [[ -z $profile ]]; then
    command claude "$@"
    return
  fi

  "$CLAUDE_SESSION_COLOR_SH" apply "$profile"

  # Leave a user-supplied name untouched; only name the session when it has none.
  if [[ $invocation == *" -n "* || $invocation == *" --name "* ]]; then
    command claude "$@"
  else
    command claude -n "${PWD:t} $("$CLAUDE_SESSION_COLOR_SH" swatch "$profile")" "$@"
  fi
}
