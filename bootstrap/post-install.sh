#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../modules/common/helpers.sh disable=SC1091
source "$ROOT_DIR/modules/common/helpers.sh"

require_root
log_info "Running post-install tweaks"

# Example tweak: enable parallel downloads if not already set
PACMAN_CONF="/etc/pacman.conf"
if grep -q '^#ParallelDownloads' "$PACMAN_CONF"; then
  sed -i 's/^#ParallelDownloads/ParallelDownloads/' "$PACMAN_CONF"
  log_info "Enabled pacman parallel downloads"
fi

log_info "Post-install tweaks complete"
