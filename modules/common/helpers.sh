#!/usr/bin/env bash

# Shared helper functions for installer scripts. Source this file from other modules.

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "helpers.sh is meant to be sourced, not executed directly." >&2
  exit 1
fi

log_info() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

log_warn() {
  printf '\033[1;33m[WARN]\033[0m %s\n' "$*"
}

log_error() {
  printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "Missing command: $cmd. Install it before continuing."
    return 1
  fi
}

require_root() {
  if [[ $EUID -ne 0 ]]; then
    log_error "This script must run as root."
    exit 1
  fi
}

require_non_root() {
  if [[ $EUID -eq 0 ]]; then
    log_error "Run this script as a regular user (sudo will be used when needed)."
    exit 1
  fi
}

run_root_cmd() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
  else
    if command -v sudo >/dev/null 2>&1; then
      sudo "$@"
    else
      log_error "sudo is required for elevated actions."
      return 1
    fi
  fi
}

pacman_install() {
  local -a packages=()
  local pkg
  for pkg in "$@"; do
    packages+=("$pkg")
  done
  if [[ ${#packages[@]} -eq 0 ]]; then
    return 0
  fi
  run_root_cmd pacman --sync --needed --noconfirm "${packages[@]}"
}

read_manifest() {
  local manifest_path="$1"
  if [[ ! -f "$manifest_path" ]]; then
    return 0
  fi
  grep -vE '^(#|\s*$)' "$manifest_path"
}

prompt_yes_no() {
  local prompt="$1"
  local default_answer="${2:-y}"
  local answer
  while true; do
    read -rp "$prompt [y/n] (default: $default_answer) " answer
    answer="${answer:-$default_answer}"
    case "$answer" in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) log_warn "Please answer y or n." ;;
    esac
  done
}
