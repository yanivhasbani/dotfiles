# iTerm2 watches the dynamic-profiles *directory*, not the files inside it. When the
# entry there is a symlink into this repo — which is how the README says to install it
# — editing the repo's copy changes nothing the watcher can see, so iTerm2 keeps
# serving the profiles it cached the day the link was made.
#
# Nothing reports this. A profile that no longer exists is dropped from the picker
# only after a reload, and the escape sequence that selects one is a no-op on a name
# iTerm2 does not know, so a stale cache looks exactly like a colour that "just
# doesn't apply". Recreating the link changes the directory, which is the event the
# watcher is actually waiting for; the reload is immediate and needs no restart.

ITERM2_PROFILES_DIR="${ITERM2_PROFILES_DIR:-$HOME/Library/Application Support/iTerm2/DynamicProfiles}"

iterm-reload-profiles() {
  local src="$DOTFILES_DIR/iterm2/DynamicProfiles/sessions.json"
  local dst="$ITERM2_PROFILES_DIR/sessions.json"

  [[ -r $src ]] || { print -u2 "iterm-reload-profiles: cannot read $src"; return 1 }

  # iTerm2 ignores a malformed file in silence, which is the same symptom as a stale
  # one. Fail here instead, where the reason is visible.
  local names
  names=$(python3 - "$src" <<'PY' 2>/dev/null
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception as e:
    print("ERR " + str(e)); raise SystemExit(0)
print(", ".join(p.get("Name", "?") for p in d.get("Profiles", [])))
PY
)
  if [[ -z $names || $names == ERR\ * ]]; then
    print -u2 "iterm-reload-profiles: ${names:-no profiles found} in $src"
    return 1
  fi

  mkdir -p $ITERM2_PROFILES_DIR
  rm -f $dst && ln -s $src $dst || return 1
  print "iTerm2 profiles reloaded: $names"
}
