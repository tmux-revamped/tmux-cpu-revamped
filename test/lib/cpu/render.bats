#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _CPU_REVAMPED_RENDER_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/cpu/render.sh"
}

teardown() {
  cleanup_test_environment
}

@test "render.sh - _cpu_level classifies low, medium, high" {
  [[ "$(_cpu_level 10 30 80)" == "low" ]]
  [[ "$(_cpu_level 50 30 80)" == "medium" ]]
  [[ "$(_cpu_level 90 30 80)" == "high" ]]
}

@test "render.sh - _cpu_level treats non-numeric as zero" {
  [[ "$(_cpu_level abc 30 80)" == "low" ]]
}

@test "render.sh - _cpu_level strips a decimal part" {
  [[ "$(_cpu_level 85.9 30 80)" == "high" ]]
}

@test "render.sh - _cpu_c_to_f converts Celsius" {
  [[ "$(_cpu_c_to_f 50)" == "122" ]]
}

@test "render.sh - _cpu_c_to_f is empty for junk" {
  [[ -z "$(_cpu_c_to_f xx)" ]]
}

@test "render.sh - cpu_render_percentage is empty on cold start" {
  [[ -z "$(cpu_render_percentage "")" ]]
}

@test "render.sh - cpu_render_percentage uses the default format" {
  [[ "$(cpu_render_percentage 42)" == "42%" ]]
}

@test "render.sh - cpu_render_percentage honors a custom format" {
  set_tmux_option "@cpu_revamped_percentage_format" "[%s]"
  [[ "$(cpu_render_percentage 42)" == "[42]" ]]
}

@test "render.sh - cpu_render_icon picks the level icon" {
  [[ "$(cpu_render_icon 90)" == "▰▰▰" ]]
  [[ "$(cpu_render_icon 50)" == "▰▰▱" ]]
  [[ "$(cpu_render_icon 5)" == "▰▱▱" ]]
}

@test "render.sh - cpu_render_icon honors a custom icon" {
  set_tmux_option "@cpu_revamped_high_icon" "HOT"
  [[ "$(cpu_render_icon 95)" == "HOT" ]]
}

@test "render.sh - cpu_render_fg is empty by default" {
  [[ -z "$(cpu_render_fg 95)" ]]
}

@test "render.sh - cpu_render_fg returns the configured color" {
  set_tmux_option "@cpu_revamped_high_fg_color" "#[fg=red]"
  [[ "$(cpu_render_fg 95)" == "#[fg=red]" ]]
}

@test "render.sh - cpu_render_bg returns the configured color" {
  set_tmux_option "@cpu_revamped_low_bg_color" "#[bg=green]"
  [[ "$(cpu_render_bg 5)" == "#[bg=green]" ]]
}

@test "render.sh - cpu_render_fg passes a named color through verbatim" {
  set_tmux_option "@cpu_revamped_high_fg_color" "#[fg=red]"
  [[ "$(cpu_render_fg 95)" == "#[fg=red]" ]]
}

@test "render.sh - cpu_render_fg passes a 256-palette color through verbatim" {
  set_tmux_option "@cpu_revamped_high_fg_color" "#[fg=colour203]"
  [[ "$(cpu_render_fg 95)" == "#[fg=colour203]" ]]
}

@test "render.sh - cpu_render_fg passes a hex color through verbatim" {
  set_tmux_option "@cpu_revamped_high_fg_color" "#[fg=#f38ba8]"
  [[ "$(cpu_render_fg 95)" == "#[fg=#f38ba8]" ]]
}

@test "render.sh - cpu_render_fg passes a combined fg and bg spec through verbatim" {
  set_tmux_option "@cpu_revamped_high_fg_color" "#[fg=#f38ba8,bg=#1e1e2e]"
  [[ "$(cpu_render_fg 95)" == "#[fg=#f38ba8,bg=#1e1e2e]" ]]
}

@test "render.sh - cpu_render_fg passes a bright color through verbatim" {
  set_tmux_option "@cpu_revamped_high_fg_color" "#[fg=brightred]"
  [[ "$(cpu_render_fg 95)" == "#[fg=brightred]" ]]
}

@test "render.sh - cpu_render_temp_fg passes a named color through verbatim" {
  set_tmux_option "@cpu_revamped_temp_high_fg_color" "#[fg=red]"
  [[ "$(cpu_render_temp_fg 95)" == "#[fg=red]" ]]
}

@test "render.sh - cpu_render_temp_fg passes a 256-palette color through verbatim" {
  set_tmux_option "@cpu_revamped_temp_high_fg_color" "#[fg=colour203]"
  [[ "$(cpu_render_temp_fg 95)" == "#[fg=colour203]" ]]
}

@test "render.sh - cpu_render_temp_fg passes a hex color through verbatim" {
  set_tmux_option "@cpu_revamped_temp_high_fg_color" "#[fg=#f38ba8]"
  [[ "$(cpu_render_temp_fg 95)" == "#[fg=#f38ba8]" ]]
}

@test "render.sh - cpu_render_temp_fg passes a combined fg and bg spec through verbatim" {
  set_tmux_option "@cpu_revamped_temp_high_fg_color" "#[fg=#f38ba8,bg=#1e1e2e]"
  [[ "$(cpu_render_temp_fg 95)" == "#[fg=#f38ba8,bg=#1e1e2e]" ]]
}

@test "render.sh - cpu_render_temp_fg passes a bright color through verbatim" {
  set_tmux_option "@cpu_revamped_temp_high_fg_color" "#[fg=brightred]"
  [[ "$(cpu_render_temp_fg 95)" == "#[fg=brightred]" ]]
}

@test "render.sh - cpu_render_temp is empty on cold start" {
  [[ -z "$(cpu_render_temp "")" ]]
}

@test "render.sh - cpu_render_temp formats Celsius by default" {
  [[ "$(cpu_render_temp 50)" == "50°C" ]]
}

@test "render.sh - cpu_render_temp converts to Fahrenheit" {
  set_tmux_option "@cpu_revamped_temp_unit" "F"
  [[ "$(cpu_render_temp 50)" == "122°F" ]]
}

@test "render.sh - cpu_render_temp_icon is empty on cold start" {
  [[ -z "$(cpu_render_temp_icon "")" ]]
}

@test "render.sh - cpu_render_temp_icon picks the level icon" {
  set_tmux_option "@cpu_revamped_temp_high_icon" "HOT"
  [[ "$(cpu_render_temp_icon 95)" == "HOT" ]]
}

@test "render.sh - cpu_render_temp_fg returns the configured color" {
  set_tmux_option "@cpu_revamped_temp_high_fg_color" "#[fg=red]"
  [[ "$(cpu_render_temp_fg 95)" == "#[fg=red]" ]]
}

@test "render.sh - cpu_render_temp_bg returns the configured color" {
  set_tmux_option "@cpu_revamped_temp_low_bg_color" "#[bg=blue]"
  [[ "$(cpu_render_temp_bg 40)" == "#[bg=blue]" ]]
}

@test "render.sh - cpu_render_temp_fg is empty on cold start" {
  [[ -z "$(cpu_render_temp_fg "")" ]]
}

@test "render.sh - cpu_render_freq is empty on cold start or zero" {
  [[ -z "$(cpu_render_freq "")" ]]
  [[ -z "$(cpu_render_freq 0)" ]]
}

@test "render.sh - cpu_render_freq formats with default and custom" {
  [[ "$(cpu_render_freq 4000)" == "4000MHz" ]]
  set_tmux_option "@cpu_revamped_freq_format" "%s MHz"
  [[ "$(cpu_render_freq 4000)" == "4000 MHz" ]]
}

@test "render.sh - cpu_render_load formats with default and custom" {
  [[ -z "$(cpu_render_load "")" ]]
  [[ "$(cpu_render_load 1.23)" == "1.23" ]]
  set_tmux_option "@cpu_revamped_load_format" "load %s"
  [[ "$(cpu_render_load 1.23)" == "load 1.23" ]]
}

@test "render.sh - cpu_render_count echoes the value" {
  [[ "$(cpu_render_count 12)" == "12" ]]
}

@test "render.sh - cpu_render_load_color is empty on cold start" {
  [[ -z "$(cpu_render_load_color "" 8)" ]]
}

@test "render.sh - cpu_render_load_color picks high when saturated" {
  set_tmux_option "@cpu_revamped_high_fg_color" "#[fg=red]"
  [[ "$(cpu_render_load_color 16 8)" == "#[fg=red]" ]]
}

@test "render.sh - cpu_render_load_color picks medium near capacity" {
  set_tmux_option "@cpu_revamped_medium_fg_color" "#[fg=yellow]"
  [[ "$(cpu_render_load_color 6 8)" == "#[fg=yellow]" ]]
}

@test "render.sh - cpu_render_load_color picks low when idle" {
  set_tmux_option "@cpu_revamped_low_fg_color" "#[fg=green]"
  [[ "$(cpu_render_load_color 1 8)" == "#[fg=green]" ]]
}

@test "render.sh - cpu_render_load_color treats an invalid count as one" {
  set_tmux_option "@cpu_revamped_high_fg_color" "#[fg=red]"
  [[ "$(cpu_render_load_color 1.5 xx)" == "#[fg=red]" ]]
}

@test "render.sh - cpu_render_load_color honors custom ratios" {
  set_tmux_option "@cpu_revamped_load_medium_ratio" "0.25"
  set_tmux_option "@cpu_revamped_medium_fg_color" "#[fg=yellow]"
  [[ "$(cpu_render_load_color 3 8)" == "#[fg=yellow]" ]]
}

@test "render.sh - cpu_render_alert is empty when calm" {
  [[ -z "$(cpu_render_alert 10 40)" ]]
}

@test "render.sh - cpu_render_alert fires on high load" {
  [[ "$(cpu_render_alert 95 40)" == "!" ]]
}

@test "render.sh - cpu_render_alert fires on high temperature" {
  [[ "$(cpu_render_alert 10 90)" == "!" ]]
}

@test "render.sh - cpu_render_alert honors a custom glyph" {
  set_tmux_option "@cpu_revamped_alert_icon" "ALERT"
  [[ "$(cpu_render_alert 95 40)" == "ALERT" ]]
}

@test "render.sh - cpu_render_alert treats a non-numeric load as zero" {
  [[ -z "$(cpu_render_alert abc 40)" ]]
}

@test "render.sh - cpu_render_alert ignores a non-numeric temperature" {
  [[ -z "$(cpu_render_alert 10 xx)" ]]
}

@test "render.sh - cpu_render_alert honors custom thresholds" {
  set_tmux_option "@cpu_revamped_high_thresh" "50"
  [[ "$(cpu_render_alert 60 40)" == "!" ]]
}

@test "render.sh - cpu_render_top_process echoes the value" {
  [[ "$(cpu_render_top_process "node 42%")" == "node 42%" ]]
}

@test "render.sh - cpu_render_governor echoes the value" {
  [[ "$(cpu_render_governor "performance")" == "performance" ]]
}

@test "render.sh - cpu_render_load_color runs its decimal math under the C locale" {
  # Arrange
  export AWK_LOCALE_LOG="${TEST_TMPDIR}/awk_locale"
  awk() { printf '%s' "${LC_ALL:-}" > "${AWK_LOCALE_LOG}"; command awk "$@"; }
  export LC_ALL=pt_BR.UTF-8 2>/dev/null

  # Act
  cpu_render_load_color 0.9 1 >/dev/null

  # Assert
  [[ "$(cat "${AWK_LOCALE_LOG}")" == "C" ]]
}
