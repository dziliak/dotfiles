# dotfiles

## Oneliner to restore config files

`sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/dziliak/dotfiles.git`

## Make sure to change the git origin to SSH

`git remote set-url origin git@github.com:dziliak/dotfiles.git`

## Make sure to install pre-commit

1. `chezmoi cd`
2. `brew install pre-commit gitleaks`
3. `pre-commit install`
4. `pre-commit run --all-files`

## Adding files to be encrypted

`chezmoi add --encrypt path/to/file`

## Some installed apps from Homebrew need to be unquarantined

`xattr -dr com.apple.quarantine /Applications/Qucs-S.app`

## To-do List

- [x] Install on desktop
- [ ] Install on surface pro
- [x] Commit hyprland config to repo
- [ ] Template fastfetch for mac vs linux
- [ ] Create mac installers for configs
- [ ] Create pacman/paru installers for configs
- [ ] Create paru update/upgrade on running chezmoi apply
