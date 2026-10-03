#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

ENTRY="${BATS_TEST_DIRNAME}/../../cpu-revamped.tmux"

setup() {
  setup_test_environment
  export SPAWN_LOG="${TEST_TMPDIR}/spawn.log"
  nohup() { printf '%s\n' "$*" >> "${SPAWN_LOG}"; }
  export -f nohup
}

teardown() {
  cleanup_test_environment
}

@test "entry - jobs mode turns a placeholder into a dispatcher call" {
  set_tmux_option "status-right" "[#{cpu_percentage}]"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file status-right)")" == "[#($(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/src/cpu.sh percentage)]" ]]
}

@test "entry - options mode turns a placeholder into an option read" {
  set_tmux_option "@cpu_revamped_render" "options"
  set_tmux_option "status-right" "[#{cpu_percentage}]"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file status-right)")" == "[#{E:@cpu_revamped_out_percentage}]" ]]
}

@test "entry - options mode starts the ticker" {
  set_tmux_option "@cpu_revamped_render" "options"
  set_tmux_option "status-right" "[#{cpu_percentage}]"

  bash "${ENTRY}"

  [[ "$(cat "${SPAWN_LOG}")" == *"/src/cpu.sh daemon" ]]
}

@test "entry - jobs mode starts no ticker" {
  set_tmux_option "status-right" "[#{cpu_percentage}]"

  bash "${ENTRY}"

  [ ! -f "${SPAWN_LOG}" ]
}

@test "entry - only metrics on the status line are published" {
  set_tmux_option "status-left" "#{cpu_temp}"
  set_tmux_option "status-right" "#{cpu_fg_color}#{cpu_percentage}"

  bash "${ENTRY}"

  [[ "$(cat "$(_mock_opt_file @cpu_revamped_published)")" == "percentage fg_color temp" ]]
}
