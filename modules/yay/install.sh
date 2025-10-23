#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=../common/helpers.sh disable=SC1091
source "$ROOT_DIR/modules/common/helpers.sh"

require_non_root
require_command git
require_command makepkg

if command -v yay >/dev/null 2>&1; then
  log_info "yay already installed"
  exit 0
fi

log_info "Installing yay from AUR"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

log_info "Cloning yay repo"
git clone https://aur.archlinux.org/yay.git "$workdir/yay"

pushd "$workdir/yay" >/dev/null
log_info "Building yay (you may be prompted for sudo to install dependencies)"
makepkg -si --noconfirm
popd >/dev/null

log_info "yay installation complete"
