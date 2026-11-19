#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/server_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/server_helpers.bash"

bats_require_minimum_version 1.5.0

everything() {
  local options
  options=$(tmux show-options -g)
  grep -vE '@cpu_revamped_(percent|temp|freq|load|load5|load15|count|governor|top_process|history|[a-z_]+_ts|percent_lock) ' <<<"${options}"
  tmux list-keys
}

@test "entrypoint - git tracks the entry point and the tool as executable" {
  # Arrange
  local modes

  # Act
  modes=$(git -C "${ROOT}" ls-files --stage -- cpu-revamped.tmux bin/cpu-revamped)

  # Assert
  run awk '$1 != "100755" { bad++ } END { print NR ":" bad + 0 }' <<<"${modes}"
  [[ "${output}" == "2:0" ]]
}

@test "entrypoint - loading binds the popup on M-c and turns the placeholder into its job, which shows the load" {
  # Arrange
  local keys
  tmux set-option -g status-right '#{cpu_percentage} #{cpu_load} #{cpu_count} end'

  # Act
  load_plugin

  # Assert
  keys=$(prefix_keys)
  run grep -c -x 'M-c' <<<"${keys}"
  [[ "${output}" == "1" ]]
  run tmux show-option -gqv status-right
  [[ "${output}" == "#('${ROOT}/bin/cpu-revamped' status percentage) #('${ROOT}/bin/cpu-revamped' status load) #('${ROOT}/bin/cpu-revamped' status count) end" ]]
  wait_for host_shows "30% 0.50 4 end"
}

@test "entrypoint - loading twice changes nothing" {
  # Arrange
  local before after
  tmux set-option -g status-right '#{cpu_percentage} end'
  load_plugin
  before=$(everything)

  # Act
  load_plugin

  # Assert
  after=$(everything)
  [[ "${before}" == "${after}" ]]
}

@test "entrypoint - a process name that holds a tmux format is shown as text" {
  # Arrange
  tmux set-option -g status-right '#{cpu_top_process} end'

  # Act
  load_plugin

  # Assert
  wait_for host_shows "My #S app 42% end"
}

@test "entrypoint - the clock, the load average, the graph and the alert reach the status line" {
  # Arrange
  tmux set-option -g status-right '#{cpu_freq} #{cpu_load5} #{cpu_load15} #{cpu_graph} end'

  # Act
  load_plugin

  # Assert
  wait_for host_shows "3400MHz 1.25 2.00"
  wait_for host_shows $'\xe2\x96\x83 end'
}

@test "entrypoint - in the nerd set a label set to nothing on a real server means the default, so every metric keeps its glyph" {
  # Arrange
  tmux set-option -g @cpu_revamped_icons nerd
  tmux set-option -g @cpu_revamped_count_label ''
  tmux set-option -g status-right '#{cpu_percentage} #{cpu_count} end'

  # Act
  load_plugin

  # Assert
  wait_for host_shows $'\xf3\xb0\x8a\x9a 30% \xf3\xb0\x98\x9a 4 end'
}

@test "entrypoint - a format given in the environment reaches the status job with its percent signs whole" {
  # Arrange
  tmux set-environment -g CPU_REVAMPED_PERCENTAGE_FORMAT 'cpu %s%%'
  tmux set-option -g status-right '#{cpu_percentage} end'

  # Act
  load_plugin

  # Assert
  wait_for host_shows "cpu 30% end"
}

@test "entrypoint - a checkout whose path holds a space, a quote, a hash and a percent sign loads, shows the load and takes its key" {
  # Arrange
  local copy="${BATS_TEST_TMPDIR}/it's #1 50% plug in"
  mkdir -p "${copy}"
  cp -R "${ROOT}/bin" "${ROOT}/lib" "${ROOT}/cpu-revamped.tmux" "${copy}/"
  monitor btop
  tmux set-option -g status-right '#{cpu_percentage} end'
  load_plugin "${copy}"
  wait_for host_shows "30% end"

  # Act
  press C-b M-c

  # Assert
  wait_for host_shows "monitor: btop"
}

@test "entrypoint - a default key someone else holds is left alone, and one the person names is bound" {
  # Arrange
  local table
  tmux bind-key -T prefix M-c display-message taken
  load_plugin
  table=$(tmux list-keys -T prefix)
  run grep -c 'M-c  *display-message taken' <<<"${table}"
  [[ "${output}" == "1" ]]
  run grep -c 'cpu-revamped' <<<"${table}"
  [[ "${output}" == "0" ]]
  tmux bind-key -T prefix x display-message taken-too
  setting popup_key x

  # Act
  load_plugin

  # Assert
  table=$(tmux list-keys -T prefix)
  run grep -c 'cpu-revamped. popup' <<<"${table}"
  [[ "${output}" == "1" ]]
}

@test "entrypoint - a key set to off binds nothing" {
  # Arrange
  local table
  setting popup_key off

  # Act
  load_plugin

  # Assert
  table=$(tmux list-keys -T prefix)
  run grep -c 'cpu-revamped' <<<"${table}"
  [[ "${output}" == "0" ]]
}
