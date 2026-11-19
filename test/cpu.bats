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

status_of() {
  lib_run cpu 'cpu_revamped_status '"$1"
}

stored() {
  sampled 42
  option temp 50
  option freq 2400
  option load 1.52
  option load5 1.60
  option load15 1.70
  option count 8
  option governor powersave
  option top_process "42 node"
  option history "20 40 60"
}

@test "cpu - the figures print the stored sample in their formats" {
  # Arrange
  stored

  # Act
  each "percentage temp freq load load5 load15 count top_process governor"

  # Assert
  [[ "${lines[*]}" == "42% 50°C 2400MHz 1.52 1.60 1.70 8 node 42% powersave" ]]
}

@test "cpu - a format the person sets shapes its value" {
  # Arrange
  stored
  option percentage_format 'cpu %s'
  option temp_format 'temp %s'
  option freq_format '%s MHz'
  option load_format 'load %s'

  # Act
  each "percentage temp freq load load5 load15"

  # Assert
  [[ "${lines[0]}" == "cpu 42" ]]
  [[ "${lines[1]}" == "temp 50" ]]
  [[ "${lines[2]}" == "2400 MHz" ]]
  [[ "${lines[3]}" == "load 1.52" ]]
  [[ "${lines[4]}" == "load 1.60" ]]
  [[ "${lines[5]}" == "load 1.70" ]]
}

@test "cpu - with no sample stored the values print nothing, and the tier placeholders show the low tier" {
  # Arrange
  option low_fg_color '#[fg=green]'
  option low_bg_color '#[bg=black]'
  option icons nerd

  # Act
  each "percentage temp temp_icon temp_fg_color temp_bg_color freq load load5 load15 count graph top_process governor load_color alert"

  # Assert
  [[ -z "${output}" ]]
  each "icon fg_color bg_color"
  [[ "${lines[0]}" == $'\xe2\x96\xb0\xe2\x96\xb1\xe2\x96\xb1' ]]
  [[ "${lines[1]}" == "#[fg=green]" ]]
  [[ "${lines[2]}" == "#[bg=black]" ]]
}

@test "cpu - the icon is one, two or three bars as the load crosses 30 and 80 percent" {
  # Arrange
  local script='cpu_revamped_load; for percent in 29 30 79 80; do CPU_REVAMPED_S_percent="${percent}"; cpu_revamped_show icon; done'

  # Act
  lib_run cpu "${script}"

  # Assert
  [[ "${lines[0]}" == $'\xe2\x96\xb0\xe2\x96\xb1\xe2\x96\xb1' ]]
  [[ "${lines[1]}" == $'\xe2\x96\xb0\xe2\x96\xb0\xe2\x96\xb1' ]]
  [[ "${lines[2]}" == $'\xe2\x96\xb0\xe2\x96\xb0\xe2\x96\xb1' ]]
  [[ "${lines[3]}" == $'\xe2\x96\xb0\xe2\x96\xb0\xe2\x96\xb0' ]]
}

@test "cpu - the icons and the colours of each tier are the person's to set" {
  # Arrange
  option low_icon L
  option medium_icon M
  option high_icon H
  option low_fg_color '#[fg=green]'
  option medium_fg_color '#[fg=yellow]'
  option high_fg_color '#[fg=red]'
  option low_bg_color '#[bg=black]'
  option medium_bg_color '#[bg=blue]'
  option high_bg_color '#[bg=white]'
  local script='cpu_revamped_load; for percent in 10 50 90; do CPU_REVAMPED_S_percent="${percent}"; cpu_revamped_show icon; cpu_revamped_show fg_color; cpu_revamped_show bg_color; done'

  # Act
  lib_run cpu "${script}"

  # Assert
  [[ "${lines[*]}" == "L #[fg=green] #[bg=black] M #[fg=yellow] #[bg=blue] H #[fg=red] #[bg=white]" ]]
}

@test "cpu - the tiers start where their options say, and junk there means 30 and 80 percent" {
  # Arrange
  option low_fg_color low
  option medium_fg_color medium
  option high_fg_color high
  option medium_thresh 10
  option high_thresh 20
  local script='cpu_revamped_load; for percent in 9 10 20; do CPU_REVAMPED_S_percent="${percent}"; cpu_revamped_show fg_color; done; CPU_REVAMPED_S_medium_thresh=x; CPU_REVAMPED_S_high_thresh=y; for percent in 20 30 80; do CPU_REVAMPED_S_percent="${percent}"; cpu_revamped_show fg_color; done'

  # Act
  lib_run cpu "${script}"

  # Assert
  [[ "${lines[*]}" == "low medium high low medium high" ]]
}

@test "cpu - the temperature tiers have their own icons and styles, from 65 and 80 degrees" {
  # Arrange
  option temp_low_icon L
  option temp_medium_icon M
  option temp_high_icon H
  option temp_low_fg_color '#[fg=green]'
  option temp_medium_fg_color '#[fg=yellow]'
  option temp_high_fg_color '#[fg=red]'
  option temp_low_bg_color '#[bg=black]'
  option temp_medium_bg_color '#[bg=blue]'
  option temp_high_bg_color '#[bg=white]'
  local script='cpu_revamped_load; for temp in 64 65 79 80; do CPU_REVAMPED_S_temp="${temp}"; cpu_revamped_show temp_icon; cpu_revamped_show temp_fg_color; cpu_revamped_show temp_bg_color; done'

  # Act
  lib_run cpu "${script}"

  # Assert
  [[ "${lines[*]}" == "L #[fg=green] #[bg=black] M #[fg=yellow] #[bg=blue] M #[fg=yellow] #[bg=blue] H #[fg=red] #[bg=white]" ]]
}

@test "cpu - the temperature tiers move with their thresholds, and junk there means 65 and 80 degrees" {
  # Arrange
  option temp_low_icon low
  option temp_medium_icon medium
  option temp_high_icon high
  option temp_medium_thresh 40
  option temp_high_thresh 50
  local script='cpu_revamped_load; for temp in 39 40 50; do CPU_REVAMPED_S_temp="${temp}"; cpu_revamped_show temp_icon; done; CPU_REVAMPED_S_temp_medium_thresh=x; CPU_REVAMPED_S_temp_high_thresh=y; for temp in 64 65 80; do CPU_REVAMPED_S_temp="${temp}"; cpu_revamped_show temp_icon; done'

  # Act
  lib_run cpu "${script}"

  # Assert
  [[ "${lines[*]}" == "low medium high low medium high" ]]
}

@test "cpu - the temperature is shown in Celsius, or in Fahrenheit rounded to the nearest degree" {
  # Arrange
  option temp 50
  shown temp
  [[ "${output}" == "50°C" ]]
  option temp_unit F
  shown temp
  [[ "${output}" == "122°F" ]]
  option temp 37
  shown temp
  [[ "${output}" == "99°F" ]]
  option temp_format '[%s]'

  # Act
  shown temp

  # Assert
  [[ "${output}" == "[99]" ]]
}

@test "cpu - a unit that is neither C nor F keeps Celsius under its own name" {
  # Arrange
  option temp 50
  option temp_unit K

  # Act
  shown temp

  # Assert
  [[ "${output}" == "50°K" ]]
}

@test "cpu - a clock of zero or nothing prints nothing" {
  # Arrange
  option freq 0
  shown freq
  [[ -z "${output}" ]]
  option freq ""

  # Act
  shown freq

  # Assert
  [[ -z "${output}" ]]
}

@test "cpu - the load colour is the foreground style of the tier of the load average per core" {
  # Arrange
  option low_fg_color low
  option medium_fg_color medium
  option high_fg_color high
  option count 8
  local script='cpu_revamped_load; for load in 1 5.7 6 16 8; do CPU_REVAMPED_S_load="${load}"; cpu_revamped_show load_color; done'

  # Act
  lib_run cpu "${script}"

  # Assert
  [[ "${lines[*]}" == "low medium medium high high" ]]
}

@test "cpu - the load colour counts one core when the count is no number or zero, and its ratios are the person's to set" {
  # Arrange
  option low_fg_color low
  option medium_fg_color medium
  option high_fg_color high
  local script='cpu_revamped_load; CPU_REVAMPED_S_load=1.5; for count in "" x 0; do CPU_REVAMPED_S_count="${count}"; cpu_revamped_show load_color; done; CPU_REVAMPED_S_count=8; CPU_REVAMPED_S_load_medium_ratio=0.25; CPU_REVAMPED_S_load_high_ratio=0.5; for load in 1 3 5; do CPU_REVAMPED_S_load="${load}"; cpu_revamped_show load_color; done'

  # Act
  lib_run cpu "${script}"

  # Assert
  [[ "${lines[*]}" == "high high high low medium high" ]]
}

@test "cpu - the alert shows while the load or the temperature is high" {
  # Arrange
  local script='cpu_revamped_load; for pair in "10 40" "80 40" "10 80" "79 79"; do CPU_REVAMPED_S_percent="${pair% *}"; CPU_REVAMPED_S_temp="${pair#* }"; printf "[%s]" "${pair}"; cpu_revamped_show alert; done'

  # Act
  lib_run cpu "${script}"

  # Assert
  [[ "${lines[*]}" == "[10 40][80 40]! [10 80]! [79 79]" ]]
}

@test "cpu - the alert's text, its thresholds and a load or temperature that is no number are the person's to set" {
  # Arrange
  option alert_icon ALERT
  option high_thresh 50
  option temp_high_thresh 60
  local script='cpu_revamped_load; for pair in "49 59" "50 59" "49 60" "x 59" "49 y"; do CPU_REVAMPED_S_percent="${pair% *}"; CPU_REVAMPED_S_temp="${pair#* }"; printf "[%s]" "${pair}"; cpu_revamped_show alert; done'

  # Act
  lib_run cpu "${script}"

  # Assert
  [[ "${lines[*]}" == "[49 59][50 59]ALERT [49 60]ALERT [x 59][49 y]" ]]
}

@test "cpu - the busiest process prints its name, with each hash doubled, then its share" {
  # Arrange
  option top_process "42 /My #1 App"

  # Act
  shown top_process

  # Assert
  [[ "${output}" == "/My ##1 App 42%" ]]
}

@test "cpu - the graph draws one bar per sample, eight heights, and takes what is not a number for zero" {
  # Arrange
  option history "0 13 38 50 88 100 x 55.9 150"

  # Act
  shown graph

  # Assert
  [[ "${output}" == $'\xe2\x96\x81\xe2\x96\x82\xe2\x96\x84\xe2\x96\x84\xe2\x96\x87\xe2\x96\x88\xe2\x96\x81\xe2\x96\x85\xe2\x96\x88' ]]
}

@test "cpu - a metric's label is printed before its value, and never alone" {
  # Arrange
  sampled 42
  option percentage_label 'C:'
  option temp_label 'T:'
  shown temp
  [[ -z "${output}" ]]

  # Act
  shown percentage

  # Assert
  [[ "${output}" == "C: 42%" ]]
}

@test "cpu - the nerd set puts its glyph before every labelled metric" {
  # Arrange
  stored
  option icons nerd

  # Act
  each "percentage temp freq load load5 load15 count graph top_process governor"

  # Assert
  [[ "${lines[0]}" == $'\xf3\xb0\x8a\x9a 42%' ]]
  [[ "${lines[1]}" == $'\xf3\xb0\x94\x8f 50\xc2\xb0C' ]]
  [[ "${lines[2]}" == $'\xf3\xb0\x93\x85 2400MHz' ]]
  [[ "${lines[3]}" == $'\xf3\xb0\x97\x91 1.52' ]]
  [[ "${lines[4]}" == $'\xf3\xb0\x97\x91 1.60' ]]
  [[ "${lines[5]}" == $'\xf3\xb0\x97\x91 1.70' ]]
  [[ "${lines[6]}" == $'\xf3\xb0\x98\x9a 8' ]]
  [[ "${lines[7]}" == $'\xf3\xb0\x9e\xb1 \xe2\x96\x82\xe2\x96\x84\xe2\x96\x85' ]]
  [[ "${lines[8]}" == $'\xf3\xb0\xa3\x86 node 42%' ]]
  [[ "${lines[9]}" == $'\xf3\xb0\x98\xae powersave' ]]
}

@test "cpu - in the nerd set the icons, the colours and the alert take no glyph" {
  # Arrange
  stored
  option percent 10
  option icons nerd
  option low_fg_color '#[fg=green]'
  option temp_low_icon T
  option load_high_ratio 0.1
  option high_fg_color '#[fg=red]'

  # Act
  each "icon fg_color temp_icon load_color"

  # Assert
  [[ "${lines[0]}" == $'\xe2\x96\xb0\xe2\x96\xb1\xe2\x96\xb1' ]]
  [[ "${lines[1]}" == "#[fg=green]" ]]
  [[ "${lines[2]}" == "T" ]]
  [[ "${lines[3]}" == "#[fg=red]" ]]
}

@test "cpu - in the nerd set a metric's own label wins, and a label set to nothing means the default, so its glyph stays" {
  # Arrange
  stored
  option icons nerd
  option percentage_label 'C:'
  option temp_label ''

  # Act
  each "percentage temp"

  # Assert
  [[ "${lines[0]}" == "C: 42%" ]]
  [[ "${lines[1]}" == $'\xf3\xb0\x94\x8f 50\xc2\xb0C' ]]
}

@test "cpu - the plain set labels nothing" {
  # Arrange
  stored

  # Act
  each "percentage temp freq"

  # Assert
  [[ "${lines[*]}" == "42% 50°C 2400MHz" ]]
}

@test "cpu - fixed width pads each figure to its natural width and leaves the rest alone" {
  # Arrange
  sampled 9
  option temp 5
  option freq 800
  option load 1.5
  option count 8
  option top_process "1 sh"
  option governor powersave
  option fixed_width on

  # Act
  each "percentage temp freq load count top_process governor"

  # Assert
  [[ "${lines[0]}" == "  9%" ]]
  [[ "${lines[1]}" == "  5°C" ]]
  [[ "${lines[2]}" == " 800MHz" ]]
  [[ "${lines[3]}" == "  1.5" ]]
  [[ "${lines[4]}" == "  8" ]]
  [[ "${lines[5]}" == "sh 1%" ]]
  [[ "${lines[6]}" == "powersave" ]]
}

@test "cpu - a metric's own width wins over the fixed width, counts characters and never cuts" {
  # Arrange
  sampled 9
  option fixed_width on
  option percentage_width 6
  option governor "$(printf 'caf\303\251')"
  option governor_width 6
  option load 1.52
  option load_width 2
  option freq 800
  option freq_width wide
  shown percentage
  [[ "${output}" == "    9%" ]]
  shown governor
  [[ "${output}" == "  $(printf 'caf\303\251')" ]]
  shown load
  [[ "${output}" == "1.52" ]]

  # Act
  shown freq

  # Assert
  [[ "${output}" == " 800MHz" ]]
}

@test "cpu - a label goes before the padded value" {
  # Arrange
  sampled 9
  option percentage_label 'C:'
  option percentage_width 5

  # Act
  shown percentage

  # Assert
  [[ "${output}" == "C:    9%" ]]
}

@test "cpu - a fresh sample is printed with one tmux read and no write" {
  # Arrange
  sampled 42 999999

  # Act
  status_of percentage

  # Assert
  [[ "${output}" == "42%" ]]
  run sends
  [[ -z "${output}" ]]
  run sent '^display-message -p'
  [[ "${output}" == "1" ]]
}

@test "cpu - a sample older than the interval is printed at once while the CPU is read behind it" {
  # Arrange
  linux_host
  sampled 42 999990

  # Act
  status_of percentage

  # Assert
  [[ "${output}" == "42%" ]]
  eventually holds percent 80
  eventually holds percent_lock 0
  holds percent_ts 1000000
}

@test "cpu - with nothing stored yet the placeholder is empty and the first sample starts" {
  # Arrange
  linux_host

  # Act
  status_of percentage

  # Assert
  [[ -z "${output}" ]]
  eventually holds percent 80
}

@test "cpu - a sample under way is left to finish, and one whose lock is old or has no time is started again" {
  # Arrange
  linux_host
  sampled 42 999900
  option percent_lock 1
  option percent_lock_ts 999997
  status_of percentage
  run sends
  [[ -z "${output}" ]]
  option percent_lock_ts 999970
  status_of percentage
  eventually holds percent 80
  eventually holds percent_lock 0
  sampled 42 999900
  option percent_lock 1
  option percent_lock_ts ""

  # Act
  status_of percentage

  # Assert
  eventually holds percent 80
}

@test "cpu - the interval comes from its setting, and junk there means five seconds" {
  # Arrange
  linux_host
  sampled 42 999990
  option interval 60
  status_of percentage
  run sends
  [[ -z "${output}" ]]
  option interval soon

  # Act
  status_of percentage

  # Assert
  eventually holds percent 80
}

@test "cpu - while no client is attached and the throttle is on nothing is sampled" {
  # Arrange
  linux_host
  sampled 42 999900
  option throttle_when_detached 1

  # Act
  status_of percentage

  # Assert
  [[ "${output}" == "42%" ]]
  run sends
  [[ -z "${output}" ]]
}

@test "cpu - with a client attached the throttle lets the sample run" {
  # Arrange
  linux_host
  sampled 42 999900
  option throttle_when_detached 1
  printf 'client-a\n' >"${FAKE}/clients"

  # Act
  status_of percentage

  # Assert
  eventually holds percent 80
}

@test "cpu - a placeholder asked for by hand has its figure read even when the status line does not use it" {
  # Arrange
  linux_host
  processes
  sampled 42 999990
  option published percentage

  # Act
  status_of top_process

  # Assert
  [[ -z "${output}" ]]
  eventually holds top_process "42 My App"
}

@test "cpu - a tick samples the CPU and publishes every metric the status line uses in one tmux call" {
  # Arrange
  linux_host
  processes "  0.5 init
 44.0 My #1"
  option published "percentage top_process"
  printf 'client-a\n' >"${FAKE}/clients"

  # Act
  lib_run cpu 'cpu_revamped_tick'

  # Assert
  [[ "${status}" -eq 0 ]]
  holds out_percentage "80%%"
  holds out_top_process "My ##1 44%%"
  run sent 'set-option -gq @cpu_revamped_out_percentage 80%% ; set-option -gq @cpu_revamped_out_top_process My ##1 44%% ; refresh-client -S -t client-a'
  [[ "${output}" == "1" ]]
}

@test "cpu - a tick skips a doubled space in the list of metrics" {
  # Arrange
  linux_host
  option published "percentage  count"

  # Act
  lib_run cpu 'cpu_revamped_tick'

  # Assert
  holds out_percentage "80%%"
  holds out_count "4"
  run sent '@cpu_revamped_out_ '
  [[ "${output}" == "0" ]]
}

@test "cpu - a tick publishes nothing when the status line uses no metric, or when tmux takes no write" {
  # Arrange
  linux_host
  lib_run cpu 'cpu_revamped_tick'
  run sent '@cpu_revamped_out_'
  [[ "${output}" == "0" ]]
  option published "percentage"
  : >"${FAKE}/refused"

  # Act
  lib_run cpu 'cpu_revamped_tick'

  # Assert
  [[ "${status}" -eq 0 ]]
  run sent '@cpu_revamped_out_'
  [[ "${output}" == "0" ]]
}

@test "cpu - a tick while no client is attached and the throttle is on publishes the stored sample without reading the CPU" {
  # Arrange
  linux_host
  sampled 42
  option published percentage
  option throttle_when_detached 1

  # Act
  lib_run cpu 'cpu_revamped_tick'

  # Assert
  holds out_percentage "42%%"
  run asked
  [[ -z "${output}" ]]
}

@test "cpu - a tmux version is read out of its banner and compared part by part" {
  # Arrange
  local script='for banner in "tmux 3.6a" "tmux next-3.7" "nonsense"; do printf "[%s]" "$(cpu_revamped_parse_version "${banner}")"; done; for pair in "3.6 3.2" "3.2 3.2" "3.1 3.2" "4.0 3.2" "2.9 3.2" " 3.2" "x 3.2"; do if cpu_revamped_version_ge ${pair}; then printf y; else printf n; fi; done'

  # Act
  lib_run cpu "${script}"

  # Assert
  [[ "${output}" == "[3.6][3.7][]yynynnn" ]]
}
