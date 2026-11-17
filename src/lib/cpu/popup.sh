#!/usr/bin/env bash

[[ -n "${_CPU_REVAMPED_POPUP_LOADED:-}" ]] && return 0
_CPU_REVAMPED_POPUP_LOADED=1

_CPU_POPUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_CPU_POPUP_DIR}/../tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${_CPU_POPUP_DIR}/../utils/has-command.sh"

_tmux() { tmux "$@"; }

cpu_tmux_version() {
  printf '%s\n' "${1}" | grep -oE '[0-9]+\.[0-9]+' | head -1
}

cpu_version_ge() {
  [[ -n "${1}" ]] || return 1
  LC_ALL=C awk -v a="${1}" -v b="${2}" 'BEGIN { split(a, x, "."); split(b, y, "."); if (x[1]+0 > y[1]+0 || (x[1]+0 == y[1]+0 && x[2]+0 >= y[2]+0)) exit 0; exit 1 }'
}

cpu_popup_supported() {
  local version
  version=$(cpu_tmux_version "$(_tmux -V 2>/dev/null)")
  cpu_version_ge "${version}" "3.2"
}

cpu_popup_command() {
  local chosen
  chosen=$(get_tmux_option "@cpu_revamped_popup_command" "")
  if [[ -n "${chosen}" ]]; then
    echo "${chosen}"
    return 0
  fi
  if has_command btop; then echo "btop"; return 0; fi
  if has_command htop; then echo "htop"; return 0; fi
  echo "top"
}

cpu_popup_open() {
  local command program shown width height
  if ! cpu_popup_supported; then
    _tmux display-message "tmux 3.2+ is required for the CPU detail popup"
    return 0
  fi
  command=$(cpu_popup_command)
  program="${command%% *}"
  if ! has_command "${program}"; then
    shown=$(printf '%s\n' "${program}" | sed 's/#/##/g')
    _tmux display-message "cpu-revamped: ${shown} is not installed"
    return 0
  fi
  width=$(get_tmux_option "@cpu_revamped_popup_width" "80%")
  height=$(get_tmux_option "@cpu_revamped_popup_height" "80%")
  _tmux display-popup -E -w "${width}" -h "${height}" "${command}"
}

cpu_popup_bind() {
  local key script hash="#"
  key=$(get_tmux_option "@cpu_revamped_popup_key" "M-c")
  [[ -z "${key}" || "${key}" == "off" ]] && return 0
  script="$(printf '%q' "${1}")"
  _tmux bind-key "${key}" run-shell "${script//"${hash}"/${hash}${hash}} popup"
}

export -f _tmux
export -f cpu_tmux_version
export -f cpu_version_ge
export -f cpu_popup_supported
export -f cpu_popup_command
export -f cpu_popup_open
export -f cpu_popup_bind
