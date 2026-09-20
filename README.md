# dotfiles

Personal Linux desktop configuration: Hyprland/Niri, Waybar, Ax-Shell,
terminals, launchers, notifications, theming, shell tools, Neovim, Zellij,
Yazi, and supporting scripts.

## Layout

The repository mirrors paths under `$HOME`, so files can be installed with a
copy or symlink workflow of your choice. The `.config/Ax-Shell` directory is
included as part of the desktop setup.

## Safety

This is a curated snapshot. Histories, browser/application state, caches,
private keys, cloud credentials, GitHub CLI credentials, and the local
`cli-top` environment file are intentionally excluded. Review paths and
machine-specific values before installing on another system.

## Fresh-system setup

On a supported Arch, Debian/Ubuntu, Fedora, or openSUSE system, clone the
repository and run:

```sh
./install.sh
```

The installer detects the native package manager, installs missing desktop
components—including both Hyprland and Niri—plus the tools used by this
configuration, then copies the repository layout into your home directory.
Existing files are preserved with a timestamped `.bak.*` suffix. Preview the
package and copy actions without changing anything with:

```sh
./install.sh --dry-run
```

Use `./install.sh --skip-packages` when the required programs are already
installed. The package managers must provide `hyprland` and `niri`; if a
distribution does not package either compositor in its enabled repositories,
install that package source first and rerun the script.
