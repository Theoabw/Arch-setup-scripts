#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=../../common/helpers.sh disable=SC1091
source "$ROOT_DIR/modules/common/helpers.sh"

log_info "Installing fzf"
pacman_install fzf

ZSHRC_PATH="$HOME/.zshrc"
FZF_SNIPPET='[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh'

if [[ -f "$ZSHRC_PATH" ]]; then
  if ! grep -Fq "$FZF_SNIPPET" "$ZSHRC_PATH"; then
    {
      echo ""
      echo "# fzf keybindings"
      echo "$FZF_SNIPPET"
    } >> "$ZSHRC_PATH"
    log_info "Appended fzf keybindings to .zshrc"
  else
    log_info "fzf keybindings already configured in .zshrc"
  fi
else
  log_warn "$HOME/.zshrc not found; run install-ohmyzsh.sh first"
fi

log_info "fzf setup complete"
