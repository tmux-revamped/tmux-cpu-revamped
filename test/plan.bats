#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/cpu_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/cpu_helpers.bash"

logged() {
  grep -qxF -- "$1" "${FAKE}/log"
}

other_owner() {
  quiet sleep 'kept=$(grep -v "^@cpu_revamped_ticker_pid	" "'"${FAKE}"'/vars" || :)
printf "%s\n@cpu_revamped_ticker_pid\tsomeone-else\n" "${kept}" | grep -v "^$" >"'"${FAKE}"'/vars.next"
mv -f "'"${FAKE}"'/vars.next" "'"${FAKE}"'/vars"'
}

settled() {
  local tries=0
  until "$@"; do
    tries=$((tries + 1))
    [[ "${tries}" -lt 200 ]] || return 1
    /bin/sleep 0.05
  done
}

@test "plan - a fresh install binds the detail popup to M-c" {
  # Arrange
  local tool
  tool=$(tool_path)

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N CPU details M-c run-shell ${tool} popup" ]]
}

@test "plan - a key set to off binds nothing, and a key the person names is bound whoever holds it" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  planned
  [[ -z "${output}" ]]
  printf 'bind-key    -T prefix F8     display-message mine\n' >"${FAKE}/keys"
  option popup_key F8

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N CPU details F8 run-shell ${tool} popup" ]]
}

@test "plan - a tmux older than 3.1 gets its key without a note" {
  # Arrange
  tmux_is 3.0

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key M-c run-shell "*" popup" ]]
}

@test "plan - the default key is left alone when something else holds it, and bound again when the binding is the plugin's own" {
  # Arrange
  printf 'bind-key    -T prefix M-c     display-message mine\n' >"${FAKE}/keys"
  planned 'cpu_revamped_plan; printf "[%s]\n" "${CPU_REVAMPED_SKIPPED}"; '
  [[ "${output}" == "[M-c]" ]]
  printf 'bind-key -r -T prefix M-c     run-shell "/old/bin/cpu-revamped popup"\n' >"${FAKE}/keys"

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N CPU details M-c run-shell "*" popup" ]]
}

@test "plan - each placeholder becomes a job that prints it, and the metrics in use are recorded" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  var status-right '#{cpu_fg_color}#{cpu_icon} #{cpu_percentage}#[default] #{cpu_temp} #{cpu_alert}'
  var status-left '#{cpu_graph} #S'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-left #(${tool} status graph) #S" ]]
  [[ "${lines[1]}" == "set-option -gq status-right #(${tool} status fg_color)#(${tool} status icon) #(${tool} status percentage)#[default] #(${tool} status temp) #(${tool} status alert)" ]]
  [[ "${lines[2]}" == "set-option -gq @cpu_revamped_published percentage icon fg_color temp graph alert" ]]
  [[ "${#lines[@]}" -eq 3 ]]
}

@test "plan - every placeholder has its job" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  var status-right '#{cpu_bg_color}#{cpu_temp_icon}#{cpu_temp_fg_color}#{cpu_temp_bg_color}#{cpu_freq}#{cpu_load}#{cpu_load5}#{cpu_load15}#{cpu_count}#{cpu_top_process}#{cpu_governor}#{cpu_load_color}'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-right #(${tool} status bg_color)#(${tool} status temp_icon)#(${tool} status temp_fg_color)#(${tool} status temp_bg_color)#(${tool} status freq)#(${tool} status load)#(${tool} status load5)#(${tool} status load15)#(${tool} status count)#(${tool} status top_process)#(${tool} status governor)#(${tool} status load_color)" ]]
  [[ "${lines[1]}" == "set-option -gq @cpu_revamped_published bg_color temp_icon temp_fg_color temp_bg_color freq load load5 load15 count top_process governor load_color" ]]
}

@test "plan - a status line that ends in a semicolon keeps it, escaped, so tmux does not read it as a separator" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  var status-right '#{cpu_percentage};'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-right #(${tool} status percentage)\\;" ]]
}

@test "plan - in options mode each placeholder becomes a read of the option the daemon fills" {
  # Arrange
  option popup_key off
  option render options
  var status-right '#{cpu_fg_color}#{cpu_percentage} | #{cpu_temp}'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-right #{E:@cpu_revamped_out_fg_color}#{E:@cpu_revamped_out_percentage} | #{E:@cpu_revamped_out_temp}" ]]
  [[ "${lines[1]}" == "set-option -gq @cpu_revamped_published percentage fg_color temp" ]]
}

@test "plan - a render mode the plugin does not know means jobs" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  option render both
  var status-right '#{cpu_percentage}'

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "set-option -gq status-right #(${tool} status percentage)" ]]
}

@test "plan - a status line already rewritten is left as it is, and its metrics stay recorded" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key off
  option render options
  option published "percentage temp"
  var status-right '#{E:@cpu_revamped_out_percentage} | #{E:@cpu_revamped_out_temp}'
  planned
  [[ -z "${output}" ]]
  option render jobs
  option published "temp temp_icon"
  var status-right "#(${tool} status temp_icon) #(${tool} status temp)"

  # Act
  planned

  # Assert
  [[ -z "${output}" ]]
}

@test "plan - a status line with no placeholder is not written, and an old list of metrics is emptied" {
  # Arrange
  option popup_key off
  option published "percentage"
  var status-right '%H:%M #{session_name}'

  # Act
  planned

  # Assert
  [[ "${output}" == 'set-option -gq @cpu_revamped_published ""' ]]
}

@test "plan - a setting given in the environment rides on the key and on every job" {
  # Arrange
  var status-right '#{cpu_percentage}'

  # Act
  planned 'export CPU_REVAMPED_INTERVAL=2; '

  # Assert
  [[ "${lines[0]}" == *"cpu-revamped' --interval '2' popup" ]]
  [[ "${lines[1]}" == *"cpu-revamped' --interval '2' status percentage)" ]]
}

@test "plan - settings given in the environment ride in the order of the settings table, and an empty one rides too" {
  # Arrange
  var status-right '#{cpu_percentage}'

  # Act
  planned 'export CPU_REVAMPED_HIGH_THRESH=90 CPU_REVAMPED_COUNT_LABEL= CPU_REVAMPED_INTERVAL=3 CPU_REVAMPED_POPUP_KEY=F8 CPU_REVAMPED_POPUP_WIDTH=90%; '

  # Assert
  [[ "${lines[0]}" == "bind-key -N CPU details F8 run-shell "*"cpu-revamped' --popup-width '90%' --interval '3' --high-thresh '90' --count-label '' popup" ]]
}

@test "plan - apply sends everything in one tmux call and clears a daemon's claim in jobs mode" {
  # Arrange
  var status-right '#{cpu_percentage}'

  # Act
  lib_run cpu 'cpu_revamped_apply'

  # Assert
  [[ "${status}" -eq 0 ]]
  run sends
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "${lines[0]}" == "bind-key -N CPU details M-c run-shell "*" popup ; set-option -gq status-right #("*" status percentage) ; set-option -gq @cpu_revamped_published percentage" ]]
  [[ "${lines[1]}" == "set-option -gqu @cpu_revamped_ticker_pid" ]]
}

@test "plan - when tmux refuses the batch each command is sent alone, and the bad one fails the run" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key F99
  var status-right '#{cpu_percentage}'
  printf '%s\n' "bind-key -N CPU details F99 run-shell ${tool} popup" >"${FAKE}/refused"

  # Act
  lib_run cpu 'cpu_revamped_apply'

  # Assert
  [[ "${status}" -eq 1 ]]
  run sent '^set-option -gq status-right #(.* status percentage)$'
  [[ "${output}" == "1" ]]
  holds published percentage
}

@test "plan - in options mode apply starts the daemon, which claims the ticker and publishes until another takes over" {
  # Arrange
  linux_host
  option popup_key off
  option render options
  option interval 1
  var status-right '#{cpu_percentage}'
  other_owner

  # Act
  lib_run cpu 'cpu_revamped_apply'

  # Assert
  [[ "${status}" -eq 0 ]]
  settled holds out_percentage "80%%"
  settled holds ticker_pid someone-else
  run sent '^set-option -gq @cpu_revamped_ticker_pid [0-9][0-9]*$'
  [[ "${output}" == "1" ]]
}

@test "plan - the daemon ends when another process owns the ticker" {
  # Arrange
  linux_host
  option published "count"
  other_owner

  # Act
  tool daemon

  # Assert
  [[ "${status}" -eq 0 ]]
  holds out_count "4"
  holds ticker_pid someone-else
}

@test "plan - the popup opens btop when it is installed, at the size the options give" {
  # Arrange
  quiet btop ':'
  quiet htop ':'
  option popup_width 90%
  option popup_height 50%

  # Act
  lib_run cpu 'cpu_revamped_popup'

  # Assert
  [[ "${status}" -eq 0 ]]
  logged "display-popup -E -w 90% -h 50% btop"
}

@test "plan - without btop the popup opens htop, and without both it opens top" {
  # Arrange
  quiet htop ':'
  lib_run cpu 'cpu_revamped_popup'
  logged "display-popup -E -w 80% -h 80% htop"
  unstub htop
  quiet top ':'

  # Act
  lib_run cpu 'cpu_revamped_popup'

  # Assert
  logged "display-popup -E -w 80% -h 80% top"
}

@test "plan - a popup command the person sets runs with its arguments, in place of btop" {
  # Arrange
  quiet btop ':'
  quiet glances ':'
  option popup_command "glances -t 2"

  # Act
  lib_run cpu 'cpu_revamped_popup'

  # Assert
  logged "display-popup -E -w 80% -h 80% glances -t 2"
}

@test "plan - a popup command that is not installed is named in a message, with each hash doubled, and opens no popup" {
  # Arrange
  option popup_command "no#such --flag"

  # Act
  lib_run cpu 'cpu_revamped_popup'

  # Assert
  [[ "${status}" -eq 0 ]]
  logged "display-message cpu-revamped: no##such is not installed"
  run sent '^display-popup'
  [[ "${output}" == "0" ]]
}

@test "plan - without top too the popup names it in a message" {
  # Arrange
  quiet unrelated ':'

  # Act
  lib_run cpu 'cpu_revamped_popup'

  # Assert
  logged "display-message cpu-revamped: top is not installed"
}

@test "plan - a tmux older than 3.2 says so and opens nothing" {
  # Arrange
  tmux_is 3.1
  quiet htop ':'

  # Act
  lib_run cpu 'cpu_revamped_popup'

  # Assert
  [[ "${status}" -eq 0 ]]
  logged "display-message cpu-revamped: tmux 3.2+ is required for the CPU detail popup"
  run sent '^display-popup'
  [[ "${output}" == "0" ]]
}

@test "plan - a popup or a message tmux refuses to open leaves the key quiet" {
  # Arrange
  quiet htop ':'
  printf '%s\n' "display-popup -E -w 80% -h 80% htop" "display-message cpu-revamped: tmux 3.2+ is required for the CPU detail popup" "display-message cpu-revamped: top is not installed" >"${FAKE}/refused"
  lib_run cpu 'cpu_revamped_popup'
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  tmux_is 3.1
  lib_run cpu 'cpu_revamped_popup'
  [[ "${status}" -eq 0 ]]
  unstub htop
  tmux_is 3.6

  # Act
  lib_run cpu 'cpu_revamped_popup'

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
}

@test "plan - a path is quoted for a job with each hash and each percent sign doubled, and for a key with no hash left" {
  # Arrange
  local script='cpu_revamped_job_quote "/a b/it'"'"'s#1 50%"; cpu_revamped_literal "/a b/it'"'"'s#1 50%"'

  # Act
  lib_run cpu "${script}"

  # Assert
  [[ "${lines[0]}" == "'/a b/it'\\''s##1 50%%'" ]]
  [[ "${lines[1]}" == "'/a b/it'\\''s'\"\$(printf '%b' '\\0043')\"'1 50%'" ]]
}

@test "plan - a format given in the environment rides on the job with its percent signs doubled, since tmux reads the status line as a time format" {
  # Arrange
  option popup_key off
  var status-right '#{cpu_percentage}'

  # Act
  planned 'export CPU_REVAMPED_PERCENTAGE_FORMAT="%s%% used"; '

  # Assert
  [[ "${lines[0]}" == *"cpu-revamped' --percentage-format '%%s%%%% used' status percentage)" ]]
}
