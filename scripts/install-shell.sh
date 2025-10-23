#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../modules/common/helpers.sh disable=SC1091
source "$ROOT_DIR/modules/common/helpers.sh"

show_help() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Installs oh-my-zsh and optional shell enhancements.

Options:
  --skip-fzf        Do not install fzf or configure bindings.
  --skip-history    Do not configure shared history settings.
  --skip-theme      Do not set the theme (default: agnoster).
  -h, --help        Show this message.
USAGE
}

WITH_FZF=true
WITH_HISTORY=true
WITH_THEME=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-fzf)
      WITH_FZF=false
      shift
      ;;
    --skip-history)
      WITH_HISTORY=false
      shift
      ;;
    --skip-theme)
      WITH_THEME=false
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

bash "$ROOT_DIR/modules/shell/install-ohmyzsh.sh"

if [[ "$WITH_FZF" == true ]]; then
  bash "$ROOT_DIR/modules/shell/plugins/fzf.sh"
fi

if [[ "$WITH_HISTORY" == true ]]; then
  bash "$ROOT_DIR/modules/shell/plugins/history.sh"
fi

if [[ "$WITH_THEME" == true ]]; then
  bash "$ROOT_DIR/modules/shell/theme.sh"
fi

log_info "Shell setup complete"
