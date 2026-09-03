# Give every concurrent Claude session its own iTerm2 colour, so sessions are
# distinguishable at a glance in a terminal and in the /resume picker.
#
# The colour is chosen at launch rather than assigned: the pool is listed with
# the colours other live shells already hold marked, and the pick is applied to
# this tab before claude starts. The shell's own claim is offered as the default,
# so relaunching in a tab keeps its identity instead of consuming a new colour.
#
# The matching swatch is appended to the session name because escape-sequence
# colours never reach the mobile app, while the name does.
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
    local -A swatch=(Umber 🟫 "Deep Sea" 🟦 Aubergine 🟪 Fern 🟩 Garnet 🟥 Sage 🟨)
    local -a held          # parallel to pool; set when another live shell holds it
    local pick owner cand default reply rows left right i j

    for (( i = 1; i <= $#pool; i++ )); do
      owner=$(<$dir/${pool[i]// /_}) 2>/dev/null
      if [[ $owner == $$ ]]; then
        # kill -0 always succeeds on our own pid, so this shell's previous claim
        # has to be recognised before the liveness test, not by it.
        [[ -z $default ]] && default=$i
      elif [[ -n $owner ]] && kill -0 $owner 2>/dev/null; then
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
    if [[ -t 0 && -t 2 && " $* " != *" -p "* && " $* " != *" --print "* ]]; then
      rows=$(( ($#pool + 1) / 2 ))
      print -u2
      print -u2 "  Session colour:"
      for (( i = 1; i <= rows; i++ )); do
        j=$(( i + rows ))
        left="$i) ${swatch[$pool[i]]:-⬜} $pool[i]${held[i]:+ ·}"
        right=""
        (( j <= $#pool )) && right="$j) ${swatch[$pool[j]]:-⬜} $pool[j]${held[j]:+ ·}"
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
      (( reply > 0 )) && pick=$pool[$reply]
    fi
    # No prompt means no colour: a run we could not ask about must not claim one
    # from the pool or recolour whatever tab it happens to be attached to.

    if [[ -n $pick ]]; then
      print $$ > $dir/${pick// /_}
      # Release anything else this shell still owns, so one shell holds one colour.
      for cand in $pool; do
        [[ $cand == $pick ]] && continue
        owner=$(<$dir/${cand// /_}) 2>/dev/null
        [[ $owner == $$ ]] && rm -f $dir/${cand// /_}
      done
      printf '\033]1337;SetProfile=%s\a' "$pick"
      # Leave a user-supplied name untouched; only name the session when it has none.
      if [[ " $* " != *" -n "* && " $* " != *" --name "* ]]; then
        command claude -n "${PWD:t} ${swatch[$pick]:-⬜}" "$@"; return
      fi
    fi
  fi
  command claude "$@"
}
