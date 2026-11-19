#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/server_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/server_helpers.bash"

bats_require_minimum_version 1.5.0

loaded_with_status() {
  tmux set-option -g status-right '#{cpu_percentage} end'
  load_plugin
  wait_for host_shows "30% end"
}

pane_is_plain() {
  local mode
  mode=$(tmux display-message -p -t test:0.0 '#{pane_in_mode}')
  [[ "${mode}" == "0" ]]
}

@test "keys - prefix M-c opens btop in a popup when it is installed" {
  # Arrange
  monitor btop
  monitor htop
  loaded_with_status

  # Act
  press C-b M-c

  # Assert
  wait_for host_shows "monitor: btop"
}

@test "keys - without btop the popup opens htop, and leaving it closes the popup and keeps the status line running" {
  # Arrange
  monitor htop
  loaded_with_status
  press C-b M-c
  wait_for host_shows "monitor: htop"

  # Act
  press Enter

  # Assert
  wait_for host_lacks "monitor: htop"
  wait_for host_shows "30% end"
  pane_is_plain
}

@test "keys - with neither the popup runs top until Ctrl-C, which leaves no error" {
  # Arrange
  loaded_with_status
  press C-b M-c
  wait_for host_shows "monitor: following"

  # Act
  press C-c

  # Assert
  wait_for host_lacks "monitor: following"
  pane_is_plain
  run tmux show-messages
  [[ "${output}" != *"returned"* ]]
}

@test "keys - a key the person names opens the popup, and the default one then does nothing" {
  # Arrange
  monitor btop
  setting popup_key F8
  loaded_with_status
  press C-b M-c
  host_lacks "monitor: btop"

  # Act
  press C-b F8

  # Assert
  wait_for host_shows "monitor: btop"
}

@test "keys - a popup command the person sets runs with its arguments" {
  # Arrange
  monitor btop
  stand_in glances 'printf "arguments: %s\n" "$*"; read -r monitor_wait'
  setting popup_command "glances -t 2"
  loaded_with_status

  # Act
  press C-b M-c

  # Assert
  wait_for host_shows "arguments: -t 2"
  host_lacks "monitor: btop"
}

@test "keys - a popup command that is not installed is named in a message, and no popup opens" {
  # Arrange
  setting popup_command "nothing-here --x"
  loaded_with_status

  # Act
  press C-b M-c

  # Assert
  wait_for said "nothing-here is not installed"
  pane_is_plain
}

@test "keys - the popup takes the size the options give" {
  # Arrange
  stand_in btop 'stty size; read -r monitor_wait'
  setting popup_width 50
  setting popup_height 10
  loaded_with_status

  # Act
  press C-b M-c

  # Assert
  wait_for host_shows "8 48"
}

@test "keys - in options mode the status line reads options a daemon fills" {
  # Arrange
  setting render options
  tmux set-option -g status-right '#{cpu_percentage} | #{cpu_top_process} end'

  # Act
  load_plugin

  # Assert
  run tmux show-option -gqv status-right
  [[ "${output}" == "#{E:@cpu_revamped_out_percentage} | #{E:@cpu_revamped_out_top_process} end" ]]
  wait_for host_shows "30% | My #S app 42% end"
  run tmux show-option -gqv @cpu_revamped_ticker_pid
  [[ "${output}" =~ ^[0-9]+$ ]]
}

@test "keys - in options mode the popup key still opens the monitor" {
  # Arrange
  monitor btop
  setting render options
  tmux set-option -g status-right '#{cpu_percentage} end'
  load_plugin
  wait_for host_shows "30% end"

  # Act
  press C-b M-c

  # Assert
  wait_for host_shows "monitor: btop"
}
