#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=../common/helpers.sh disable=SC1091
source "$ROOT_DIR/modules/common/helpers.sh"

ZSHRC_PATH="$HOME/.zshrc"
THEME_NAME="${OH_MY_ZSH_THEME:-robbyrussell}"

if [[ ! -f "$ZSHRC_PATH" ]]; then
  log_error "$HOME/.zshrc not found; install oh-my-zsh before setting theme"
  exit 1
fi

if grep -E '^ZSH_THEME=' "$ZSHRC_PATH" >/dev/null; then
  sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$THEME_NAME\"/" "$ZSHRC_PATH"
  log_info "Set ZSH theme to $THEME_NAME"
else
  echo "ZSH_THEME=\"$THEME_NAME\"" >> "$ZSHRC_PATH"
  log_info "Appended ZSH theme setting"
fi
