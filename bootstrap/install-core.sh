#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../modules/common/helpers.sh disable=SC1091
source "$ROOT_DIR/modules/common/helpers.sh"

require_root
require_supported_distro

DISTRO_NAME="$(detect_distro_pretty_name)"
DISTRO_FAMILY="$(detect_distro_family)"

log_info "Running core system bootstrap for $DISTRO_NAME"

BASE_MANIFEST="$ROOT_DIR/manifests/base-packages.txt"

case "$DISTRO_FAMILY" in
  arch)
    log_info "Refreshing pacman databases"
    pacman -Syu --noconfirm
    ;;
  debian)
    BASE_MANIFEST="$ROOT_DIR/manifests/base-packages.debian.txt"
    export DEBIAN_FRONTEND=noninteractive
    log_info "Updating apt package lists"
    apt-get update
    log_info "Upgrading existing packages"
    apt-get upgrade -y
    ;;
  *)
    log_error "Unsupported distribution family: $DISTRO_FAMILY"
    exit 1
    ;;
esac

mapfile -t base_packages < <(read_manifest "$BASE_MANIFEST") || true

if [[ ${#base_packages[@]} -gt 0 ]]; then
  log_info "Installing base packages from ${BASE_MANIFEST#$ROOT_DIR/}"
  install_packages "${base_packages[@]}"
else
  log_warn "No base packages listed in ${BASE_MANIFEST#$ROOT_DIR/}"
fi

log_info "Core bootstrap finished"
