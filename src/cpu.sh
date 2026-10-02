#!/usr/bin/env bash
#
# cpu.sh: command dispatcher for tmux-cpu-revamped.
#
# Each status placeholder runs this with a subcommand. The dispatcher triggers a
# guarded background refresh, then maps the cached raw value to the requested
# output. The slow sampling happens only inside the worker, off the render path.
#
# Usage:
#   cpu.sh percentage | icon | fg_color | bg_color
#   cpu.sh temp | temp_icon | temp_fg_color | temp_bg_color
#   cpu.sh freq | load | load5 | load15 | count
#   cpu.sh graph | top_process | governor | load_color | alert
#   cpu.sh refresh | popup | doctor | bind

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export CACHE_PREFIX="cpu_revamped"
export PLUGIN_LOG_NS="cpu-revamped"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/has-command.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/platform.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/cache.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/cpu/cpu.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/cpu/render.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/cpu/history.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/cpu/popup.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/cpu/doctor.sh"

# cpu_max_age -> how many seconds a sample stays fresh.
cpu_max_age() {
  get_tmux_option "@cpu_revamped_interval" "5"
}

# _cpu_attached_clients -> count of clients attached to this tmux server.
_cpu_attached_clients() {
  tmux list-clients 2>/dev/null | wc -l | tr -d ' '
}

# cpu_should_sample -> 0 when a refresh is allowed. When the throttle option is
# on and no client is attached, the worker stays idle to save battery.
cpu_should_sample() {
  [[ "$(get_tmux_option "@cpu_revamped_throttle_when_detached" "0")" == "1" ]] || return 0
  local clients
  clients=$(_cpu_attached_clients)
  [[ "${clients}" =~ ^[0-9]+$ ]] || return 0
  (( clients > 0 )) && return 0
  return 1
}

# cpu_refresh -> the worker: sample every metric once and cache it.
cpu_refresh() {
  local percent
  percent="$(read_cpu_percentage)"
  cache_set percent "${percent}"
  cpu_history_push "${percent}" "$(get_tmux_option "@cpu_revamped_graph_width" "20")"
  cache_set temp "$(read_cpu_temp)"
  cache_set freq "$(read_cpu_freq)"
  cache_set load "$(read_load_average)"
  cache_set load5 "$(read_load_average5)"
  cache_set load15 "$(read_load_average15)"
  cache_set count "$(read_cpu_count)"
  cache_set top_process "$(read_cpu_top_process)"
  cache_set governor "$(read_cpu_governor)"
}

# cpu_tick -> trigger a guarded background refresh when the sample is stale.
cpu_tick() {
  cpu_should_sample || return 0
  cache_refresh_if_stale percent "$(cpu_max_age)" cpu_refresh
}

cpu_render_metric() {
  local cmd="${1}"
  case "${cmd}" in
    percentage)    cpu_render_percentage "$(cache_get percent)" ;;
    icon)          cpu_render_icon "$(cache_get percent)" ;;
    fg_color)      cpu_render_fg "$(cache_get percent)" ;;
    bg_color)      cpu_render_bg "$(cache_get percent)" ;;
    temp)          cpu_render_temp "$(cache_get temp)" ;;
    temp_icon)     cpu_render_temp_icon "$(cache_get temp)" ;;
    temp_fg_color) cpu_render_temp_fg "$(cache_get temp)" ;;
    temp_bg_color) cpu_render_temp_bg "$(cache_get temp)" ;;
    freq)          cpu_render_freq "$(cache_get freq)" ;;
    load)          cpu_render_load "$(cache_get load)" ;;
    load5)         cpu_render_load "$(cache_get load5)" ;;
    load15)        cpu_render_load "$(cache_get load15)" ;;
    count)         cpu_render_count "$(cache_get count)" ;;
    graph)         cpu_render_graph ;;
    top_process)   cpu_render_top_process "$(cache_get top_process)" ;;
    governor)      cpu_render_governor "$(cache_get governor)" ;;
    load_color)    cpu_render_load_color "$(cache_get load)" "$(cache_get count)" ;;
    alert)         cpu_render_alert "$(cache_get percent)" "$(cache_get temp)" ;;
    *)             return 0 ;;
  esac
}

cpu_is_labelled() {
  case "${1}" in
    percentage | temp | freq | load | load5 | load15 | count | graph | top_process | governor) return 0 ;;
    *) return 1 ;;
  esac
}

cpu_nerd_label() {
  case "${1}" in
    percentage) printf '\xf3\xb0\x8a\x9a' ;;
    temp) printf '\xf3\xb0\x94\x8f' ;;
    freq) printf '\xf3\xb0\x93\x85' ;;
    load) printf '\xf3\xb0\x97\x91' ;;
    load5) printf '\xf3\xb0\x97\x91' ;;
    load15) printf '\xf3\xb0\x97\x91' ;;
    count) printf '\xf3\xb0\x98\x9a' ;;
    graph) printf '\xf3\xb0\x9e\xb1' ;;
    top_process) printf '\xf3\xb0\xa3\x86' ;;
    governor) printf '\xf3\xb0\x98\xae' ;;
    *) printf '' ;;
  esac
}

cpu_option_exists() {
  [[ -n "$(tmux show-option -gq "${1}" 2>/dev/null)" ]]
}

cpu_label() {
  local option="@cpu_revamped_${1}_label"
  if cpu_option_exists "${option}"; then
    tmux show-option -gqv "${option}" 2>/dev/null
  elif [[ "$(get_tmux_option "@cpu_revamped_icons" "ascii")" == "nerd" ]]; then
    cpu_nerd_label "${1}"
  fi
}

cpu_labelled() {
  local metric="${1}" value="${2}" label
  [[ -n "${value}" ]] || return 0
  label="$(cpu_label "${metric}")"
  if [[ -n "${label}" ]]; then
    printf '%s %s\n' "${label}" "${value}"
  else
    printf '%s\n' "${value}"
  fi
}

main() {
  local cmd="${1:-}"

  case "${cmd}" in
    refresh) cpu_refresh; return 0 ;;
    popup)   cpu_popup_open; return 0 ;;
    doctor)  cpu_doctor; return 0 ;;
    bind)    cpu_popup_bind "${PLUGIN_DIR}/src/cpu.sh"; return 0 ;;
  esac

  cpu_tick

  local out
  out="$(cpu_render_metric "${cmd}")"
  if cpu_is_labelled "${cmd}"; then
    cpu_labelled "${cmd}" "${out}"
  elif [[ -n "${out}" ]]; then
    printf '%s\n' "${out}"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
