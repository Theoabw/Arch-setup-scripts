#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=../common/helpers.sh disable=SC1091
source "$ROOT_DIR/modules/common/helpers.sh"

require_non_root

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yay"
CONFIG_FILE="$CONFIG_DIR/config.json"
TEMPLATE="$ROOT_DIR/configs/yay/yay.conf.template"

if [[ ! -f "$TEMPLATE" ]]; then
  log_error "Missing template at configs/yay/yay.conf.template"
  exit 1
fi

mkdir -p "$CONFIG_DIR"

if [[ -f "$CONFIG_FILE" ]]; then
  UPDATED=false
  if grep -q '"cleanAfter": "true"' "$CONFIG_FILE"; then
    sed -i 's/"cleanAfter": "true"/"cleanAfter": true/' "$CONFIG_FILE"
    UPDATED=true
  fi
  if grep -q '"cleanAfter": "false"' "$CONFIG_FILE"; then
    sed -i 's/"cleanAfter": "false"/"cleanAfter": false/' "$CONFIG_FILE"
    UPDATED=true
  fi
  if grep -q '"removeMake": true' "$CONFIG_FILE"; then
    sed -i 's/"removeMake": true/"removeMake": "true"/' "$CONFIG_FILE"
    UPDATED=true
  fi
  if grep -q '"removeMake": false' "$CONFIG_FILE"; then
    sed -i 's/"removeMake": false/"removeMake": "false"/' "$CONFIG_FILE"
    UPDATED=true
  fi
  if [[ "$UPDATED" == true ]]; then
    log_info "Normalized existing yay config boolean flags"
  else
    log_warn "$CONFIG_FILE already exists; leaving it untouched"
  fi
  exit 0
fi

cp "$TEMPLATE" "$CONFIG_FILE"
log_info "Copied default yay config to $CONFIG_FILE"
