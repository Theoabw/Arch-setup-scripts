#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../modules/common/helpers.sh disable=SC1091
source "$ROOT_DIR/modules/common/helpers.sh"

log_info "Starting full Arch tooling setup"

run_root_cmd bash "$ROOT_DIR/bootstrap/install-core.sh"
run_root_cmd bash "$ROOT_DIR/bootstrap/post-install.sh"

bash "$ROOT_DIR/scripts/install-yay.sh" --configure
bash "$ROOT_DIR/scripts/install-shell.sh"

YAY_MANIFEST="$ROOT_DIR/manifests/yay-packages.txt"
if command -v yay >/dev/null 2>&1; then
  mapfile -t aur_packages < <(read_manifest "$YAY_MANIFEST") || true
  if [[ ${#aur_packages[@]} -gt 0 ]]; then
    log_info "Installing AUR packages from manifests/yay-packages.txt"
    yay --sync --needed --noconfirm "${aur_packages[@]}"
  else
    log_warn "No AUR packages listed in manifests/yay-packages.txt"
  fi
else
  log_warn "yay not found; skipping AUR package installation"
fi

if command -v docker >/dev/null 2>&1 && command -v systemctl >/dev/null 2>&1; then
  log_info "Enabling and starting docker service"
  run_root_cmd systemctl enable --now docker
  if [[ -n "${SUDO_USER:-}" ]]; then
    TARGET_USER="$SUDO_USER"
  else
    TARGET_USER="$(id -un)"
  fi
  if id -nG "$TARGET_USER" | grep -qw docker; then
    log_info "User $TARGET_USER already in docker group"
  else
    log_info "Adding $TARGET_USER to docker group"
    run_root_cmd usermod -aG docker "$TARGET_USER"
    log_warn "You must log out/in for docker group membership to take effect"
  fi
else
  log_warn "Docker command or systemctl not available; skipping docker service setup"
fi

log_info "All setup steps complete"
