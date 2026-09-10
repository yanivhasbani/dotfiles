# iOS dot files

A repo designated to allow easy ongoing MAC env customization.

Currently supports 2 types of different underlying terminals:

1. zsh
2. xonsh

[!WARNING]
This repo depends on the [MAC install env](https://github.com/yanivhasbani/setup_mac_env.git) repo, and assumes homebrew was installed and zsh-autocomplete/autosuggestion are already installed.


## iTerm2 session profiles

`iterm2/DynamicProfiles/sessions.json` defines a colour profile per concurrent
Claude session, so sessions stay distinguishable in a tab strip and in a
`/resume` picker. Each entry carries a `"Swatch"` emoji (`🟩` …) — the single
source of truth for the name↔swatch↔profile mapping, since the swatch also has to
travel in the session name to reach the mobile app, where escape-sequence colours
never arrive.

Link the file into iTerm2's dynamic profiles directory:

```sh
mkdir -p ~/Library/Application\ Support/iTerm2/DynamicProfiles
ln -sf "$PWD/iterm2/DynamicProfiles/sessions.json" \
       ~/Library/Application\ Support/iTerm2/DynamicProfiles/sessions.json
```

Each profile inherits from `Default` and overrides only colours. Backgrounds stay
near-black so no session reads as bright; the colour is carried by the tab strip,
which needs Appearance → Theme → **Minimal** to be visible.

### How a session gets its colour

`iterm2/session_color.sh` is the colour engine — it lists the pool, runs the
picker, applies a profile, tracks which colour each live session holds, and maps a
session name back to its profile. Each integration is a thin adapter over its
subcommands (`pool`, `pick`, `apply`, `swatch`, `apply-for-title`). It exits
silently when it isn't running under iTerm2, so adapters can call it
unconditionally. The engine is agent-neutral — nothing in it is Claude-specific —
so a Pi adapter can reuse it later.

- **At launch** — `zsh/zshrc.d/claude.zsh` wraps `claude`: for a fresh interactive
  session it runs `session_color.sh pick` *before* `claude` starts (the one step a
  hook can't do), applies the choice, and names the session `dir 🟩`. Resumed
  (`-r`/`-c`) and non-interactive (`-p`) invocations pass straight through.
- **On resume** — including the in-CLI `/resume` picker, which the shell wrapper
  never sees — the [`yh-skills`](https://github.com/yanivhasbani/skills) repo's
  Claude Code `SessionStart` hook calls
  `session_color.sh apply-for-title "<session name>"`, reapplying the profile from
  the swatch in the name. It locates the script through `CLAUDE_SESSION_COLOR_SH`,
  exported by `claude.zsh`; without this repo installed it no-ops.

### Editing the profiles

Run `iterm-reload-profiles` after every change to this file. iTerm2 watches the
dynamic-profiles *directory*, and the entry there is a symlink — so writing to the
repo's copy is invisible to it, and it goes on serving whatever it cached when the
link was made. The helper recreates the link, which is the event the watcher wants,
and validates the JSON first.

Nothing warns you when this goes wrong. Selecting a profile iTerm2 has never loaded
is a silent no-op, so a stale cache is indistinguishable from a colour that simply
refuses to apply.

Three things to keep in mind when adding or editing a profile:

- **Write every colour three times** — `Key`, `Key (Light)` and `Key (Dark)`. The
  parent profile sets *Use Separate Colors for Light and Dark Mode*, and under that
  flag iTerm2 reads only the suffixed keys and ignores the plain one. A profile that
  sets just `Background Color` inherits the parent's background and looks untouched.
- **Leave the ANSI palette alone.** All sixteen ANSI colours come from `Default`.
  Overriding them per profile only makes sense for a background that differs in
  brightness from the rest, and none of these do.
- **Give it a `"Swatch"`** — a distinct emoji. `session_color.sh` uses it for the
  picker menu, for the `dir 🟩` session name, and to recognise the profile when a
  session is resumed. iTerm2 ignores the key.
