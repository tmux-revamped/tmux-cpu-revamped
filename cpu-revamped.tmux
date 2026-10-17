#!/usr/bin/env bash
#
# cpu-revamped.tmux: TPM entry point.
#
# Replaces the #{cpu_*} placeholders in status-left and status-right with calls
# to the dispatcher. The dispatcher reads cached values, so the status render
# never blocks on a CPU sample. It also binds the detail-popup key.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CPU_CMD="${PLUGIN_DIR}/src/cpu.sh"
HASH="#"
CPU_CMD_QUOTED="$(printf '%q' "${CPU_CMD}")"
CPU_CMD_QUOTED="${CPU_CMD_QUOTED//"${HASH}"/${HASH}${HASH}}"

metrics=(
  percentage icon fg_color bg_color temp temp_icon temp_fg_color temp_bg_color
  freq load load5 load15 count graph top_process governor load_color alert
)

render_mode="$(tmux show-option -gqv "@cpu_revamped_render")"

command_for() {
  if [[ "${render_mode}" == "options" ]]; then
    printf '#{E:@cpu_revamped_out_%s}' "${1}"
  else
    printf '#(%s %s)' "${CPU_CMD_QUOTED}" "${1}"
  fi
}

interpolate() {
  local value="${1}" metric placeholder out rest
  for metric in "${metrics[@]}"; do
    placeholder="#{cpu_${metric}}"
    out=""
    rest="${value}"
    while [[ "${rest}" == *"${placeholder}"* ]]; do
      out="${out}${rest%%"${placeholder}"*}$(command_for "${metric}")"
      rest="${rest#*"${placeholder}"}"
    done
    value="${out}${rest}"
  done
  echo "${value}"
}

used_metrics() {
  local text="${1}" metric used=""
  for metric in "${metrics[@]}"; do
    if [[ "${text}" == *"#{cpu_${metric}}"* || "${text}" == *"@cpu_revamped_out_${metric}}"* ]]; then
      used="${used:+${used} }${metric}"
    fi
  done
  echo "${used}"
}

update_option() {
  local option="${1}"
  local current
  current=$(tmux show-option -gqv "${option}")
  tmux set-option -gq "${option}" "$(interpolate "${current}")"
}

chmod +x "${CPU_CMD}" 2>/dev/null || true

status_text="$(tmux show-option -gqv status-left) $(tmux show-option -gqv status-right)"
tmux set-option -gq "@cpu_revamped_published" "$(used_metrics "${status_text}")"

update_option "status-left"
update_option "status-right"

if [[ "${render_mode}" == "options" ]]; then
  "${CPU_CMD}" start 2>/dev/null || true
else
  tmux set-option -gqu "@cpu_revamped_ticker_pid"
fi

# Bind the detail-popup key. The dispatcher routes through the _tmux seam.
"${CPU_CMD}" bind 2>/dev/null || true
