# dotfiles

## Oneliner to restore config files

`sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/dziliak/dotfiles.git`

## Make sure to install pre-commit

1. `chezmoi cd`
2. `brew install pre-commit gitleaks`
3. `pre-commit install`
4. `pre-commit run --all-files`

## To-do List

- [ ] Install on desktop
- [ ] Install on surface pro
- [ ] Commit hyprland config to repo
- [ ] Template fastfetch for mac vs linux
- [ ] Create mac installers for configs
- [ ] Create pacman/paru installers for configs
- [ ] Create paru update/upgrade on running chezmoi apply
