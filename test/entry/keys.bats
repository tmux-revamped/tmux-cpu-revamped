#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031,SC2154

# shellcheck source=test/tmux_helpers.bash
source "${BATS_TEST_DIRNAME}/../tmux_helpers.bash"

wait_for() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2; do
    "$@" && return 0
    sleep "${delay}"
  done
  "$@" && return 0
  command tmux -S "${HOST}" capture-pane -p -t host || :
  return 1
}

attached() {
  local clients
  clients=$(tmux list-clients -F x 2>/dev/null)
  [[ -n "${clients}" ]]
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
  [[ "${messages}" == *"$1"* ]]
}

stand_in() {
  printf '#!/bin/sh\nprintf "%%s\\n" "%s stand-in running $*"\nread -r stand_in_wait\n' "$1" >"${STUBS}/$1"
  chmod +x "${STUBS}/$1"
}

without_monitors() {
  local folder old_ifs="${IFS}"
  FARM="${BATS_TEST_TMPDIR}/farm"
  mkdir -p "${FARM}"
  IFS=:
  for folder in ${PATH}; do
    [[ -d "${folder}" ]] || continue
    ln -s "${folder}"/* "${FARM}/" 2>/dev/null || :
  done
  IFS="${old_ifs}"
  rm -f "${FARM}/btop" "${FARM}/htop" "${FARM}/top"
  PATH="${STUBS}:${FARM}"
}

setup() {
  ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  STUBS="${BATS_TEST_TMPDIR}/stubs"
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "${HOME}" "${STUBS}"
  HOST="${TMUX_SOCKET}-host"
  without_monitors
}

serve() {
  setup_tmux_server
  tmux set-option -g default-command "env PS1='$ ' sh"
  command tmux -S "${HOST}" -f /dev/null new-session -d -s host -x 120 -y 40 \
    "env -u TMUX TERM=xterm-256color tmux -S '${TMUX_SOCKET}' attach-session -t test"
  wait_for attached
  tmux run-shell "'${ROOT}/cpu-revamped.tmux'"
}

teardown() {
  command tmux -S "${HOST}" kill-server 2>/dev/null || :
  rm -f "${HOST}"
  teardown_tmux_server
}

press() {
  local key
  for key in "$@"; do
    command tmux -S "${HOST}" send-keys -t host "${key}"
  done
}

@test "keys - prefix M-c opens the detail popup running btop, and it stays until btop ends" {
  # Arrange
  stand_in btop
  stand_in htop
  serve

  # Act
  press C-b M-c

  # Assert
  wait_for host_shows "btop stand-in running"
  press Enter
  wait_for host_lacks "btop stand-in running"
}

@test "keys - without btop the popup runs htop" {
  # Arrange
  stand_in htop
  stand_in top
  serve

  # Act
  press C-b M-c

  # Assert
  wait_for host_shows "htop stand-in running"
}

@test "keys - without btop and htop the popup runs top" {
  # Arrange
  stand_in top
  serve

  # Act
  press C-b M-c

  # Assert
  wait_for host_shows "top stand-in running"
}

@test "keys - a popup command that is not installed is named in a message" {
  # Arrange
  stand_in top
  serve
  tmux set-option -g @cpu_revamped_popup_command "no-such-monitor --tree"

  # Act
  press C-b M-c

  # Assert
  wait_for said "cpu-revamped: no-such-monitor is not installed"
}

@test "keys - the popup command the person set runs with its arguments, on the key they set" {
  # Arrange
  stand_in glances
  setup_tmux_server
  tmux set-option -g @cpu_revamped_popup_key F5
  tmux set-option -g @cpu_revamped_popup_command "glances --tree"
  command tmux -S "${HOST}" -f /dev/null new-session -d -s host -x 120 -y 40 \
    "env -u TMUX TERM=xterm-256color tmux -S '${TMUX_SOCKET}' attach-session -t test"
  wait_for attached
  tmux run-shell "'${ROOT}/cpu-revamped.tmux'"

  # Act
  press C-b F5

  # Assert
  wait_for host_shows "glances stand-in running --tree"
}
