#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _CPU_REVAMPED_CPU_LOADED _CPU_REVAMPED_RENDER_LOADED
  unset _CPU_REVAMPED_HISTORY_LOADED _CPU_REVAMPED_POPUP_LOADED _CPU_REVAMPED_DOCTOR_LOADED
  export CACHE_SYNC=1
  source "${BATS_TEST_DIRNAME}/../../../src/cpu.sh"
  read_cpu_percentage() { echo "77"; }
  read_cpu_temp() { echo "50"; }
  read_cpu_freq() { echo "4000"; }
  read_load_average() { echo "1.23"; }
  read_cpu_count() { echo "12"; }
  read_cpu_top_process() { echo "node 42%"; }
  read_cpu_governor() { echo "powersave"; }
  read_load_average5() { echo "2.34"; }
  read_load_average15() { echo "3.45"; }
}

teardown() {
  cleanup_test_environment
}

@test "cpu.sh dispatcher - functions are defined" {
  function_exists main
  function_exists cpu_refresh
  function_exists cpu_tick
  function_exists cpu_max_age
}

@test "cpu.sh dispatcher - cpu_max_age default is 5" {
  [[ "$(cpu_max_age)" == "5" ]]
}

@test "cpu.sh dispatcher - cpu_max_age honors the interval option" {
  set_tmux_option "@cpu_revamped_interval" "10"
  [[ "$(cpu_max_age)" == "10" ]]
}

@test "cpu.sh dispatcher - cpu_refresh caches every metric" {
  cpu_refresh
  [[ "$(cache_get percent)" == "77" ]]
  [[ "$(cache_get temp)" == "50" ]]
  [[ "$(cache_get freq)" == "4000" ]]
  [[ "$(cache_get load)" == "1.23" ]]
  [[ "$(cache_get count)" == "12" ]]
}

@test "cpu.sh dispatcher - freq, load, count subcommands render the cache" {
  run main freq
  [[ "${output}" == "4000MHz" ]]
  run main load
  [[ "${output}" == "1.23" ]]
  run main count
  [[ "${output}" == "12" ]]
}

@test "cpu.sh dispatcher - refresh subcommand caches values" {
  main refresh
  [[ "$(cache_get percent)" == "77" ]]
}

@test "cpu.sh dispatcher - percentage subcommand renders the cached load" {
  run main percentage
  [[ "${output}" == "77%" ]]
}

@test "cpu.sh dispatcher - icon subcommand maps the cached load" {
  run main icon
  [[ "${output}" == "▰▰▱" ]]
}

@test "cpu.sh dispatcher - temp subcommand renders the cached temperature" {
  run main temp
  [[ "${output}" == "50°C" ]]
}

@test "cpu.sh dispatcher - fg_color maps the cached load" {
  set_tmux_option "@cpu_revamped_medium_fg_color" "#[fg=yellow]"
  run main fg_color
  [[ "${output}" == "#[fg=yellow]" ]]
}

@test "cpu.sh dispatcher - bg_color maps the cached load" {
  set_tmux_option "@cpu_revamped_medium_bg_color" "#[bg=yellow]"
  run main bg_color
  [[ "${output}" == "#[bg=yellow]" ]]
}

@test "cpu.sh dispatcher - temp_icon maps the cached temperature" {
  set_tmux_option "@cpu_revamped_temp_low_icon" "COOL"
  run main temp_icon
  [[ "${output}" == "COOL" ]]
}

@test "cpu.sh dispatcher - temp_fg_color maps the cached temperature" {
  set_tmux_option "@cpu_revamped_temp_low_fg_color" "#[fg=blue]"
  run main temp_fg_color
  [[ "${output}" == "#[fg=blue]" ]]
}

@test "cpu.sh dispatcher - temp_bg_color maps the cached temperature" {
  set_tmux_option "@cpu_revamped_temp_low_bg_color" "#[bg=blue]"
  run main temp_bg_color
  [[ "${output}" == "#[bg=blue]" ]]
}

@test "cpu.sh dispatcher - unknown subcommand produces no output" {
  run main bogus
  [[ -z "${output}" ]]
}

@test "cpu.sh dispatcher - new functions are defined" {
  function_exists cpu_should_sample
  function_exists _cpu_attached_clients
}

@test "cpu.sh dispatcher - cpu_refresh caches the added metrics" {
  cpu_refresh
  [[ "$(cache_get load5)" == "2.34" ]]
  [[ "$(cache_get load15)" == "3.45" ]]
  [[ "$(cache_get top_process)" == "node 42%" ]]
  [[ "$(cache_get governor)" == "powersave" ]]
}

@test "cpu.sh dispatcher - cpu_refresh pushes the load into history" {
  cpu_refresh
  [[ "$(get_tmux_option @cpu_revamped_history)" == "77" ]]
}

@test "cpu.sh dispatcher - load5 and load15 subcommands render the cache" {
  run main load5
  [[ "${output}" == "2.34" ]]
  run main load15
  [[ "${output}" == "3.45" ]]
}

@test "cpu.sh dispatcher - top_process subcommand renders the cache" {
  run main top_process
  [[ "${output}" == "node 42%" ]]
}

@test "cpu.sh dispatcher - governor subcommand renders the cache" {
  run main governor
  [[ "${output}" == "powersave" ]]
}

@test "cpu.sh dispatcher - graph subcommand renders a sparkline" {
  run main graph
  [[ "${output}" == "▇" ]]
}

@test "cpu.sh dispatcher - load_color subcommand maps the relative load" {
  set_tmux_option "@cpu_revamped_low_fg_color" "#[fg=green]"
  run main load_color
  [[ "${output}" == "#[fg=green]" ]]
}

@test "cpu.sh dispatcher - alert subcommand fires above the threshold" {
  read_cpu_percentage() { echo "95"; }
  run main alert
  [[ "${output}" == "!" ]]
}

@test "cpu.sh dispatcher - popup subcommand calls the tmux seam" {
  _tmux() { printf '%s\n' "$*" >> "${TEST_TMPDIR}/calls"; }
  cpu_popup_supported() { return 0; }
  run main popup
  grep -q "display-popup" "${TEST_TMPDIR}/calls"
}

@test "cpu.sh dispatcher - doctor subcommand prints the report" {
  cpu_popup_supported() { return 0; }
  has_command() { return 1; }
  run main doctor
  [[ "${output}" == *"tmux-cpu-revamped doctor"* ]]
}

@test "cpu.sh dispatcher - bind subcommand binds the popup key" {
  _tmux() { printf '%s\n' "$*" >> "${TEST_TMPDIR}/calls"; }
  run main bind
  grep -q "bind-key M-c run-shell" "${TEST_TMPDIR}/calls"
}

@test "cpu.sh dispatcher - cpu_should_sample is true when throttle is off" {
  cpu_should_sample
}

@test "cpu.sh dispatcher - cpu_should_sample is false when detached and throttled" {
  set_tmux_option "@cpu_revamped_throttle_when_detached" "1"
  _cpu_attached_clients() { echo "0"; }
  ! cpu_should_sample
}

@test "cpu.sh dispatcher - cpu_should_sample is true when a client is attached" {
  set_tmux_option "@cpu_revamped_throttle_when_detached" "1"
  _cpu_attached_clients() { echo "2"; }
  cpu_should_sample
}

@test "cpu.sh dispatcher - cpu_should_sample is true on a non-numeric client count" {
  set_tmux_option "@cpu_revamped_throttle_when_detached" "1"
  _cpu_attached_clients() { echo "weird"; }
  cpu_should_sample
}

@test "cpu.sh dispatcher - cpu_tick skips the refresh when throttled" {
  set_tmux_option "@cpu_revamped_throttle_when_detached" "1"
  _cpu_attached_clients() { echo "0"; }
  cpu_tick
  [[ -z "$(cache_get percent)" ]]
}

@test "cpu.sh dispatcher - _cpu_attached_clients is callable" {
  run _cpu_attached_clients
  [[ "${output}" =~ ^[0-9]+$ ]]
}
