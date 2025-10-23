#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=../common/helpers.sh disable=SC1091
source "$SCRIPT_DIR/../common/helpers.sh"

require_non_root
require_command git
require_command zsh

OH_MY_ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSHRC_PATH="$HOME/.zshrc"
TEMPLATE="$ROOT_DIR/configs/zsh/.zshrc.template"

if [[ -d "$OH_MY_ZSH_DIR" ]]; then
  log_info "oh-my-zsh already present at $OH_MY_ZSH_DIR"
else
  log_info "Cloning oh-my-zsh"
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
fi

if [[ -f "$ZSHRC_PATH" ]]; then
  log_warn "$ZSHRC_PATH already exists; backing up to ${ZSHRC_PATH}.pre-setup"
  cp "$ZSHRC_PATH" "${ZSHRC_PATH}.pre-setup"
fi

if [[ -f "$TEMPLATE" ]]; then
  cp "$TEMPLATE" "$ZSHRC_PATH"
  log_info "Installed default .zshrc from template"
else
  log_warn "Template not found; using oh-my-zsh default"
  cp "$OH_MY_ZSH_DIR/templates/zshrc.zsh-template" "$ZSHRC_PATH"
fi

log_info "oh-my-zsh installation complete"
