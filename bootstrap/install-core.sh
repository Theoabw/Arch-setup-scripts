#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../modules/common/helpers.sh disable=SC1091
source "$ROOT_DIR/modules/common/helpers.sh"

require_root
log_info "Running core system bootstrap"

log_info "Refreshing pacman databases"
pacman -Syu --noconfirm

BASE_MANIFEST="$ROOT_DIR/manifests/base-packages.txt"
mapfile -t base_packages < <(read_manifest "$BASE_MANIFEST") || true

if [[ ${#base_packages[@]} -gt 0 ]]; then
  log_info "Installing base packages from manifests/base-packages.txt"
  pacman --sync --needed --noconfirm "${base_packages[@]}"
else
  log_warn "No base packages listed in manifests/base-packages.txt"
fi

log_info "Core bootstrap finished"
