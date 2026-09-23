#!/usr/bin/env bash
#
# popup.sh: detail popup wiring behind a single mockable tmux seam.
#
# Every tmux interaction goes through _tmux so tests can capture the call and the
# real monitor (btop) is never launched. The popup is gated on tmux 3.2, which is
# where display-popup landed; older tmux gets a plain message instead.

[[ -n "${_CPU_REVAMPED_POPUP_LOADED:-}" ]] && return 0
_CPU_REVAMPED_POPUP_LOADED=1

_CPU_POPUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_CPU_POPUP_DIR}/../tmux/tmux-ops.sh"

# _tmux ARGS... -> the single tmux seam. Tests override this; nothing else in
# this file calls the real tmux binary or any monitor.
_tmux() { tmux "$@"; }

# cpu_tmux_version RAW -> the "MAJOR.MINOR" number parsed from `tmux -V` output.
cpu_tmux_version() {
  printf '%s\n' "${1}" | grep -oE '[0-9]+\.[0-9]+' | head -1
}

# cpu_version_ge A B -> 0 when version A is at least version B.
cpu_version_ge() {
  [[ -n "${1}" ]] || return 1
  awk -v a="${1}" -v b="${2}" 'BEGIN { split(a, x, "."); split(b, y, "."); if (x[1]+0 > y[1]+0 || (x[1]+0 == y[1]+0 && x[2]+0 >= y[2]+0)) exit 0; exit 1 }'
}

# cpu_popup_supported -> 0 when the running tmux supports display-popup (3.2+).
cpu_popup_supported() {
  local version
  version=$(cpu_tmux_version "$(_tmux -V 2>/dev/null)")
  cpu_version_ge "${version}" "3.2"
}

# cpu_popup_command -> the command run inside the popup. Defaults to btop.
cpu_popup_command() {
  get_tmux_option "@cpu_revamped_popup_command" "btop"
}

# cpu_popup_open -> open the detail popup, or warn when tmux is too old.
cpu_popup_open() {
  local command width height
  command=$(cpu_popup_command)
  if cpu_popup_supported; then
    width=$(get_tmux_option "@cpu_revamped_popup_width" "80%")
    height=$(get_tmux_option "@cpu_revamped_popup_height" "80%")
    _tmux display-popup -E -w "${width}" -h "${height}" "${command}"
  else
    _tmux display-message "tmux 3.2+ is required for the CPU detail popup"
  fi
}

# cpu_popup_bind SCRIPT -> bind the configured key to open the popup.
cpu_popup_bind() {
  local key
  key=$(get_tmux_option "@cpu_revamped_popup_key" "M-c")
  _tmux bind-key "${key}" run-shell "${1} popup"
}

export -f _tmux
export -f cpu_tmux_version
export -f cpu_version_ge
export -f cpu_popup_supported
export -f cpu_popup_command
export -f cpu_popup_open
export -f cpu_popup_bind
