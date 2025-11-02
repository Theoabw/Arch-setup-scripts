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

__DISTRO_CACHE_INITIALIZED=0
__DISTRO_ID_CACHE=""
__DISTRO_ID_LIKE_CACHE=""
__DISTRO_PRETTY_NAME_CACHE=""
__DISTRO_FAMILY_CACHE=""

_init_distro_cache() {
  if [[ "$__DISTRO_CACHE_INITIALIZED" -eq 1 ]]; then
    return 0
  fi

  if [[ ! -r /etc/os-release ]]; then
    log_error "Unable to detect Linux distribution; /etc/os-release not found."
    return 1
  fi

  local key raw_value value_lower
  while IFS="=" read -r key raw_value; do
    # Strip optional surrounding quotes.
    raw_value="${raw_value%\"}"
    raw_value="${raw_value#\"}"
    value_lower="${raw_value,,}"
    case "$key" in
      ID)
        __DISTRO_ID_CACHE="$value_lower"
        ;;
      ID_LIKE)
        __DISTRO_ID_LIKE_CACHE="$value_lower"
        ;;
      PRETTY_NAME)
        __DISTRO_PRETTY_NAME_CACHE="$raw_value"
        ;;
    esac
  done < /etc/os-release

  if [[ -z "$__DISTRO_ID_CACHE" ]]; then
    __DISTRO_ID_CACHE="unknown"
  fi

  if [[ -z "$__DISTRO_PRETTY_NAME_CACHE" ]]; then
    __DISTRO_PRETTY_NAME_CACHE="$__DISTRO_ID_CACHE"
  fi

  local id="$__DISTRO_ID_CACHE"
  local id_like="$__DISTRO_ID_LIKE_CACHE"
  if [[ "$id" == "arch" ]] || [[ "$id_like" == *"arch"* ]]; then
    __DISTRO_FAMILY_CACHE="arch"
  elif [[ "$id" == "debian" ]] || [[ "$id" == "ubuntu" ]] || [[ "$id_like" == *"debian"* ]] || [[ "$id_like" == *"ubuntu"* ]]; then
    __DISTRO_FAMILY_CACHE="debian"
  else
    __DISTRO_FAMILY_CACHE="unknown"
  fi

  __DISTRO_CACHE_INITIALIZED=1
}

detect_distro_id() {
  _init_distro_cache || return 1
  printf '%s\n' "$__DISTRO_ID_CACHE"
}

detect_distro_pretty_name() {
  _init_distro_cache || return 1
  printf '%s\n' "$__DISTRO_PRETTY_NAME_CACHE"
}

detect_distro_family() {
  _init_distro_cache || return 1
  printf '%s\n' "$__DISTRO_FAMILY_CACHE"
}

is_arch_family() {
  [[ "$(detect_distro_family)" == "arch" ]]
}

is_debian_family() {
  [[ "$(detect_distro_family)" == "debian" ]]
}

require_supported_distro() {
  local family
  family="$(detect_distro_family)" || exit 1
  case "$family" in
    arch|debian)
      return 0
      ;;
    *)
      local id pretty
      id="$(detect_distro_id 2>/dev/null || echo "unknown")"
      pretty="$(detect_distro_pretty_name 2>/dev/null || echo "$id")"
      log_error "Unsupported distribution: ${pretty} (${id})"
      exit 1
      ;;
  esac
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
  install_packages "$@"
}

install_packages() {
  local -a packages=()
  local pkg
  for pkg in "$@"; do
    packages+=("$pkg")
  done
  if [[ ${#packages[@]} -eq 0 ]]; then
    return 0
  fi
  local family
  family="$(detect_distro_family)" || return 1
  case "$family" in
    arch)
      run_root_cmd pacman --sync --needed --noconfirm "${packages[@]}"
      ;;
    debian)
      # Install only missing packages to keep output concise.
      local missing_pkgs=()
      for pkg in "${packages[@]}"; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
          continue
        fi
        missing_pkgs+=("$pkg")
      done
      if [[ ${#missing_pkgs[@]} -eq 0 ]]; then
        return 0
      fi
      run_root_cmd env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${missing_pkgs[@]}"
      ;;
    *)
      log_error "Package installation unsupported for distro family: $family"
      return 1
      ;;
  esac
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
