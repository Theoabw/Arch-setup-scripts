#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../modules/common/helpers.sh disable=SC1091
source "$ROOT_DIR/modules/common/helpers.sh"

require_root
require_supported_distro

DISTRO_NAME="$(detect_distro_pretty_name)"
DISTRO_FAMILY="$(detect_distro_family)"

log_info "Running post-install tweaks for $DISTRO_NAME"

case "$DISTRO_FAMILY" in
  arch)
    PACMAN_CONF="/etc/pacman.conf"
    if grep -q '^#ParallelDownloads' "$PACMAN_CONF"; then
      sed -i 's/^#ParallelDownloads/ParallelDownloads/' "$PACMAN_CONF"
      log_info "Enabled pacman parallel downloads"
    fi
    ;;
  debian)
    TARGET_BIN_DIR="/usr/local/bin"
    mkdir -p "$TARGET_BIN_DIR"
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
      ln -sf "$(command -v fdfind)" "$TARGET_BIN_DIR/fd"
      log_info "Linked fd to fdfind in $TARGET_BIN_DIR"
    fi
    if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
      ln -sf "$(command -v batcat)" "$TARGET_BIN_DIR/bat"
      log_info "Linked bat to batcat in $TARGET_BIN_DIR"
    fi
    if command -v docker >/dev/null 2>&1 && ! command -v docker-compose >/dev/null 2>&1; then
      compose_plugin=""
      for candidate in /usr/libexec/docker/cli-plugins/docker-compose /usr/lib/docker/cli-plugins/docker-compose; do
        if [[ -x "$candidate" ]]; then
          compose_plugin="$candidate"
          break
        fi
      done
      if [[ -n "$compose_plugin" ]]; then
        cat <<'EOF' > "$TARGET_BIN_DIR/docker-compose"
#!/usr/bin/env bash
exec docker compose "$@"
EOF
        chmod +x "$TARGET_BIN_DIR/docker-compose"
        log_info "Created docker-compose shim that forwards to docker compose"
      fi
    fi
    ;;
  *)
    log_warn "No post-install tweaks defined for distro family: $DISTRO_FAMILY"
    ;;
esac

log_info "Post-install tweaks complete"
