# iOS dot files

A repo designated to allow easy ongoing MAC env customization.

Currently supports 2 types of different underlying terminals:

1. zsh
2. xonsh

[!WARNING]
This repo depends on the [MAC install env](https://github.com/yanivhasbani/setup_mac_env.git) repo, and assumes homebrew was installed and zsh-autocomplete/autosuggestion are already installed.


## iTerm2 session profiles

`iterm2/DynamicProfiles/sessions.json` defines the colour profiles that
`zsh/zshrc.d/claude.zsh` offers at the start of a Claude session. Link it into
iTerm2's dynamic profiles directory:

```sh
mkdir -p ~/Library/Application\ Support/iTerm2/DynamicProfiles
ln -sf "$PWD/iterm2/DynamicProfiles/sessions.json" \
       ~/Library/Application\ Support/iTerm2/DynamicProfiles/sessions.json
```

Each profile inherits from `Default` and overrides only colours. Backgrounds stay
near-black so no session reads as bright; the colour is carried by the tab strip,
which needs Appearance → Theme → **Minimal** to be visible.

### Editing the profiles

Run `iterm-reload-profiles` after every change to this file. iTerm2 watches the
dynamic-profiles *directory*, and the entry there is a symlink — so writing to the
repo's copy is invisible to it, and it goes on serving whatever it cached when the
link was made. The helper recreates the link, which is the event the watcher wants,
and validates the JSON first.

Nothing warns you when this goes wrong. Selecting a profile iTerm2 has never loaded
is a silent no-op, so a stale cache is indistinguishable from a colour that simply
refuses to apply.

Two things to keep in mind when adding or editing a profile:

- **Write every colour three times** — `Key`, `Key (Light)` and `Key (Dark)`. The
  parent profile sets *Use Separate Colors for Light and Dark Mode*, and under that
  flag iTerm2 reads only the suffixed keys and ignores the plain one. A profile that
  sets just `Background Color` inherits the parent's background and looks untouched.
- **Leave the ANSI palette alone.** All sixteen ANSI colours come from `Default`.
  Overriding them per profile only makes sense for a background that differs in
  brightness from the rest, and none of these do.
