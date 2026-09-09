# Give every concurrent Claude session its own iTerm2 colour, so sessions are
# distinguishable at a glance in a terminal and in the /resume picker.
#
# A fresh session picks its colour at launch: the pool is listed with the colours
# other live shells already hold marked, and the pick is applied to this tab
# before claude starts. The shell's own claim is offered as the default, so
# relaunching in a tab keeps its identity instead of consuming a new colour.
#
# A resumed session (-r/--resume, -c/--continue) is never asked and never renamed.
# Its colour is already carried by the session name — the swatch emoji is appended
# there because escape-sequence colours never reach the mobile app — so the stored
# name is read back and the matching profile reapplied silently. When the session
# id resolves to no stored name, the tab keeps whatever colour it has.
#
# The profile pool is read from the repo's own definitions rather than hardcoded,
# so this stays correct if profiles are added or renamed there. When the file is
# absent — a machine that has not linked it into iTerm2 yet — colouring is
# skipped entirely rather than selecting profiles that do not exist.

CLAUDE_PROFILES_FILE="${CLAUDE_PROFILES_FILE:-$DOTFILES_DIR/iterm2/DynamicProfiles/sessions.json}"
CLAUDE_SESSION_COLORS_DIR="${CLAUDE_SESSION_COLORS_DIR:-$HOME/.claude/session-colors}"
CLAUDE_SESSIONS_DIR="${CLAUDE_SESSIONS_DIR:-$HOME/.claude/sessions}"
CLAUDE_HISTORY_FILE="${CLAUDE_HISTORY_FILE:-$HOME/.claude/history.jsonl}"

typeset -gA CLAUDE_PROFILE_SWATCH=(
  Umber 🟫 "Deep Sea" 🟦 Aubergine 🟪 Fern 🟩 Garnet 🟥 Sage 🟨
)

# Profile names in picker order; empty when this terminal cannot colour sessions.
_claude_profile_pool() {
  [[ $TERM_PROGRAM == iTerm.app && -r $CLAUDE_PROFILES_FILE ]] || return
  sed -n 's/.*"Name": "\([^"]*\)".*/\1/p' "$CLAUDE_PROFILES_FILE"
}

# Select this tab's profile and record the claim, releasing any the shell held.
_claude_apply_profile() {
  local profile=$1 dir=$CLAUDE_SESSION_COLORS_DIR other owner

  printf '\033]1337;SetProfile=%s\a' "$profile"

  mkdir -p "$dir"
  print $$ > "$dir/${profile// /_}"
  for other in ${(f)"$(_claude_profile_pool)"}; do
    [[ $other == $profile ]] && continue
    owner=$(<"$dir/${other// /_}") 2>/dev/null
    [[ $owner == $$ ]] && rm -f "$dir/${other// /_}"
  done
}

# Prompt for a colour, echoing the chosen profile name (empty = keep none).
# UI goes to stderr; only the pick reaches stdout, so the caller can capture it.
_claude_pick_profile() {
  local -a pool held
  pool=(${(f)"$(_claude_profile_pool)"})
  (( $#pool )) || return

  local dir=$CLAUDE_SESSION_COLORS_DIR owner default reply rows left right i j
  for (( i = 1; i <= $#pool; i++ )); do
    owner=$(<"$dir/${pool[i]// /_}") 2>/dev/null
    if [[ $owner == $$ ]]; then
      # kill -0 always succeeds on our own pid, so this shell's previous claim
      # has to be recognised before the liveness test, not by it.
      [[ -z $default ]] && default=$i
    elif [[ -n $owner ]] && kill -0 "$owner" 2>/dev/null; then
      held[i]=x
    fi
  done
  if [[ -z $default ]]; then
    for (( i = 1; i <= $#pool; i++ )); do
      [[ -z $held[i] ]] && { default=$i; break }
    done
  fi
  : ${default:=1}

  # Only ask when a person is there to answer. claude also runs from scripts,
  # hooks and `claude -p`, where a prompt would hang or land in captured output.
  [[ -t 0 && -t 2 && " $* " != *" -p "* && " $* " != *" --print "* ]] || return

  rows=$(( ($#pool + 1) / 2 ))
  print -u2
  print -u2 "  Session colour:"
  for (( i = 1; i <= rows; i++ )); do
    j=$(( i + rows ))
    left="$i) ${CLAUDE_PROFILE_SWATCH[$pool[i]]:-⬜} $pool[i]${held[i]:+ ·}"
    right=""
    (( j <= $#pool )) && right="$j) ${CLAUDE_PROFILE_SWATCH[$pool[j]]:-⬜} $pool[j]${held[j]:+ ·}"
    printf '    %-22s %s\n' "$left" "$right" >&2
  done
  print -u2 "    · = already in use, 0 = no colour"
  while true; do
    print -u2 -n "  > [$default] "
    read -r reply || { reply=$default; print -u2 }
    [[ -z $reply ]] && reply=$default
    [[ $reply == (q|Q) ]] && reply=0
    if [[ $reply == <-> ]] && (( reply >= 0 && reply <= $#pool )); then break; fi
    print -u2 "    pick 1-$#pool, or 0 for no colour"
  done
  (( reply > 0 )) && print -r -- "$pool[$reply]"
}

# The resume target in "$@": a session id, "@latest" for -c/--continue,
# "@skip" when resuming without a resolvable id, empty for a fresh session.
_claude_resume_target() {
  local -a argv=("$@")
  local next i
  for (( i = 1; i <= $#argv; i++ )); do
    case $argv[i] in
      -r|--resume)
        next=$argv[i+1]
        [[ -n $next && $next != -* ]] && { print -r -- "$next"; return }
        print -r -- @skip; return ;;
      -c|--continue)
        print -r -- @latest; return ;;
      --from-pr|--teleport)
        print -r -- @skip; return ;;
    esac
  done
}

# Concrete session id for a resume target; empty when it cannot be resolved.
_claude_resume_session_id() {
  local target=$1 line

  case $target in
    @skip) return ;;
    @latest)
      [[ -r $CLAUDE_HISTORY_FILE ]] || return
      line=$(grep -F "\"project\":\"$PWD\"" "$CLAUDE_HISTORY_FILE" | tail -1)
      [[ -n $line ]] || return
      print -r -- "${${line##*\"sessionId\":\"}%%\"*}" ;;
    *) print -r -- "$target" ;;
  esac
}

# The profile a stored session was launched with, read from its name's swatch.
_claude_profile_for_session() {
  local session_id=$1 name profile emoji
  local -a files

  [[ -n $session_id && -d $CLAUDE_SESSIONS_DIR ]] || return
  files=("$CLAUDE_SESSIONS_DIR"/*.json(N))
  (( $#files )) || return

  local file
  file=$(grep -l "\"sessionId\":\"$session_id\"" "${files[@]}" 2>/dev/null | head -1)
  [[ -n $file ]] || return
  name=$(plutil -extract name raw -o - "$file" 2>/dev/null)
  [[ -n $name ]] || return

  for profile in ${(k)CLAUDE_PROFILE_SWATCH}; do
    emoji=$CLAUDE_PROFILE_SWATCH[$profile]
    [[ $name == *$emoji* ]] && { print -r -- "$profile"; return }
  done
}

claude() {
  if [[ -z "$(_claude_profile_pool)" ]]; then
    command claude "$@"
    return
  fi

  local resume_target
  resume_target=$(_claude_resume_target "$@")
  if [[ -n $resume_target ]]; then
    if [[ -t 1 && " $* " != *" -p "* && " $* " != *" --print "* ]]; then
      local resumed_profile
      resumed_profile=$(_claude_profile_for_session "$(_claude_resume_session_id "$resume_target")")
      [[ -n $resumed_profile ]] && _claude_apply_profile "$resumed_profile"
    fi
    command claude "$@"
    return
  fi

  local pick
  pick=$(_claude_pick_profile "$@")
  # No pick means no colour: a run we could not ask about must not claim one
  # from the pool or recolour whatever tab it happens to be attached to.
  if [[ -n $pick ]]; then
    _claude_apply_profile "$pick"
    # Leave a user-supplied name untouched; only name the session when it has none.
    if [[ " $* " != *" -n "* && " $* " != *" --name "* ]]; then
      command claude -n "${PWD:t} ${CLAUDE_PROFILE_SWATCH[$pick]:-⬜}" "$@"
      return
    fi
  fi

  command claude "$@"
}
