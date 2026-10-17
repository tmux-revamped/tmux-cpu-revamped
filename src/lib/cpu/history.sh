#!/usr/bin/env bash

[[ -n "${_CPU_REVAMPED_HISTORY_LOADED:-}" ]] && return 0
_CPU_REVAMPED_HISTORY_LOADED=1

_CPU_HISTORY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_CPU_HISTORY_DIR}/../tmux/tmux-ops.sh"

CPU_HISTORY_OPT="@cpu_revamped_history"

cpu_sparkline() {
  local list="${1}"
  [[ -z "${list}" ]] && { echo ""; return 0; }
  local -a ramp=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
  local -a values
  read -ra values <<< "${list}"
  local out="" v idx
  local i
  for (( i = 0; i < ${#values[@]}; i++ )); do
    v="${values[i]%%.*}"
    [[ "${v}" =~ ^-?[0-9]+$ ]] || v=0
    (( v < 0 )) && v=0
    (( v > 100 )) && v=100
    idx=$(( v * 8 / 101 ))
    out="${out}${ramp[idx]}"
  done
  echo "${out}"
}

cpu_history_push() {
  local value="${1}" max="${2:-20}"
  [[ "${max}" =~ ^[0-9]+$ ]] && (( max > 0 )) || max=20
  local v="${value%%.*}"
  [[ "${v}" =~ ^-?[0-9]+$ ]] || return 0
  local hist
  hist=$(get_tmux_option "${CPU_HISTORY_OPT}" "")
  local -a a
  read -ra a <<< "${hist} ${v}"
  local n="${#a[@]}" start=0
  (( n > max )) && start=$(( n - max ))
  local out="" i
  for (( i = start; i < n; i++ )); do
    out="${out}${a[i]} "
  done
  set_tmux_option "${CPU_HISTORY_OPT}" "${out% }"
}

cpu_history_get() {
  get_tmux_option "${CPU_HISTORY_OPT}" ""
}

cpu_render_graph() {
  local hist
  hist=$(cpu_history_get)
  [[ -z "${hist}" ]] && { echo ""; return 0; }
  cpu_sparkline "${hist}"
}

export -f cpu_sparkline
export -f cpu_history_push
export -f cpu_history_get
export -f cpu_render_graph
