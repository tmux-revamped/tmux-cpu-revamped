#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/cpu_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/cpu_helpers.bash"

sample() {
  lib_run cpu 'CPU_REVAMPED_SYS="'"${SYS}"'"; CPU_REVAMPED_WANT="'"${1:-throttle}"'"; cpu_revamped_load; cpu_revamped_refresh; printf "stored=%s\n" "${CPU_REVAMPED_STORED}"'
}

shown() {
  lib_run cpu 'cpu_revamped_load; cpu_revamped_show '"$1"
}

episode() {
  throttle_count 0 core "$1"
  throttle_count 0 package "$2"
  sample "${3:-throttle}"
  later
}

@test "throttle - on Linux the first sample has no earlier counts, so the CPU is not held back" {
  # Arrange
  linux_host
  throttle_count 0 core 5
  throttle_count 0 package 7

  # Act
  sample

  # Assert
  holds throttle 0
  holds throttle_count "5 7"
  holds throttle_ts 1000000
  shown throttle
  [[ -z "${output}" ]]
}

@test "throttle - on Linux a rise of any counter since the previous sample means the CPU is held back" {
  # Arrange
  linux_host
  episode 5 7

  # Act
  episode 5 8

  # Assert
  holds throttle 1
  holds throttle_count "5 8"
  shown throttle
  [[ "${output}" == "throttled" ]]
}

@test "throttle - on Linux counters that stay put or go back end the episode" {
  # Arrange
  linux_host
  episode 5 7
  episode 6 7
  holds throttle 1
  episode 6 7
  holds throttle 0

  # Act
  episode 2 1

  # Assert
  holds throttle 0
  holds throttle_count "2 1"
}

@test "throttle - on Linux a counter that is no number is skipped, and with no counter at all the flag stays empty" {
  # Arrange
  linux_host
  throttle_count 0 core junk
  throttle_count 1 core 4
  throttle_count 0 package ""
  sample
  holds throttle 0
  holds throttle_count 4
  rm -rf "${SYS}/devices"
  later

  # Act
  sample

  # Assert
  holds throttle ""
  holds throttle_count ""
  shown throttle
  [[ -z "${output}" ]]
}

@test "throttle - the counters are read again only after the detail interval" {
  # Arrange
  linux_host
  throttle_count 0 core 5
  sample
  throttle_count 0 core 9
  later 10

  # Act
  sample

  # Assert
  holds throttle 0
  holds throttle_count 5
}

@test "throttle - the counters are read only for a status line that shows the flag" {
  # Arrange
  linux_host
  throttle_count 0 core 5

  # Act
  sample percentage

  # Assert
  holds throttle ""
  holds throttle_count ""
  holds throttle_ts ""
}

@test "throttle - the icon is the person's to set, and off prints nothing" {
  # Arrange
  option throttle 1
  option throttle_icon HOT
  shown throttle
  [[ "${output}" == "HOT" ]]
  option throttle_icon off

  # Act
  shown throttle

  # Assert
  [[ -z "${output}" ]]
}

@test "throttle - on macOS a CPU speed limit under 100 means the CPU is held back" {
  # Arrange
  macos
  iostat_says
  says pmset "Note: No thermal warning level has been recorded
CPU_Scheduler_Limit = 100
CPU_Available_CPUs = 8
CPU_Speed_Limit = 70"

  # Act
  sample

  # Assert
  holds throttle 1
  run asked
  [[ "${output}" == *"pmset -g therm"* ]]
}

@test "throttle - on macOS a thermal warning level above nominal means the CPU is held back" {
  # Arrange
  macos
  iostat_says
  says pmset "CPU_Speed_Limit = 100
Thermal warning level: 2"

  # Act
  sample

  # Assert
  holds throttle 1
}

@test "throttle - on macOS a full speed limit, a nominal level and the note about no level mean the CPU is not held back" {
  # Arrange
  macos
  iostat_says
  says pmset "Note: No thermal warning level has been recorded
Note: No performance warning level has been recorded
CPU_Speed_Limit = 100
Thermal warning level: 0"

  # Act
  sample

  # Assert
  holds throttle 0
}

@test "throttle - on macOS a pmset that answers nothing, or none at all, leaves the flag empty" {
  # Arrange
  macos
  iostat_says
  says pmset ""
  option throttle 1
  sample
  holds throttle ""
  unstub pmset
  later

  # Act
  sample

  # Assert
  holds throttle ""
}

@test "throttle - on a system that is neither macOS nor Linux the flag stays empty" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=FreeBSD

  # Act
  sample

  # Assert
  holds throttle ""
}

@test "notify - one notification when throttling starts, none while it goes on or when it ends, and one more for the next episode" {
  # Arrange
  linux_host
  notifier_says
  option notify 1
  episode 5 7
  holds notified ""
  episode 6 7
  holds notified 1
  episode 7 7
  episode 7 7
  holds notified 0
  run notices
  [[ "${output}" == "-- CPU throttled The CPU is running below its full speed." ]]

  # Act
  episode 8 7

  # Assert
  holds notified 1
  run notices
  [[ "${#lines[@]}" -eq 2 ]]
}

@test "notify - on macOS the notification goes through osascript with the title and message as arguments" {
  # Arrange
  macos
  iostat_says
  jxa_says ""
  says pmset "CPU_Speed_Limit = 50"
  option notify 1

  # Act
  sample

  # Assert
  holds notified 1
  run notices
  [[ "${output}" == "-e on run argv -e display notification (item 2 of argv) with title (item 1 of argv) -e end run CPU throttled The CPU is running below its full speed." ]]
}

@test "notify - at 0 nothing is sent and nothing is remembered" {
  # Arrange
  linux_host
  notifier_says
  episode 5 7

  # Act
  episode 6 7

  # Assert
  holds throttle 1
  holds notified ""
  run notices
  [[ -z "${output}" ]]
}

@test "notify - without a placeholder that shows the flag nothing is read and nothing is sent" {
  # Arrange
  linux_host
  notifier_says
  option notify 1
  throttle_count 0 core 5

  # Act
  sample percentage

  # Assert
  holds notified ""
  run notices
  [[ -z "${output}" ]]
}

@test "notify - a flag that could not be read sends nothing, and no notifier is no error" {
  # Arrange
  linux_host
  option notify 1
  sample
  holds notified ""
  throttle_count 0 core 5
  later
  sample
  throttle_count 0 core 6
  later

  # Act
  sample

  # Assert
  [[ "${output}" == "stored=1" ]]
  holds notified 1
}
