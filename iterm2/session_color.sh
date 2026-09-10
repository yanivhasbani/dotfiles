#!/usr/bin/env bash
#
# The colour engine behind per-session iTerm2 profiles. Each agent integration is
# a thin adapter over these subcommands: the claude() shell wrapper, the Claude
# Code SessionStart hook, and the Pi extension all call in here.
#
#   session_color.sh pool [--held]        profile names, one per line; --held appends
#                                         a tab + HELD when a live session holds one
#   session_color.sh pick                 prompt on the tty, echo the chosen profile
#                                         ("" = declined / not a tty)
#   session_color.sh apply <profile>      switch this terminal to <profile>, record the claim
#   session_color.sh swatch <profile>     echo the profile's swatch emoji
#   session_color.sh apply-for-title <s>  switch to the profile whose swatch appears in <s>
#
# Colouring is skipped (exit 0, no output) unless this is iTerm2 with readable
# profile definitions, so adapters may call it unconditionally.
#
# The claim recorded by `apply`/`pick` is keyed by the caller's parent pid, so the
# Claude hook adapter must `exec` this script (its parent is then the agent
# process, which lives for the whole session) rather than run it as a subprocess.

set -euo pipefail

PROFILES_FILE="${CLAUDE_PROFILES_FILE:-${DOTFILES_DIR:-$HOME/Developer/dotfiles}/iterm2/DynamicProfiles/sessions.json}"
COLORS_DIR="${CLAUDE_SESSION_COLORS_DIR:-$HOME/.claude/session-colors}"
CLAIM_OWNER="${SESSION_COLOR_OWNER:-$PPID}"

usage() {
  cat <<'EOF'
session_color.sh — per-session iTerm2 profile switching

  pool [--held]        profile names, one per line; --held appends a tab + HELD
                       when a live session holds one
  pick                 prompt on the tty, echo the chosen profile ("" = declined)
  apply <profile>      switch this terminal to <profile>, record the claim
  swatch <profile>     echo the profile's swatch emoji
  apply-for-title <s>  switch to the profile whose swatch appears in <s>

Skipped (exit 0, no output) unless this is iTerm2 with a readable profile file.
EOF
}

can_colour() {
  [[ ${TERM_PROGRAM:-} == "iTerm.app" && -r "$PROFILES_FILE" ]]
}

profile_names() {
  awk -F'"' '/"Name": / { print $4 }' "$PROFILES_FILE"
}

# "<name>\t<swatch>" per profile, in file order.
name_swatch_pairs() {
  awk -F'"' '
    /"Name": /   { name = $4 }
    /"Swatch": / { print name "\t" $4 }
  ' "$PROFILES_FILE"
}

swatch_for() {
  local want="$1" name swatch
  while IFS=$'\t' read -r name swatch; do
    if [[ "$name" == "$want" ]]; then
      printf '%s\n' "$swatch"
      return 0
    fi
  done < <(name_swatch_pairs)
  return 0
}

profile_for_swatch_in() {
  local text="$1" name swatch
  while IFS=$'\t' read -r name swatch; do
    if [[ -n "$swatch" && "$text" == *"$swatch"* ]]; then
      printf '%s\n' "$name"
      return 0
    fi
  done < <(name_swatch_pairs)
  return 0
}

claim_file() {
  printf '%s/%s' "$COLORS_DIR" "${1// /_}"
}

claim_holder() {
  cat "$(claim_file "$1")" 2>/dev/null || true
}

holder_is_live() {
  local owner
  owner="$(claim_holder "$1")"
  [[ -n "$owner" ]] && kill -0 "$owner" 2>/dev/null
}

record_claim() {
  local profile="$1" other
  mkdir -p "$COLORS_DIR"
  printf '%s\n' "$CLAIM_OWNER" >"$(claim_file "$profile")"

  while IFS= read -r other; do
    [[ "$other" == "$profile" ]] && continue
    if [[ "$(claim_holder "$other")" == "$CLAIM_OWNER" ]]; then
      rm -f "$(claim_file "$other")"
    fi
  done < <(profile_names)
  return 0
}

emit_set_profile() {
  (printf '\033]1337;SetProfile=%s\a' "$1" >/dev/tty) 2>/dev/null || true
}

cmd_pool() {
  can_colour || exit 0

  local with_held="" name
  [[ "${1:-}" == "--held" ]] && with_held=1

  while IFS= read -r name; do
    if [[ -n "$with_held" ]] && holder_is_live "$name"; then
      printf '%s\tHELD\n' "$name"
    else
      printf '%s\n' "$name"
    fi
  done < <(profile_names)
}

cmd_apply() {
  local profile="${1:?session_color.sh apply: profile required}"
  can_colour || exit 0

  emit_set_profile "$profile"
  record_claim "$profile"
}

cmd_swatch() {
  local profile="${1:?session_color.sh swatch: profile required}"
  can_colour || exit 0

  swatch_for "$profile"
}

cmd_apply_for_title() {
  can_colour || exit 0

  local profile
  profile="$(profile_for_swatch_in "${1:-}")"
  [[ -n "$profile" ]] || exit 0

  cmd_apply "$profile"
}

# Row label for the picker: "3) 🟩 Fern" plus " ·" when the colour is in use.
menu_entry() {
  local index="$1" name="$2" held="$3" swatch
  swatch="$(swatch_for "$name")"

  printf '%d) %s %s%s' "$((index + 1))" "${swatch:-⬜}" "$name" "${held:+ ·}"
}

cmd_pick() {
  can_colour || exit 0
  [[ -t 0 && -t 2 ]] || exit 0

  local names=() name
  while IFS= read -r name; do names+=("$name"); done < <(profile_names)
  [[ "${#names[@]}" -gt 0 ]] || exit 0

  local held=() default="" index owner
  for index in "${!names[@]}"; do
    held[index]=""
    owner="$(claim_holder "${names[index]}")"
    [[ -n "$owner" ]] || continue
    if [[ "$owner" == "$CLAIM_OWNER" ]]; then
      [[ -n "$default" ]] || default="$index"
    elif kill -0 "$owner" 2>/dev/null; then
      held[index]=1
    fi
  done
  if [[ -z "$default" ]]; then
    for index in "${!names[@]}"; do
      if [[ -z "${held[index]}" ]]; then
        default="$index"
        break
      fi
    done
  fi
  [[ -n "$default" ]] || default=0

  local rows=$(((${#names[@]} + 1) / 2)) row peer
  {
    printf '\n  Session colour:\n'
    for ((row = 0; row < rows; row++)); do
      peer=$((row + rows))
      if [[ "$peer" -lt "${#names[@]}" ]]; then
        printf '    %-24s %s\n' \
          "$(menu_entry "$row" "${names[row]}" "${held[row]}")" \
          "$(menu_entry "$peer" "${names[peer]}" "${held[peer]}")"
      else
        printf '    %s\n' "$(menu_entry "$row" "${names[row]}" "${held[row]}")"
      fi
    done
    printf '    · = already in use, 0 = no colour\n'
  } >&2

  local reply
  while true; do
    printf '  > [%d] ' "$((default + 1))" >&2
    read -r reply || {
      printf '\n' >&2
      reply=$((default + 1))
    }
    [[ -z "$reply" ]] && reply=$((default + 1))
    [[ "$reply" == [qQ] ]] && reply=0
    if [[ "$reply" =~ ^[0-9]+$ ]] && [[ "$reply" -ge 0 ]] && [[ "$reply" -le "${#names[@]}" ]]; then
      break
    fi
    printf '    pick 1-%d, or 0 for no colour\n' "${#names[@]}" >&2
  done

  if [[ "$reply" -gt 0 ]]; then
    printf '%s\n' "${names[reply - 1]}"
  fi
}

main() {
  local subcommand="${1:-}"
  [[ "$#" -gt 0 ]] && shift

  case "$subcommand" in
    pool) cmd_pool "$@" ;;
    pick) cmd_pick "$@" ;;
    apply) cmd_apply "$@" ;;
    swatch) cmd_swatch "$@" ;;
    apply-for-title) cmd_apply_for_title "$@" ;;
    -h | --help | "") usage ;;
    *)
      printf 'session_color.sh: unknown command: %s\n' "$subcommand" >&2
      exit 2
      ;;
  esac
}

main "$@"
