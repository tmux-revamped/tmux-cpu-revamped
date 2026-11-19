#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/tmux_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/tmux_helpers.bash"

screens() {
  printf 'host screen:\n'
  command tmux -S "${HOST}" capture-pane -p -t host || :
  printf 'options:\n'
  tmux show-options -g | grep cpu_revamped || :
  printf 'messages:\n'
  tmux show-messages | tail -n 5 || :
}

wait_for() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2; do
    "$@" && return 0
    sleep "${delay}"
  done
  "$@" && return 0
  screens
  return 1
}

attached() {
  local clients
  clients=$(tmux list-clients -F x 2>/dev/null)
  [[ -n "${clients}" ]]
}

holds() {
  local now
  now=$(tmux show-option -gqv "@cpu_revamped_$1")
  [[ "${now}" == "$2" ]]
}

host_shows() {
  local screen
  screen=$(command tmux -S "${HOST}" capture-pane -p -t host)
  [[ "${screen}" == *"$1"* ]]
}

host_lacks() {
  ! host_shows "$1"
}

said() {
  local messages
  messages=$(tmux show-messages)
  [[ "${messages}" == *"cpu-revamped: $1"* ]]
}

stand_in() {
  printf '#!/bin/sh\n{ set +x; } 2>/dev/null\n%s\n' "$2" >"${STUBS}/$1"
  chmod +x "${STUBS}/$1"
}

cpu() {
  stand_in iostat 'printf "          cpu    load average\n    us sy id   1m   5m   15m\n    10  5 85  0.50 1.25  2.00\n    20 10 70  0.50 1.25  2.00\n"'
  stand_in sysctl 'case "$*" in
"-n vm.loadavg") printf "{ 0.50 1.25 2.00 }\n" ;;
"-n hw.ncpu") printf "4\n" ;;
"-n machdep.cpu.brand_string") printf "Apple M2 Pro\n" ;;
"-n hw.cpufrequency") printf "3400000000\n" ;;
*) exit 1 ;;
esac'
  stand_in cat 'case "${1:-}" in
/proc/stat)
  count=0
  [ ! -f "'"${BATS_TEST_TMPDIR}"'/stat.count" ] || read -r count <"'"${BATS_TEST_TMPDIR}"'/stat.count"
  count=$((count + 1))
  printf "%s\n" "${count}" >"'"${BATS_TEST_TMPDIR}"'/stat.count"
  printf "cpu  %s 0 0 %s 0 0 0 0\n" "$((count * 30))" "$((count * 70))"
  ;;
/proc/cpuinfo) printf "processor\t: 0\ncpu MHz\t\t: 3400.000\n\nprocessor\t: 1\n\nprocessor\t: 2\n\nprocessor\t: 3\n" ;;
/proc/loadavg) printf "0.50 1.25 2.00 1/200 12345\n" ;;
*/cpufreq/scaling_cur_freq) printf "3400000\n" ;;
*/cpufreq/scaling_governor) printf "powersave\n" ;;
*) exec "'"${BATS_TEST_TMPDIR}"'/farm/cat" "$@" ;;
esac'
  stand_in ps 'printf "  1.0 /sbin/launchd\n 42.0 My #S app\n  2.0 tmux\n"'
  stand_in top 'while :; do
  printf "monitor: following\n"
  sleep 1
done'
}

monitor() {
  stand_in "$1" 'printf "monitor: '"$1"'\n"; read -r monitor_wait'
}

without_tools() {
  local farm="${BATS_TEST_TMPDIR}/farm" folder name
  mkdir -p "${farm}"
  local IFS=:
  for folder in ${PATH}; do
    [[ -d "${folder}" ]] || continue
    ln -s "${folder}"/* "${farm}/" 2>/dev/null || :
  done
  unset IFS
  for name in iostat sysctl ps top btop htop sensors macmon osx-cpu-temp istats; do
    rm -f "${farm:?}/${name}"
  done
  PATH="${STUBS}:${farm}"
}

setup() {
  unset BASH_ENV
  ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  STUBS="${BATS_TEST_TMPDIR}/stubs"
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}" "${STUBS}"
  without_tools
  cpu
  setup_tmux_server
  HOST="${TMUX_SOCKET}-host"
  tmux set-option -g default-command "env PS1='$ ' sh"
  tmux respawn-pane -k -t test:0.0 "env PS1='$ ' sh"
  tmux set-option -g status-interval 1
  tmux set-option -g status-left ''
  tmux set-option -g status-right-length 120
  tmux set-option -g @cpu_revamped_interval 1
  command tmux -S "${HOST}" -f /dev/null new-session -d -s host -x 120 -y 30 \
    "env -u TMUX TERM=xterm-256color tmux -u -S '${TMUX_SOCKET}' attach-session -t test"
  wait_for attached
}

teardown() {
  local daemon
  daemon=$(tmux show-option -gqv @cpu_revamped_ticker_pid 2>/dev/null) || daemon=""
  if [[ "${daemon}" =~ ^[0-9]+$ ]]; then
    pkill -P "${daemon}" 2>/dev/null || :
    kill "${daemon}" 2>/dev/null || :
  fi
  command tmux -S "${HOST}" kill-server 2>/dev/null || :
  rm -f "${HOST}"
  teardown_tmux_server
}

load_plugin() {
  local quoted
  quoted=$(printf '%s' "${1:-${ROOT}}" | sed "s/'/'\\\\''/g")
  tmux run-shell "'${quoted}/cpu-revamped.tmux'"
}

setting() {
  set_option "@cpu_revamped_$1" "$2"
}

press() {
  local key
  for key in "$@"; do
    command tmux -S "${HOST}" send-keys -t host "${key}"
  done
}

prefix_keys() {
  local table
  table=$(tmux list-keys -T prefix)
  awk '{ for (i = 1; i < NF; i++) { if ($i == "-T") { print $(i + 2); break } } }' <<<"${table}"
}
