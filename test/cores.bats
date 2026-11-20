#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/cpu_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/cpu_helpers.bash"

sample() {
  lib_run cpu 'CPU_REVAMPED_SYS="'"${SYS}"'"; CPU_REVAMPED_WANT="'"${1:-}"'"; cpu_revamped_load; cpu_revamped_refresh; printf "stored=%s\n" "${CPU_REVAMPED_STORED}"'
}

shown() {
  lib_run cpu 'cpu_revamped_load; cpu_revamped_show '"$1"
}

first_counters=$'cpu  2000 0 600 3000 0\ncpu0 400 0 100 1000 0\ncpu1 100 0 100 800 0\ncpu2 0 0 0 100 0'
busier_counters=$'cpu  2100 0 700 3100 0\ncpu0 440 0 110 1050 0\ncpu1 100 0 100 900 0\ncpu2 100 0 0 100 0'
backwards_counters=$'cpu  2200 0 800 3200 0\ncpu0 600 0 100 1000 0\ncpu1 50 0 50 800 0\ncpu2 200 0 0 100 0'

cores_pass() {
  busy "cpu  1000 0 500 8000 500 0 0 0 0 0" "$1"
  sample "${2:-cores}"
}

@test "cores - on Linux the first sample has no previous counters, so it prints nothing and keeps the counters" {
  # Arrange
  cpuinfo

  # Act
  cores_pass "${first_counters}"

  # Assert
  holds cores ""
  holds cores_stat "1500:1000 1000:800 100:100"
  holds cores_ts 1000000
  shown cores
  [[ -z "${output}" ]]
}

@test "cores - on Linux a steady second sample is each core's busy share since the previous one" {
  # Arrange
  cores_pass "${first_counters}"
  later 10

  # Act
  cores_pass "${busier_counters}"

  # Assert
  holds cores "50 0 100"
  holds cores_stat "1600:1050 1100:900 200:100"
  holds cores_ts 1000010
  shown cores
  [[ "${output}" == $'\xe2\x96\x84\xe2\x96\x81\xe2\x96\x88' ]]
}

@test "cores - a share rounds to the nearest whole" {
  # Arrange
  cores_pass $'cpu  1 0 0 0 0\ncpu0 0 0 0 0 0\ncpu1 0 0 0 0 0'
  later 10

  # Act
  cores_pass $'cpu  1 0 0 0 0\ncpu0 1 0 0 2 0\ncpu1 2 0 0 1 0'

  # Assert
  holds cores "33 67"
}

@test "cores - counters that went backwards or a core with no change are 0, and the next sample goes on from them" {
  # Arrange
  cores_pass "${busier_counters}"
  later 10
  cores_pass "${backwards_counters}"
  holds cores "0 0 100"
  later 10

  # Act
  cores_pass "${backwards_counters}"

  # Assert
  holds cores "0 0 0"
  holds cores_stat "1700:1000 900:800 300:100"
}

@test "cores - two samples in the same second keep the previous bars and the previous counters" {
  # Arrange
  cores_pass "${first_counters}"
  later 10
  cores_pass "${busier_counters}"

  # Act
  cores_pass "${backwards_counters}"

  # Assert
  holds cores "50 0 100"
  holds cores_stat "1600:1050 1100:900 200:100"
  holds cores_ts 1000010
}

@test "cores - a change in the number of cores starts again with no bars" {
  # Arrange
  cores_pass "${first_counters}"
  later 10

  # Act
  cores_pass $'cpu  2100 0 700 3100 0\ncpu0 440 0 110 1050 0\ncpu1 100 0 100 900 0'

  # Assert
  holds cores ""
  holds cores_stat "1600:1050 1100:900"
}

@test "cores - a /proc/stat with no core lines leaves no bars and no counters" {
  # Arrange
  option cores "10 20"
  option cores_stat "1:1 2:2"

  # Act
  cores_pass "cpu  1 0 0 0 0"

  # Assert
  holds cores ""
  holds cores_stat ""
}

@test "cores - the counters are read only for a status line that shows the bars" {
  # Arrange
  cores_pass "${first_counters}" percentage

  # Act
  shown cores

  # Assert
  holds cores ""
  holds cores_stat ""
  holds cores_ts ""
  [[ -z "${output}" ]]
}

@test "cores - a placeholder asked for by hand has its bars read even when the status line does not use it" {
  # Arrange
  busy "cpu  1 0 0 0 0" "${first_counters}"
  option published percentage
  sampled 42 999990

  # Act
  lib_run cpu 'cpu_revamped_status cores'

  # Assert
  [[ -z "${output}" ]]
  eventually holds cores_stat "1500:1000 1000:800 100:100"
}

@test "cores - on macOS the bars come from the counters JXA reads through host_processor_info" {
  # Arrange
  macos
  iostat_says
  jxa_says $'cpu0 100 0 100 800\ncpu1 0 0 0 100'
  sample cores
  holds cores ""
  holds cores_stat "1000:800 100:100"
  later 10
  jxa_says $'cpu0 140 0 110 850\ncpu1 50 0 0 100'

  # Act
  sample cores

  # Assert
  holds cores "50 100"
  run cat "${FAKE}/jxa"
  [[ "${#lines[@]}" -eq 2 ]]
}

@test "cores - on macOS nothing is asked for bars the status line does not show" {
  # Arrange
  macos
  iostat_says
  jxa_says $'cpu0 100 0 100 800'

  # Act
  sample percentage

  # Assert
  [[ ! -e "${FAKE}/jxa" ]]
  holds cores ""
}

@test "cores - on macOS a JXA that fails falls back to macmon, whose share of each core needs no earlier counters" {
  # Arrange
  macos
  iostat_says
  jxa_says "execution error"
  says macmon '{"cpu_tiers":[{"active_ratio":0.5,"cores":[{"active_ratio":0.25,"core_id":0,"freq_mhz":2568},{"active_ratio":0.756,"core_id":10,"freq_mhz":2568}]},{"active_ratio":0.5,"cores":[{"active_ratio":1.0,"core_id":20}]}],"ecpu_cores":[{"active_ratio":0.9,"core_id":0}],"pcpu_cores":[{"active_ratio":0.8,"core_id":20}]}'

  # Act
  sample cores

  # Assert
  holds cores "25 76 100"
  holds cores_stat ""
  run asked
  [[ "${output}" == *"macmon pipe -s 1 -i 200"* ]]
}

@test "cores - on macOS without osascript macmon is the source" {
  # Arrange
  macos
  iostat_says
  says macmon '{"cpu_tiers":[{"cores":[{"active_ratio":0.1,"core_id":0}]}]}'

  # Act
  sample cores

  # Assert
  holds cores 10
  [[ ! -e "${FAKE}/jxa" ]]
}

@test "cores - on macOS with neither osascript nor macmon there are no bars" {
  # Arrange
  macos
  iostat_says
  option cores "10 20"

  # Act
  sample cores

  # Assert
  holds cores ""
  holds cores_stat ""
}

@test "cores - on a system that is neither macOS nor Linux there are no bars" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=FreeBSD

  # Act
  sample cores

  # Assert
  holds cores ""
}

@test "cores - a label, a width and the nerd glyph go with the bars, and a label set to off keeps them bare" {
  # Arrange
  option cores "0 100"
  option icons nerd
  shown cores
  [[ "${output}" == $'\xf3\xb0\xbb\xa0 \xe2\x96\x81\xe2\x96\x88' ]]
  option cores_label 'C:'
  option cores_width 4
  shown cores
  [[ "${output}" == $'C:   \xe2\x96\x81\xe2\x96\x88' ]]
  option cores_label off

  # Act
  shown cores

  # Assert
  [[ "${output}" == $'  \xe2\x96\x81\xe2\x96\x88' ]]
}

@test "cores - a core share that is no number is a bar of zero, and one above a hundred a full bar" {
  # Arrange
  option cores "x 250"

  # Act
  shown cores

  # Assert
  [[ "${output}" == $'\xe2\x96\x81\xe2\x96\x88' ]]
}
