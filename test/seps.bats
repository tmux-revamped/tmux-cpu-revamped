#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/cpu_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/cpu_helpers.bash"

shown() {
  lib_run cpu 'cpu_revamped_load; cpu_revamped_show '"$1"
}

each() {
  lib_run cpu 'cpu_revamped_load; for metric in '"$1"'; do cpu_revamped_show "${metric}"; done'
}

stored_figures() {
  sampled 42
  option temp 50
}

@test "seps - each arrow takes the colour of the load tier's background as its foreground, over the separator background" {
  # Arrange
  sampled 10
  option low_bg_color '#[bg=#313244]'
  option medium_bg_color '#[bg=#45475a]'
  option high_bg_color '#[bg=#585b70]'

  # Act
  each "sep_left sep_right"

  # Assert
  [[ "${lines[0]}" == $'#[fg=#313244,bg=default]\xee\x82\xb2#[default]' ]]
  [[ "${lines[1]}" == $'#[fg=#313244,bg=default]\xee\x82\xb0#[default]' ]]
}

@test "seps - the arrow follows the tier as the load climbs" {
  # Arrange
  option low_bg_color '#[bg=green]'
  option medium_bg_color '#[bg=yellow]'
  option high_bg_color '#[bg=red]'
  local script='cpu_revamped_load; for percent in 10 50 90; do CPU_REVAMPED_S_percent="${percent}"; cpu_revamped_show sep_right; done'

  # Act
  lib_run cpu "${script}"

  # Assert
  [[ "${lines[0]}" == $'#[fg=green,bg=default]\xee\x82\xb0#[default]' ]]
  [[ "${lines[1]}" == $'#[fg=yellow,bg=default]\xee\x82\xb0#[default]' ]]
  [[ "${lines[2]}" == $'#[fg=red,bg=default]\xee\x82\xb0#[default]' ]]
}

@test "seps - the glyphs and the background behind them are the person's to set" {
  # Arrange
  sampled 10
  option low_bg_color '#[bg=blue,bold]'
  option sep_left '<'
  option sep_right '>'
  option sep_bg black

  # Act
  each "sep_left sep_right"

  # Assert
  [[ "${lines[0]}" == "#[fg=blue,bg=black]<#[default]" ]]
  [[ "${lines[1]}" == "#[fg=blue,bg=black]>#[default]" ]]
}

@test "seps - an empty tier background, or one with no bg part, prints the glyph unstyled" {
  # Arrange
  sampled 10
  option sep_right '>'
  shown sep_right
  [[ "${output}" == ">" ]]
  option low_bg_color '#[fg=red]'

  # Act
  shown sep_right

  # Assert
  [[ "${output}" == ">" ]]
}

@test "seps - with no sample stored the arrow takes the low tier" {
  # Arrange
  option low_bg_color '#[bg=#313244]'

  # Act
  shown sep_left

  # Assert
  [[ "${output}" == $'#[fg=#313244,bg=default]\xee\x82\xb2#[default]' ]]
}

@test "seps - a glyph set to off prints nothing" {
  # Arrange
  sampled 10
  option low_bg_color '#[bg=blue]'
  option sep_left off
  option sep_right off

  # Act
  each "sep_left sep_right"

  # Assert
  [[ -z "${output}" ]]
}

@test "off - the load icon of each tier set to off prints nothing" {
  # Arrange
  option low_icon off
  option medium_icon off
  option high_icon off
  local script='cpu_revamped_load; for percent in 10 50 90; do CPU_REVAMPED_S_percent="${percent}"; cpu_revamped_show icon; done'

  # Act
  lib_run cpu "${script}"

  # Assert
  [[ -z "${output}" ]]
}

@test "off - the temperature icon of each tier set to off prints nothing, and a colour is never taken for off" {
  # Arrange
  option temp_low_icon off
  option temp_medium_icon off
  option temp_high_icon off
  option temp_low_fg_color off
  local script='cpu_revamped_load; for temp in 40 70 90; do CPU_REVAMPED_S_temp="${temp}"; cpu_revamped_show temp_icon; done; CPU_REVAMPED_S_temp=40; cpu_revamped_show temp_fg_color'

  # Act
  lib_run cpu "${script}"

  # Assert
  [[ "${output}" == "off" ]]
}

@test "off - the alert icon set to off prints nothing" {
  # Arrange
  sampled 90
  option alert_icon off

  # Act
  shown alert

  # Assert
  [[ -z "${output}" ]]
}

@test "off - a label set to off prints no label, not even the Nerd Font glyph, and keeps the padding" {
  # Arrange
  stored_figures
  option icons nerd
  option percentage_label off
  option temp_label off
  option percentage_width 5

  # Act
  each "percentage temp"

  # Assert
  [[ "${lines[0]}" == "  42%" ]]
  [[ "${lines[1]}" == "50°C" ]]
}
