#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=../common/helpers.sh disable=SC1091
source "$SCRIPT_DIR/../common/helpers.sh"

require_non_root
require_command git
require_command zsh
require_command python3

OH_MY_ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
OH_MY_ZSH_CUSTOM="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}"
ZSHRC_PATH="$HOME/.zshrc"
TEMPLATE="$ROOT_DIR/configs/zsh/.zshrc.template"

if [[ -d "$OH_MY_ZSH_DIR" ]]; then
  log_info "oh-my-zsh already present at $OH_MY_ZSH_DIR"
else
  log_info "Cloning oh-my-zsh"
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
fi

BACKUP_PATH="${ZSHRC_PATH}.pre-setup"
if [[ -f "$ZSHRC_PATH" ]]; then
  if [[ ! -f "$BACKUP_PATH" ]]; then
    cp "$ZSHRC_PATH" "$BACKUP_PATH"
    log_info "Backed up existing .zshrc to $BACKUP_PATH"
  else
    log_info "Preserving existing .zshrc (previous backup at $BACKUP_PATH)"
  fi
else
  local_template="$OH_MY_ZSH_DIR/templates/zshrc.zsh-template"
  if [[ -f "$local_template" ]]; then
    cp "$local_template" "$ZSHRC_PATH"
    log_info "Seeded $ZSHRC_PATH from oh-my-zsh template"
  else
    log_warn "oh-my-zsh template missing; creating empty $ZSHRC_PATH"
    : > "$ZSHRC_PATH"
  fi
fi

ensure_plugin_link() {
  local plugin="$1"
  shift
  local candidate target=""
  for candidate in "$@"; do
    if [[ -d "$candidate" ]]; then
      target="$candidate"
      break
    fi
    if [[ -f "$candidate" ]]; then
      target="$(dirname "$candidate")"
      break
    fi
  done
  if [[ -z "$target" ]]; then
    log_warn "Unable to locate files for oh-my-zsh plugin '$plugin'"
    return 0
  fi

  local dest="$OH_MY_ZSH_CUSTOM/plugins/$plugin"
  if [[ -e "$dest" ]]; then
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$target" "$dest"
  log_info "Linked oh-my-zsh plugin '$plugin' from $target"
}

ensure_plugin_link "zsh-autosuggestions" \
  "/usr/share/zsh/plugins/zsh-autosuggestions" \
  "/usr/share/zsh-autosuggestions"

ensure_plugins_config() {
  local target="$1"
  shift
  local -a required=("$@")
  local output
  if output=$(python3 - "$target" "${required[@]}" <<'PY'
import sys
import pathlib
import re

path = pathlib.Path(sys.argv[1])
required = sys.argv[2:]
try:
    text = path.read_text()
except FileNotFoundError:
    text = ""

pattern = re.compile(r'^plugins=\((.*?)\)', re.MULTILINE)
match = pattern.search(text)
added = []

if match:
    existing = [token for token in match.group(1).split() if token]
    for plugin in required:
        if plugin not in existing:
            existing.append(plugin)
            added.append(plugin)
    if added:
        new_line = 'plugins=(' + ' '.join(existing) + ')'
        start, end = match.span()
        text = text[:start] + new_line + text[end:]
else:
    existing = []
    for plugin in required:
        if plugin not in existing:
            existing.append(plugin)
            added.append(plugin)
    new_line = 'plugins=(' + ' '.join(existing) + ')'
    source_pattern = re.compile(r'^\s*source\s+["\']?\$?\{?ZSH\}?/oh-my-zsh\.sh["\']?', re.MULTILINE)
    source_match = source_pattern.search(text)
    insertion = new_line + "\n"
    if source_match:
        idx = source_match.start()
        text = text[:idx] + insertion + text[idx:]
    else:
        if text and not text.endswith("\n"):
            text += "\n"
        text += insertion

if added:
    if not text.endswith("\n"):
        text += "\n"
    path.write_text(text)
    print("Ensured plugins include: " + ", ".join(added))
PY
); then
    if [[ -n "$output" ]]; then
      log_info "$output"
    fi
  else
    log_warn "Failed to reconcile plugins list in $target"
  fi
}

append_snippet_if_missing() {
  local snippet="$1"
  local target="$2"
  if [[ ! -f "$snippet" ]]; then
    return
  fi
  local marker
  marker="$(head -n 1 "$snippet")"
  if [[ -n "$marker" ]] && grep -Fq "$marker" "$target"; then
    return
  fi
  {
    echo ""
    cat "$snippet"
  } >> "$target"
  log_info "Appended shell defaults snippet from ${snippet#$ROOT_DIR/} to ${target##*/}"
}

ensure_plugins_config "$ZSHRC_PATH" git fzf history-substring-search zsh-autosuggestions
append_snippet_if_missing "$TEMPLATE" "$ZSHRC_PATH"

log_info "oh-my-zsh installation complete"
