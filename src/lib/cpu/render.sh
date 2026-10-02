#!/usr/bin/env bash
#
# render.sh: map cached CPU values to icons, colors, and formatted text.
#
# These are pure mappers. They read configuration from tmux options and the raw
# value passed in, then return a string. No sampling happens here.

[[ -n "${_CPU_REVAMPED_RENDER_LOADED:-}" ]] && return 0
_CPU_REVAMPED_RENDER_LOADED=1

_CPU_RENDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_CPU_RENDER_DIR}/../tmux/tmux-ops.sh"

# _cpu_level VALUE MEDIUM HIGH -> low|medium|high by integer thresholds.
_cpu_level() {
  local v="${1%%.*}" med="${2}" high="${3}"
  [[ "${v}" =~ ^-?[0-9]+$ ]] || v=0
  if (( v >= high )); then
    echo "high"
  elif (( v >= med )); then
    echo "medium"
  else
    echo "low"
  fi
}

# _cpu_c_to_f CELSIUS -> integer Fahrenheit.
_cpu_c_to_f() {
  [[ "${1}" =~ ^-?[0-9]+$ ]] || { echo ""; return 0; }
  LC_ALL=C awk -v c="${1}" 'BEGIN { printf "%.0f", (c * 9 / 5) + 32 }'
}

cpu_render_percentage() {
  local raw="${1}"
  [[ -z "${raw}" ]] && { echo ""; return 0; }
  local fmt
  fmt=$(get_tmux_option "@cpu_revamped_percentage_format" "%s%%")
  # shellcheck disable=SC2059
  printf "${fmt}" "${raw}"
}

cpu_render_icon() {
  local level
  level=$(_cpu_level "${1:-0}" "$(get_tmux_option "@cpu_revamped_medium_thresh" "30")" \
    "$(get_tmux_option "@cpu_revamped_high_thresh" "80")")
  case "${level}" in
    high)   get_tmux_option "@cpu_revamped_high_icon" "▰▰▰" ;;
    medium) get_tmux_option "@cpu_revamped_medium_icon" "▰▰▱" ;;
    *)      get_tmux_option "@cpu_revamped_low_icon" "▰▱▱" ;;
  esac
}

cpu_render_fg() {
  local level
  level=$(_cpu_level "${1:-0}" "$(get_tmux_option "@cpu_revamped_medium_thresh" "30")" \
    "$(get_tmux_option "@cpu_revamped_high_thresh" "80")")
  get_tmux_option "@cpu_revamped_${level}_fg_color" ""
}

cpu_render_bg() {
  local level
  level=$(_cpu_level "${1:-0}" "$(get_tmux_option "@cpu_revamped_medium_thresh" "30")" \
    "$(get_tmux_option "@cpu_revamped_high_thresh" "80")")
  get_tmux_option "@cpu_revamped_${level}_bg_color" ""
}

# cpu_render_temp RAW_CELSIUS -> formatted temperature honoring the unit option.
cpu_render_temp() {
  local raw="${1}"
  [[ -z "${raw}" ]] && { echo ""; return 0; }
  local unit value
  unit=$(get_tmux_option "@cpu_revamped_temp_unit" "C")
  if [[ "${unit}" == "F" ]]; then
    value=$(_cpu_c_to_f "${raw}")
  else
    value="${raw}"
  fi
  local fmt
  fmt=$(get_tmux_option "@cpu_revamped_temp_format" "%s°${unit}")
  # shellcheck disable=SC2059
  printf "${fmt}" "${value}"
}

_cpu_temp_level() {
  _cpu_level "${1:-0}" "$(get_tmux_option "@cpu_revamped_temp_medium_thresh" "65")" \
    "$(get_tmux_option "@cpu_revamped_temp_high_thresh" "80")"
}

cpu_render_temp_icon() {
  [[ -z "${1}" ]] && { echo ""; return 0; }
  case "$(_cpu_temp_level "${1}")" in
    high)   get_tmux_option "@cpu_revamped_temp_high_icon" "" ;;
    medium) get_tmux_option "@cpu_revamped_temp_medium_icon" "" ;;
    *)      get_tmux_option "@cpu_revamped_temp_low_icon" "" ;;
  esac
}

cpu_render_temp_fg() {
  [[ -z "${1}" ]] && { echo ""; return 0; }
  get_tmux_option "@cpu_revamped_temp_$(_cpu_temp_level "${1}")_fg_color" ""
}

cpu_render_temp_bg() {
  [[ -z "${1}" ]] && { echo ""; return 0; }
  get_tmux_option "@cpu_revamped_temp_$(_cpu_temp_level "${1}")_bg_color" ""
}

cpu_render_freq() {
  [[ -z "${1}" || "${1}" == "0" ]] && { echo ""; return 0; }
  local fmt
  fmt=$(get_tmux_option "@cpu_revamped_freq_format" "%sMHz")
  # shellcheck disable=SC2059
  printf "${fmt}" "${1}"
}

cpu_render_load() {
  [[ -z "${1}" ]] && { echo ""; return 0; }
  local fmt
  fmt=$(get_tmux_option "@cpu_revamped_load_format" "%s")
  # shellcheck disable=SC2059
  printf "${fmt}" "${1}"
}

cpu_render_count() {
  echo "${1}"
}

# cpu_render_load_color LOAD COUNT -> the tier fg color for the load relative to
# core count, so the same absolute load reads green on a big box and red on a
# small one. Reuses the load tier color options.
cpu_render_load_color() {
  local load="${1}" count="${2}"
  [[ -z "${load}" ]] && { echo ""; return 0; }
  [[ "${count}" =~ ^[0-9]+$ ]] && (( count > 0 )) || count=1
  local med high level
  med=$(get_tmux_option "@cpu_revamped_load_medium_ratio" "0.7")
  high=$(get_tmux_option "@cpu_revamped_load_high_ratio" "1.0")
  level=$(awk -v l="${load}" -v c="${count}" -v m="${med}" -v h="${high}" 'BEGIN { r = l / c; if (r >= h) print "high"; else if (r >= m) print "medium"; else print "low" }')
  get_tmux_option "@cpu_revamped_${level}_fg_color" ""
}

# cpu_render_alert PERCENT TEMP -> an alert glyph when load or temperature is at
# or above its high threshold, empty otherwise.
cpu_render_alert() {
  local pct="${1}" temp="${2}"
  local hi thi
  hi=$(get_tmux_option "@cpu_revamped_high_thresh" "80")
  thi=$(get_tmux_option "@cpu_revamped_temp_high_thresh" "80")
  local p="${pct%%.*}" t="${temp%%.*}"
  [[ "${p}" =~ ^-?[0-9]+$ ]] || p=0
  local hot=0
  (( p >= hi )) && hot=1
  if [[ "${t}" =~ ^-?[0-9]+$ ]] && (( t >= thi )); then
    hot=1
  fi
  if (( hot == 1 )); then
    get_tmux_option "@cpu_revamped_alert_icon" "!"
  else
    echo ""
  fi
}

# cpu_render_top_process VALUE -> the cached top-process string verbatim.
cpu_render_top_process() {
  echo "${1}"
}

# cpu_render_governor VALUE -> the cached governor string verbatim.
cpu_render_governor() {
  echo "${1}"
}

export -f cpu_render_freq
export -f cpu_render_load
export -f cpu_render_count
export -f _cpu_level
export -f _cpu_c_to_f
export -f cpu_render_percentage
export -f cpu_render_icon
export -f cpu_render_fg
export -f cpu_render_bg
export -f cpu_render_temp
export -f _cpu_temp_level
export -f cpu_render_temp_icon
export -f cpu_render_temp_fg
export -f cpu_render_temp_bg
export -f cpu_render_load_color
export -f cpu_render_alert
export -f cpu_render_top_process
export -f cpu_render_governor
