# iOS dot files

A repo designated to allow easy ongoing MAC env customization.

Currently supports 2 types of different underlying terminals:

1. zsh
2. xonsh

[!WARNING]
This repo depends on the [MAC install env](https://github.com/yanivhasbani/setup_mac_env.git) repo, and assumes homebrew was installed and zsh-autocomplete/autosuggestion are already installed.


## iTerm2 session profiles

`iterm2/DynamicProfiles/sessions.json` defines the colour profiles that
`zsh/zshrc.d/claude.zsh` assigns to concurrent Claude sessions. Link it into
iTerm2's dynamic profiles directory — iTerm2 picks the file up live, no restart:

```sh
mkdir -p ~/Library/Application\ Support/iTerm2/DynamicProfiles
ln -sf "$PWD/iterm2/DynamicProfiles/sessions.json" \
       ~/Library/Application\ Support/iTerm2/DynamicProfiles/sessions.json
```

Each profile inherits from the `Default` profile and overrides only colours.
Backgrounds stay near-black so no session reads as bright; the colour is carried
by the tab strip, which needs Appearance → Theme → **Minimal** to be visible.
`Frost` is the exception — a light background, shipping a dark ANSI palette so
the prompt stays readable on it.
