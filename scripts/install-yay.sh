#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../modules/common/helpers.sh disable=SC1091
source "$ROOT_DIR/modules/common/helpers.sh"

show_help() {
  cat <<USAGE
Usage: $(basename "$0") [--configure]

Installs the yay AUR helper for the current user.

Options:
  --configure    Copy default yay configuration after install.
  -h, --help     Show this message.
USAGE
}

CONFIGURE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --configure)
      CONFIGURE=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

bash "$ROOT_DIR/modules/yay/install.sh"

if [[ "$CONFIGURE" == true ]]; then
  bash "$ROOT_DIR/modules/yay/config.sh"
fi

log_info "yay setup script complete"
