# dotfiles

Personal shell environment — zsh + tmux, managed with [oh-my-zsh](https://ohmyz.sh) and [tpm](https://github.com/tmux-plugins/tpm).

## Quick start

```bash
git clone git@github.com:a1liz/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

Then:

1. Edit `~/.zshrc.local` — add machine-specific paths and secrets
2. `exec zsh`
3. In tmux: `prefix + I` to install plugins

## What's included

| Area | Config | Details |
|------|--------|---------|
| zsh  | `zshrc` | oh-my-zsh + p10k |
| zsh  | `my_zshrc` | aliases (proxy, cp, ls, etc.) |
| zsh  | `p10k.zsh` | powerlevel10k prompt |
| tmux | `tmux.conf` | tpm + dracula theme + status plugins |

## Structure

```
├── install.sh          # one-shot bootstrap
├── zsh/
│   ├── zshrc           # oh-my-zsh + plugins + theme
│   ├── my_zshrc        # custom aliases
│   └── p10k.zsh        # prompt config
└── tmux/
    └── tmux.conf       # tmux with tpm + dracula
```

Machine-specific config lives in `~/.zshrc.local` (git-ignored).
