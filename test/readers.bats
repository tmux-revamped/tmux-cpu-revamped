#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/cpu_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/cpu_helpers.bash"

sample() {
  lib_run cpu 'CPU_REVAMPED_SYS="'"${SYS}"'"; CPU_REVAMPED_WANT="'"${1:-}"'"; cpu_revamped_load; cpu_revamped_refresh; printf "stored=%s\n" "${CPU_REVAMPED_STORED}"'
}

temperature() {
  lib_run cpu 'CPU_REVAMPED_SYS="'"${SYS}"'"; cpu_revamped_temp_read; printf "[%s]" "${CPU_REVAMPED_F_temp}"'
}

everything="temp freq load top_process governor"

@test "readers - on Linux a sample turns /proc/stat into the load, and the details into their figures" {
  # Arrange
  linux_host
  processes

  # Act
  sample "${everything}"

  # Assert
  [[ "${output}" == "stored=1" ]]
  holds percent 80
  holds history 80
  holds freq 2194
  holds load 0.50
  holds load5 1.25
  holds load15 2.00
  holds count 4
  holds governor powersave
  holds top_process "42 My App"
  holds percent_ts 1000000
  holds freq_ts 1000000
  holds load_ts 1000000
  holds governor_ts 1000000
  holds top_process_ts 1000000
}

@test "readers - on Linux the load is the busy share of two reads of /proc/stat, taken 0.3 seconds apart" {
  # Arrange
  busy

  # Act
  sample

  # Assert
  holds percent 80
  run cat "${FAKE}/slept"
  [[ "${output}" == "0.3" ]]
  run asked
  [[ "${output}" == $'cat /proc/stat\ncat /proc/stat' ]]
}

@test "readers - on Linux iowait counts as idle and a share rounds to the nearest whole" {
  # Arrange
  busy "cpu  100 0 100 700 100 0 0 0" "cpu  110 0 100 720 170 0 0 0"
  sample
  holds percent 10
  busy "cpu  0 0 0 0 0 0 0 0" "cpu  10 0 0 20 0 0 0 0"

  # Act
  sample

  # Assert
  holds percent 33
}

@test "readers - on Linux a read that goes backwards is no load, and so is one that does not move" {
  # Arrange
  busy "cpu  500 0 0 0 0 0 0 0" "cpu  100 0 0 600 0 0 0 0"
  sample
  holds percent 0
  busy "cpu  500 0 0 0 0 0 0 0" "cpu  500 0 0 0 0 0 0 0"

  # Act
  sample

  # Assert
  holds percent 0
}

@test "readers - on Linux a /proc/stat that cannot be read is no load" {
  # Arrange
  proc_file other ""
  option percent 40

  # Act
  sample

  # Assert
  [[ "${output}" == "stored=1" ]]
  holds percent 0
  holds history 0
}

@test "readers - on macOS the load is a hundred less the idle share of the last iostat row" {
  # Arrange
  macos
  iostat_says

  # Act
  sample

  # Assert
  holds percent 30
  run asked
  [[ "${output}" == "iostat -c 2 -w 1 -n 0" ]]
}

@test "readers - on macOS without iostat the load comes from the last CPU usage line of top" {
  # Arrange
  macos
  top_says

  # Act
  sample

  # Assert
  holds percent 40
  run asked
  [[ "${output}" == "top -l2 -n0" ]]
}

@test "readers - on macOS an iostat without a row and a top without an idle share both mean no load" {
  # Arrange
  macos
  iostat_says "cpu
 us sy id"
  sample
  holds percent 0
  unstub iostat
  top_says "CPU usage: unknown"

  # Act
  sample

  # Assert
  holds percent 0
}

@test "readers - on macOS with neither iostat nor top the load is 0 and nothing is asked" {
  # Arrange
  macos

  # Act
  sample

  # Assert
  holds percent 0
  run asked
  [[ -z "${output}" ]]
}

@test "readers - on a system that is neither macOS nor Linux the load is 0" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=FreeBSD

  # Act
  sample "${everything}"

  # Assert
  holds percent 0
  holds freq ""
  holds load ""
  holds governor ""
}

@test "readers - on Linux the clock is the first cpu MHz of /proc/cpuinfo, cut to whole megahertz" {
  # Arrange
  busy
  cpuinfo

  # Act
  sample freq

  # Assert
  holds freq 2194
}

@test "readers - on Linux without a cpu MHz line the clock comes from scaling_cur_freq in kilohertz, and without both it is empty" {
  # Arrange
  busy
  cpuinfo "processor	: 0"
  scaling 3200000
  sample freq
  holds freq 3200
  proc_file scaling ""
  later

  # Act
  sample freq

  # Assert
  holds freq ""
}

@test "readers - on Apple Silicon the clock is looked up from the chip generation, and an unknown chip means 0" {
  # Arrange
  apple_silicon
  sysctl_set brand "Apple M2 Pro"
  sample freq
  holds freq 3400
  sysctl_set brand "Apple M5"
  later
  sample freq
  holds freq 4500
  sysctl_set brand "Apple M1"
  later 200
  sample freq
  holds freq 3200
  sysctl_set brand "Mystery"
  later 300

  # Act
  sample freq

  # Assert
  holds freq 0
  run asked
  [[ "${output}" == *"sysctl -n machdep.cpu.brand_string"* ]]
}

@test "readers - on an Intel Mac the clock is hw.cpufrequency in megahertz, and zero or nothing is empty" {
  # Arrange
  intel_mac
  sysctl_set cpufreq 2400000000
  sample freq
  holds freq 2400
  sysctl_set cpufreq 0
  later

  # Act
  sample freq

  # Assert
  holds freq ""
}

@test "readers - on Linux the load averages and the core count come from /proc/loadavg and /proc/cpuinfo" {
  # Arrange
  busy
  loadavg "3.10 2.20 1.30 2/100 99"
  cpuinfo

  # Act
  sample load

  # Assert
  holds load 3.10
  holds load5 2.20
  holds load15 1.30
  holds count 4
}

@test "readers - on Linux a loadavg and a cpuinfo that cannot be read leave the averages and the count empty" {
  # Arrange
  busy
  option load 9
  option count 9

  # Act
  sample load

  # Assert
  holds load ""
  holds load15 ""
  holds count ""
}

@test "readers - on macOS the load averages come from vm.loadavg and the core count from hw.ncpu" {
  # Arrange
  mac_host
  iostat_says

  # Act
  sample load

  # Assert
  holds load 1.52
  holds load5 1.60
  holds load15 1.70
  holds count 12
  run asked
  [[ "${output}" == *$'sysctl -n vm.loadavg\nsysctl -n hw.ncpu'* ]]
}

@test "readers - a vm.loadavg that is cut short and an ncpu that is no number leave them empty" {
  # Arrange
  macos
  sysctl_set loadavg "{ 1.52 }"
  sysctl_set ncpu many

  # Act
  sample load

  # Assert
  holds load ""
  holds count ""
}

@test "readers - the governor comes from scaling_governor on Linux and is empty on macOS" {
  # Arrange
  busy
  governor schedutil
  sample governor
  holds governor schedutil
  macos
  option governor stale
  later
  : >"${FAKE}/asked"

  # Act
  sample governor

  # Assert
  holds governor ""
  run asked
  [[ -z "${output}" ]]
}

@test "readers - the busiest process is the one with the most CPU, named by its last path part" {
  # Arrange
  busy
  processes

  # Act
  sample top_process

  # Assert
  holds top_process "42 My App"
  run asked
  [[ "${output}" == *"ps axo pcpu=,comm="* ]]
}

@test "readers - a bare command name that holds a slash keeps it, and a decimal share is cut to its whole part" {
  # Arrange
  busy
  processes "  1.0 init
 77.9 node/worker one
  5.0 tmux"

  # Act
  sample top_process

  # Assert
  holds top_process "77 node/worker one"
}

@test "readers - a ps that lists only idle processes or nothing leaves the busiest process empty" {
  # Arrange
  busy
  processes "  0.0 init
  0.0 tmux"
  option top_process "1 old"
  sample top_process
  holds top_process ""
  says ps ""
  option top_process "1 old"
  later

  # Act
  sample top_process

  # Assert
  holds top_process ""
}

@test "readers - only the details the status line uses are read" {
  # Arrange
  linux_host
  processes
  : >"${FAKE}/asked"

  # Act
  sample percentage

  # Assert
  holds freq ""
  holds load ""
  holds top_process ""
  holds governor ""
  run asked
  [[ "${output}" == $'cat /proc/stat\ncat /proc/stat' ]]
}

@test "readers - a detail is read again only after the detail interval" {
  # Arrange
  linux_host
  processes
  option governor old
  option governor_ts 999940
  option top_process "1 old"
  option top_process_ts 999940
  : >"${FAKE}/asked"

  # Act
  sample "governor top_process"

  # Assert
  holds governor old
  holds top_process "1 old"
  run asked
  [[ "${output}" == $'cat /proc/stat\ncat /proc/stat' ]]
}

@test "readers - a detail interval the person sets decides when a detail is read again, and junk there means sixty seconds" {
  # Arrange
  linux_host
  option detail_interval 30
  option governor old
  option governor_ts 999969
  sample governor
  holds governor powersave
  option detail_interval soon
  option governor old
  option governor_ts 999941

  # Act
  sample governor

  # Assert
  holds governor old
}

@test "readers - each sample joins the history, which keeps the newest samples up to the graph width" {
  # Arrange
  busy
  option history "10 20 30"
  sample
  holds history "10 20 30 80"
  option graph_width 2

  # Act
  sample

  # Assert
  holds history "80 80"
}

@test "readers - a graph width of zero or one that is not a number keeps twenty samples" {
  # Arrange
  busy
  option history "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25"
  option graph_width 0
  sample
  holds history "7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 80"
  option graph_width many

  # Act
  sample

  # Assert
  holds history "8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 80 80"
}

@test "readers - a thermal zone of a CPU is read in whole degrees, and the hottest one wins" {
  # Arrange
  thermal_zone 0 x86_pkg_temp 45900
  thermal_zone 1 acpitz 61000
  thermal_zone 2 iwlwifi_1 99000
  thermal_zone 3 cpu-thermal not-a-number

  # Act
  temperature

  # Assert
  [[ "${output}" == "[61]" ]]
}

@test "readers - a zone with leading zeros is read as a decimal number" {
  # Arrange
  thermal_zone 0 cpu_thermal 0042000
  thermal_zone 1 cpu_thermal 0000000

  # Act
  temperature

  # Assert
  [[ "${output}" == "[42]" ]]
}

@test "readers - without a thermal zone coretemp is read, and the hottest input wins" {
  # Arrange
  coretemp_input 0 1 55000
  coretemp_input 0 2 52000
  coretemp_input 1 1 junk

  # Act
  temperature

  # Assert
  [[ "${output}" == "[55]" ]]
}

@test "readers - without those a k10temp chip is read, its Tctl or Tdie sensor first" {
  # Arrange
  hwmon_chip 0 nvme
  hwmon_input 0 1 99000
  hwmon_chip 1 k10temp
  hwmon_input 1 1 70000 Tctl
  hwmon_input 1 2 90000 Tccd1
  hwmon_input 1 3 72000 Tdie
  hwmon_input 1 4 junk Tccd2

  # Act
  temperature

  # Assert
  [[ "${output}" == "[72]" ]]
}

@test "readers - a k10temp chip with no Tctl falls back to its hottest labelled sensor, and a chip with no name is skipped" {
  # Arrange
  mkdir -p "${SYS}/class/hwmon/hwmon9"
  hwmon_chip 1 k10temp
  hwmon_input 1 1 40000 Tccd1
  hwmon_input 1 2 50000
  hwmon_input 1 3 45000 Tccd2

  # Act
  temperature

  # Assert
  [[ "${output}" == "[50]" ]]
}

@test "readers - when no sysfs source exists sensors is read, from its first matching line" {
  # Arrange
  says sensors "coretemp-isa-0000
Adapter: ISA adapter
Package id 0:  +45.9°C  (high = +80.0°C, crit = +100.0°C)
Core 0:        +40.0°C  (high = +80.0°C, crit = +100.0°C)"

  # Act
  temperature

  # Assert
  [[ "${output}" == "[45]" ]]
}

@test "readers - a sensors line that matches but holds no reading means no temperature, and so does no sensors at all" {
  # Arrange
  says sensors "Tctl: unavailable
Core 0: +40.0°C"
  temperature
  [[ "${output}" == "[]" ]]
  unstub sensors

  # Act
  temperature

  # Assert
  [[ "${output}" == "[]" ]]
}

@test "readers - a sysfs source wins over sensors" {
  # Arrange
  thermal_zone 0 x86_pkg_temp 45000
  says sensors "Package id 0:  +99.0°C"

  # Act
  temperature

  # Assert
  [[ "${output}" == "[45]" ]]
  run asked
  [[ -z "${output}" ]]
}

@test "readers - on Apple Silicon macmon gives the temperature, rounded half up" {
  # Arrange
  apple_silicon
  says macmon '{"cpu_temp_avg":61.5,"gpu_temp_avg":50.2}'
  temperature
  [[ "${output}" == "[62]" ]]
  says macmon '{"cpu_temp_avg":61.4}'
  temperature
  [[ "${output}" == "[61]" ]]
  says macmon '{"cpu_temp_avg":0.4}'

  # Act
  temperature

  # Assert
  [[ "${output}" == "[0]" ]]
  run asked
  [[ "${output}" == *"macmon pipe -s 1 -i 200"* ]]
}

@test "readers - a macmon reading of zero, or none, falls through to osx-cpu-temp and then istats" {
  # Arrange
  apple_silicon
  says macmon '{"cpu_temp_avg":0.0}'
  says osx-cpu-temp "0.0°C"
  says istats "CPU temp:  58.0°C"
  temperature
  [[ "${output}" == "[58]" ]]
  says macmon '{"gpu_temp_avg":40.0}'
  says osx-cpu-temp "61.5°C"

  # Act
  temperature

  # Assert
  [[ "${output}" == "[62]" ]]
}

@test "readers - on an Intel Mac macmon is not asked, osx-cpu-temp is rounded half up and istats rounds to even" {
  # Arrange
  intel_mac
  says macmon '{"cpu_temp_avg":99.0}'
  says osx-cpu-temp "61.4°C"
  temperature
  [[ "${output}" == "[61]" ]]
  unstub osx-cpu-temp
  says istats "CPU temp:  61.5°C"
  temperature
  [[ "${output}" == "[62]" ]]
  says istats "CPU temp: 58
fan: 2000 rpm"

  # Act
  temperature

  # Assert
  [[ "${output}" == "[58]" ]]
  run asked
  [[ "${output}" != *macmon* ]]
}

@test "readers - istats with a reading of zero or none, and a Mac with no tool at all, mean no temperature" {
  # Arrange
  macos
  says istats "CPU temp: 0.0"
  temperature
  [[ "${output}" == "[]" ]]
  says istats "no sensors"
  temperature
  [[ "${output}" == "[]" ]]
  unstub istats

  # Act
  temperature

  # Assert
  [[ "${output}" == "[]" ]]
}

@test "readers - a system that is neither macOS nor Linux has no temperature" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=FreeBSD
  thermal_zone 0 x86_pkg_temp 45000

  # Act
  temperature

  # Assert
  [[ "${output}" == "[]" ]]
}

@test "readers - the temperature is read only for a placeholder that shows it, and stored with its time" {
  # Arrange
  linux_host
  thermal_zone 0 x86_pkg_temp 45000
  sample percentage
  holds temp ""
  holds temp_ts ""

  # Act
  sample alert

  # Assert
  holds temp 45
  holds temp_ts 1000000
}

@test "readers - a locale with a decimal comma still reads shares, temperatures and the busiest process with a point" {
  # Arrange
  apple_silicon
  iostat_says
  says macmon '{"cpu_temp_avg":61.5}'
  processes "  0.9 slow
  0.5 idle
  1.5 busy"
  export LC_ALL=pt_BR.UTF-8 LC_NUMERIC=pt_BR.UTF-8

  # Act
  sample "temp top_process"

  # Assert
  holds temp 62
  holds top_process "1 busy"
  holds percent 30
}

@test "readers - a whole sample reaches tmux in one call" {
  # Arrange
  linux_host
  processes

  # Act
  sample "${everything}"

  # Assert
  run sends
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "${lines[0]}" == "set-option -gq @cpu_revamped_percent 80 ; set-option -gq @cpu_revamped_history 80 ; "*" ; set-option -gq @cpu_revamped_governor_ts 1000000" ]]
}

@test "readers - a sample tmux refuses is reported as not stored" {
  # Arrange
  linux_host
  printf 'refused\n' >"${FAKE}/refused"

  # Act
  sample

  # Assert
  [[ "${output}" == "stored=0" ]]
  holds percent ""
}
