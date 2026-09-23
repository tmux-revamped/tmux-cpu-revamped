#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _CPU_REVAMPED_POPUP_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/cpu/popup.sh"
  CALLS="${TEST_TMPDIR}/tmux_calls"
}

teardown() {
  cleanup_test_environment
}

@test "popup.sh - functions are defined" {
  function_exists _tmux
  function_exists cpu_tmux_version
  function_exists cpu_version_ge
  function_exists cpu_popup_supported
  function_exists cpu_popup_command
  function_exists cpu_popup_open
  function_exists cpu_popup_bind
}

@test "popup.sh - _tmux seam forwards to tmux" {
  set_tmux_option @probe seam
  _tmux set-option -gq @probe seam
  [[ "$(get_tmux_option @probe)" == "seam" ]]
}

@test "popup.sh - cpu_tmux_version parses a plain version" {
  [[ "$(cpu_tmux_version "tmux 3.4")" == "3.4" ]]
}

@test "popup.sh - cpu_tmux_version parses a next build" {
  [[ "$(cpu_tmux_version "tmux next-3.5a")" == "3.5" ]]
}

@test "popup.sh - cpu_version_ge compares versions" {
  cpu_version_ge "3.4" "3.2"
  cpu_version_ge "3.2" "3.2"
  cpu_version_ge "4.0" "3.2"
  ! cpu_version_ge "3.1" "3.2"
  ! cpu_version_ge "2.9" "3.2"
}

@test "popup.sh - cpu_version_ge is false for an empty version" {
  ! cpu_version_ge "" "3.2"
}

@test "popup.sh - cpu_popup_supported is true on a modern tmux" {
  _tmux() { echo "tmux 3.4"; }
  cpu_popup_supported
}

@test "popup.sh - cpu_popup_supported is false on an old tmux" {
  _tmux() { echo "tmux 3.0"; }
  ! cpu_popup_supported
}

@test "popup.sh - cpu_popup_command defaults to btop" {
  [[ "$(cpu_popup_command)" == "btop" ]]
}

@test "popup.sh - cpu_popup_command honors the option" {
  set_tmux_option "@cpu_revamped_popup_command" "htop"
  [[ "$(cpu_popup_command)" == "htop" ]]
}

@test "popup.sh - cpu_popup_open uses display-popup when supported" {
  _tmux() { printf '%s\n' "$*" >> "${CALLS}"; }
  cpu_popup_supported() { return 0; }
  cpu_popup_open
  grep -q "display-popup -E -w 80% -h 80% btop" "${CALLS}"
}

@test "popup.sh - cpu_popup_open honors width, height, and command options" {
  _tmux() { printf '%s\n' "$*" >> "${CALLS}"; }
  cpu_popup_supported() { return 0; }
  set_tmux_option "@cpu_revamped_popup_command" "htop"
  set_tmux_option "@cpu_revamped_popup_width" "60%"
  set_tmux_option "@cpu_revamped_popup_height" "50%"
  cpu_popup_open
  grep -q "display-popup -E -w 60% -h 50% htop" "${CALLS}"
}

@test "popup.sh - cpu_popup_open warns when tmux is too old" {
  _tmux() { printf '%s\n' "$*" >> "${CALLS}"; }
  cpu_popup_supported() { return 1; }
  cpu_popup_open
  grep -q "display-message" "${CALLS}"
  ! grep -q "display-popup" "${CALLS}"
}

@test "popup.sh - cpu_popup_bind binds the default key" {
  _tmux() { printf '%s\n' "$*" >> "${CALLS}"; }
  cpu_popup_bind "/path/to/cpu.sh"
  grep -q "bind-key M-c run-shell /path/to/cpu.sh popup" "${CALLS}"
}

@test "popup.sh - cpu_popup_bind honors the key option" {
  _tmux() { printf '%s\n' "$*" >> "${CALLS}"; }
  set_tmux_option "@cpu_revamped_popup_key" "F2"
  cpu_popup_bind "/path/to/cpu.sh"
  grep -q "bind-key F2 run-shell /path/to/cpu.sh popup" "${CALLS}"
}
