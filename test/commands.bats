#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/cpu_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/cpu_helpers.bash"

everything() {
  linux_host
  processes
  option history "60 70"
}

@test "commands - status prints one placeholder from the stored sample" {
  # Arrange
  sampled 42 1000000

  # Act
  tool status percentage

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "42%" ]]
}

@test "commands - status without a name is a usage error, and an unknown name a bad value" {
  # Arrange
  tool status
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "cpu-revamped: no placeholder given. run 'cpu-revamped help' for usage." ]]

  # Act
  tool status free

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "cpu-revamped: status must be percentage, icon, fg_color, bg_color, temp, temp_icon, temp_fg_color, temp_bg_color, freq, load, load5, load15, count, graph, top_process, governor, load_color or alert, got: free" ]]
}

@test "commands - refresh samples the CPU now and says how much is busy" {
  # Arrange
  linux_host

  # Act
  tool refresh

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "Refreshed. 80% of the CPU is busy." ]]
  holds percent 80
}

@test "commands - refresh reads the details only when the status line shows them" {
  # Arrange
  everything
  tool refresh
  run asked
  [[ "${output}" == $'cat /proc/stat\ncat /proc/stat' ]]
  : >"${FAKE}/asked"
  option published "governor top_process"

  # Act
  tool refresh

  # Assert
  run asked
  [[ "${output}" == *$'cat /proc/stat\ncat /proc/stat'*"cat "*"/scaling_governor"* ]]
  [[ "${output}" == *"ps axo pcpu=,comm="* ]]
}

@test "commands - refresh fails when no tmux server takes the sample" {
  # Arrange
  linux_host
  printf 'refused\n' >"${FAKE}/refused"

  # Act
  tool refresh

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "cpu-revamped: no tmux server is running, so the sample has nowhere to go" ]]
}

@test "commands - card reads everything now and prints one row per figure" {
  # Arrange
  everything

  # Act
  tool card

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "Load               80%" ]]
  [[ "${lines[1]}" =~ ^Temperature\ +(-|[0-9]+°C)$ ]]
  [[ "${lines[2]}" == "Clock              2194MHz" ]]
  [[ "${lines[3]}" == "Load average       0.50 1.25 2.00" ]]
  [[ "${lines[4]}" == "Cores              4" ]]
  [[ "${lines[5]}" == "Governor           powersave" ]]
  [[ "${lines[6]}" == "Top process        My App, 42%" ]]
  [[ "${lines[7]}" == $'History            \xe2\x96\x85\xe2\x96\x86\xe2\x96\x87' ]]
  [[ "${lines[8]}" == "Read. 80% of the CPU is busy." ]]
  [[ "${#lines[@]}" -eq 9 ]]
}

@test "commands - with no sources the card has a dash in every row but the load" {
  # Arrange
  proc_file other ""

  # Act
  tool card

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "Load               0%" ]]
  [[ "${lines[2]}" == "Clock              -" ]]
  [[ "${lines[3]}" == "Load average       -" ]]
  [[ "${lines[6]}" == "Top process        -" ]]
  [[ "${lines[8]}" == "Read. 0% of the CPU is busy." ]]
}

@test "commands - where gum draws the card is a table and a closing sentence" {
  # Arrange
  everything
  export REVAMPED_TEST_GUM=1

  # Act
  tool card

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Figure"*"Value"* ]]
  [[ "${output}" == *"Load average"*"0.50 1.25 2.00"* ]]
  [[ "${output}" == *"Read. 80% of the CPU is busy."* ]]
}

@test "commands - apply binds the popup key and prints nothing" {
  # Arrange
  local started='^bind-key -N CPU details M-c run-shell'

  # Act
  tool apply

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  run sent "${started}"
  [[ "${output}" == "1" ]]
}

@test "commands - popup opens a monitor in a tmux popup and prints nothing" {
  # Arrange
  quiet htop ':'
  local opened='^display-popup -E -w 80% -h 80% htop$'

  # Act
  tool popup

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  run sent "${opened}"
  [[ "${output}" == "1" ]]
}

@test "commands - list prints what apply would send, and --json the same plan as one object" {
  # Arrange
  local path
  path=$(bin_path)
  option popup_key 'C-"'
  tool list
  [[ "${output}" == "bind-key -N CPU details C-\" run-shell ${path} popup" ]]

  # Act
  tool list --json

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == '{"bindings":[["bind-key","-N","CPU details","C-\"","run-shell","'*' popup"]]}' ]]
  run sends
  [[ -z "${output}" ]]
}

@test "commands - --json with any command but list is a usage error" {
  # Arrange
  sampled

  # Act
  tool --json card

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "cpu-revamped: option '--json' works only with list. run 'cpu-revamped help' for usage." ]]
}

@test "commands - the command line wins over the environment, and the environment over the tmux option" {
  # Arrange
  sampled 42 1000000
  option percentage_format 'option %s'
  tool status percentage
  [[ "${output}" == "option 42" ]]
  export CPU_REVAMPED_PERCENTAGE_FORMAT='environment %s'
  tool status percentage
  [[ "${output}" == "environment 42" ]]

  # Act
  tool --percentage-format 'line %s' status percentage

  # Assert
  [[ "${output}" == "line 42" ]]
}

@test "commands - an option takes its value after a space or an equals sign, and an empty label leaves the nerd glyph" {
  # Arrange
  sampled 42 1000000
  option icons nerd
  tool --percentage-label=C: status percentage
  [[ "${output}" == "C: 42%" ]]

  # Act
  tool --percentage-label '' status percentage

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == $'\xf3\xb0\x8a\x9a 42%' ]]
}

@test "commands - the popup command is an option too, with its arguments" {
  # Arrange
  quiet glances ':'

  # Act
  tool --popup-command 'glances -t 2' popup

  # Assert
  [[ "${status}" -eq 0 ]]
  run sent '^display-popup -E -w 80% -h 80% glances -t 2$'
  [[ "${output}" == "1" ]]
}

@test "commands - an unknown option, one without its value and a word after a double dash are usage errors" {
  # Arrange
  tool --colour red status graph
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "cpu-revamped: unknown option '--colour'. run 'cpu-revamped help' for usage." ]]
  tool --colour=red status graph
  [[ "${output}" == "cpu-revamped: unknown option '--colour'. run 'cpu-revamped help' for usage." ]]
  tool -x
  [[ "${output}" == "cpu-revamped: unknown option '-x'. run 'cpu-revamped help' for usage." ]]
  tool status --interval
  [[ "${output}" == "cpu-revamped: option '--interval' needs a value. run 'cpu-revamped help' for usage." ]]

  # Act
  tool -- --interval

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "cpu-revamped: unknown command '--interval'. run 'cpu-revamped help' for usage." ]]
}

@test "commands - a bad number is reported alone, since the reader of the environment reads it to the end" {
  # Arrange
  mkdir -p "${BATS_TEST_TMPDIR}/stubs"
  cat >"${BATS_TEST_TMPDIR}/stubs/env" <<'STUB'
#!/bin/sh
{ set +x; } 2>/dev/null
trap '' PIPE
printf 'CPU_REVAMPED_INTERVAL=soon\n'
count=0
while [ "${count}" -lt 4000 ]; do
  printf 'FILLER_%s=%0100d\n' "${count}" 0 || exit 1
  count=$((count + 1))
done
STUB
  chmod +x "${BATS_TEST_TMPDIR}/stubs/env"

  # Act
  tool status graph

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "cpu-revamped: --interval must be a whole number, got: soon" ]]
}

@test "commands - a number is checked before anything runs, whichever setting carries it" {
  # Arrange
  tool --interval soon status graph
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "cpu-revamped: --interval must be a whole number, got: soon" ]]
  tool --detail-interval often status graph
  [[ "${output}" == "cpu-revamped: --detail-interval must be a whole number, got: often" ]]
  tool --graph-width long status graph
  [[ "${output}" == "cpu-revamped: --graph-width must be a whole number, got: long" ]]
  tool --temp-high-thresh hot status graph
  [[ "${output}" == "cpu-revamped: --temp-high-thresh must be a whole number, got: hot" ]]
  tool --top-process-width wide status graph
  [[ "${output}" == "cpu-revamped: --top-process-width must be a whole number, got: wide" ]]

  # Act
  tool --high-thresh most status graph

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "cpu-revamped: --high-thresh must be a whole number, got: most" ]]
}

@test "commands - a load ratio is a number, whole or with a decimal point" {
  # Arrange
  sampled 42 1000000
  tool --load-medium-ratio many status graph
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "cpu-revamped: --load-medium-ratio must be a number, got: many" ]]
  tool --load-high-ratio 1.5.2 status graph
  [[ "${output}" == "cpu-revamped: --load-high-ratio must be a number, got: 1.5.2" ]]

  # Act
  tool --load-medium-ratio 0.5 --load-high-ratio 2 status load_color

  # Assert
  [[ "${status}" -eq 0 ]]
}

@test "commands - a width given as nothing is no width, and the fixed and the popup widths are not numbers" {
  # Arrange
  sampled 9 1000000

  # Act
  tool --percentage-width '' --fixed-width on --popup-width 90% status percentage

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "  9%" ]]
}

@test "commands - each choice is checked before anything runs" {
  # Arrange
  tool --icons emoji status graph
  [[ "${output}" == "cpu-revamped: --icons must be ascii or nerd, got: emoji" ]]
  tool --fixed-width yes status graph
  [[ "${output}" == "cpu-revamped: --fixed-width must be on or off, got: yes" ]]
  tool --temp-unit K status graph
  [[ "${output}" == "cpu-revamped: --temp-unit must be C or F, got: K" ]]
  tool --throttle-when-detached on status graph
  [[ "${output}" == "cpu-revamped: --throttle-when-detached must be 0 or 1, got: on" ]]

  # Act
  tool --render both status graph

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "cpu-revamped: --render must be jobs or options, got: both" ]]
}

@test "commands - on Linux doctor names the files it reads, and a default key someone else holds" {
  # Arrange
  local load='stat +ok +/proc/stat, holds the load' averages='loadavg +ok +/proc/loadavg, holds the load averages' info='cpuinfo +ok +/proc/cpuinfo, holds the core count and the clock' popup='popup +ok +tmux 3\.6 opens the detail popup' taken='keys +warn +already bound and left alone: M-c'
  linux_host
  printf 'bind-key    -T prefix M-c     display-message mine\n' >"${FAKE}/keys"

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ${load} ]]
  [[ "${output}" =~ ${averages} ]]
  [[ "${output}" =~ ${info} ]]
  [[ "${output}" =~ ${popup} ]]
  [[ "${output}" =~ ${taken} ]]
  [[ "${output}" =~ governor\ +ok\ +.*scaling_governor,\ holds\ the\ governor ]]
}

@test "commands - on Linux doctor warns about each source that is missing and exits 0" {
  # Arrange
  local load='stat +warn +/proc/stat cannot be read, so the load stays 0' averages='loadavg +warn +/proc/loadavg cannot be read' info='cpuinfo +warn +/proc/cpuinfo cannot be read' governor='governor +warn +no scaling governor is readable' sensors='sensors +warn +the temperature needs a thermal zone' top='ps +warn +without it the busiest process stays empty'
  proc_file other ""

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ${load} ]]
  [[ "${output}" =~ ${averages} ]]
  [[ "${output}" =~ ${info} ]]
  [[ "${output}" =~ ${governor} ]]
  [[ "${output}" =~ ${sensors} ]]
  [[ "${output}" =~ ${top} ]]
}

@test "commands - on Linux doctor names sensors and ps when they are installed" {
  # Arrange
  local sensors='sensors +ok +.*/sensors, reads the temperature when no thermal zone' top='ps +ok +.*/ps, names the busiest process'
  linux_host
  says sensors ""
  processes

  # Act
  tool doctor

  # Assert
  [[ "${output}" =~ ${sensors} ]]
  [[ "${output}" =~ ${top} ]]
}

@test "commands - on macOS doctor names iostat, sysctl and the temperature tools" {
  # Arrange
  local load='iostat +ok +.*/iostat, reads the load' sysctl='sysctl +ok +.*/sysctl, reads the clock' macmon='macmon +ok +.*/macmon, reads the temperature on Apple Silicon' osx='osx-cpu-temp +ok +.*/osx-cpu-temp, reads the temperature on an Intel Mac' istats='istats +ok +.*/istats, reads the temperature when osx-cpu-temp is missing' governor='governor +warn +macOS has no CPU governor'
  macos
  iostat_says
  sysctl_set loadavg ""
  says macmon ""
  says osx-cpu-temp ""
  says istats ""

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ${load} ]]
  [[ "${output}" =~ ${sysctl} ]]
  [[ "${output}" =~ ${macmon} ]]
  [[ "${output}" =~ ${osx} ]]
  [[ "${output}" =~ ${istats} ]]
  [[ "${output}" =~ ${governor} ]]
}

@test "commands - on macOS doctor names top when iostat is missing, and warns about each tool that is missing" {
  # Arrange
  local top='top +ok +.*/top, reads the load' none='top +warn +without iostat or top the load stays 0' sysctl='sysctl +warn +without it those figures stay empty' macmon='macmon +warn +without it the temperature stays empty on Apple Silicon' osx='osx-cpu-temp +warn +the temperature falls back to istats' istats='istats +warn +without it and osx-cpu-temp'
  macos
  top_says
  tool doctor
  [[ "${output}" =~ ${top} ]]
  unstub top

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ${none} ]]
  [[ "${output}" =~ ${sysctl} ]]
  [[ "${output}" =~ ${macmon} ]]
  [[ "${output}" =~ ${osx} ]]
  [[ "${output}" =~ ${istats} ]]
}

@test "commands - doctor names the monitor the popup opens: the command set, then btop, then htop, then top" {
  # Arrange
  local first='monitor +ok +.*/btop, opens in the popup' second='monitor +ok +.*/htop, opens in the popup' third='monitor +ok +.*/top, opens in the popup' none='monitor +warn +top is not installed, so the popup names it in a message' own='monitor +ok +.*/glances, opens in the popup' missing='monitor +warn +nothing-here is not installed'
  tool doctor
  [[ "${output}" =~ ${none} ]]
  quiet top ':'
  tool doctor
  [[ "${output}" =~ ${third} ]]
  quiet htop ':'
  tool doctor
  [[ "${output}" =~ ${second} ]]
  quiet btop ':'
  tool doctor
  [[ "${output}" =~ ${first} ]]
  quiet glances ':'
  option popup_command "glances -t 2"
  tool doctor
  [[ "${output}" =~ ${own} ]]
  option popup_command "nothing-here --x"

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ${missing} ]]
}

@test "commands - doctor warns when the tmux is too old for the popup" {
  # Arrange
  local old='popup +warn +the detail popup needs tmux 3\.2 or later'
  tmux_is 3.1

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ${old} ]]
}

@test "commands - doctor names a tmux option whose value it does not know" {
  # Arrange
  option render both
  option graph_width lots
  option temp_unit K

  # Act
  tool doctor

  # Assert
  run grep '^settings' <<<"${output}"
  [[ "${output}" == "settings           warn     unknown values: render=both temp_unit=K graph_width=lots" ]]
}
