#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=../../common/helpers.sh disable=SC1091
source "$ROOT_DIR/modules/common/helpers.sh"

ZSHRC_PATH="$HOME/.zshrc"

if [[ ! -f "$ZSHRC_PATH" ]]; then
  log_error "$HOME/.zshrc not found; install oh-my-zsh before configuring history"
  exit 1
fi

HISTORY_SNIPPET="\
# Shared history and sensible defaults\n\
HISTSIZE=10000\n\
SAVEHIST=10000\n\
setopt share_history\n\
setopt hist_ignore_dups\n\
setopt hist_reduce_blanks\n\
setopt hist_verify\n"

if grep -Fq "share_history" "$ZSHRC_PATH"; then
  log_info "History options already configured"
  exit 0
fi

echo "" >> "$ZSHRC_PATH"
printf '%s\n' "$HISTORY_SNIPPET" >> "$ZSHRC_PATH"
log_info "Configured zsh history options"
