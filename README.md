# Arch Setup Scripts

Opinionated scripts for bootstrapping a Linux workstation with oh-my-zsh and related tooling. Arch Linux remains the primary target, but Debian and Ubuntu are now supported with automatic distro detection. The repository keeps install logic modular so you can tweak or extend each component independently.

## Layout

```
bootstrap/            # root-level system tasks (package manager setup, config tweaks)
modules/              # reusable installer building blocks
  common/             # shared helpers sourced by other scripts
  shell/              # oh-my-zsh and plugin installers
  yay/                # yay install + configuration helpers
configs/              # templates copied into the user's home
manifests/            # package lists consumed by scripts
scripts/              # user-facing entrypoints
```

## Quickstart

```bash
# Run the full bootstrap + tooling install
./scripts/setup-all.sh
```

The entrypoint autodetects whether you're on Arch or Debian/Ubuntu and applies the matching bootstrap flow.

Scripts expect a regular user with sudo rights. `setup-all.sh` elevates only for package-manager steps and then continues as the invoking user for shell customisation.

## Individual scripts

- `./scripts/install-yay.sh [--configure]` installs the yay AUR helper and, optionally, copies the default config from `configs/yay/yay.conf.template`. This script is skipped automatically on non-Arch systems.
- `./scripts/install-shell.sh [--skip-chsh] [--skip-fzf] [--skip-history] [--skip-theme]` installs oh-my-zsh, optionally changes your login shell to zsh, and wires up extras like fzf bindings and history tuning.
- Module scripts underneath `modules/` can be called directly if you need finer-grained control, but prefer the wrappers in `scripts/` for sensible defaults and argument parsing.

## Manifests

- `manifests/base-packages.txt` feeds into `bootstrap/install-core.sh` for Arch-based systems.
- `manifests/base-packages.debian.txt` mirrors the base manifest for Debian/Ubuntu systems.
- `manifests/yay-packages.txt` is read by `scripts/setup-all.sh` after yay is installed. Comment or remove lines to skip packages.

## Customising

- Adjust `configs/zsh/.zshrc.template` to tweak the snippet appended to your `.zshrc` (fzf bindings, plugin fallbacks, editor defaults). The installer augments an existing oh-my-zsh config instead of replacing it. Set `OH_MY_ZSH_THEME` before running the installer to override the default theme (`robbyrussell` keeps good compatibility across terminals).
- Update `configs/yay/yay.conf.template` for global yay behaviour such as default editor or cleanup preferences.
- Extend the layout by dropping new modules (for example `modules/gui/`) and invoking them from a wrapper script in `scripts/`.

## Notes

- Scripts are idempotent where practical: repeated runs of the same installer skip work when the target is already configured.
- The helpers in `modules/common/helpers.sh` centralise logging, root elevation, and manifest parsing—source them from any new module scripts you add.
