#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _CPU_REVAMPED_DOCTOR_LOADED _CPU_REVAMPED_POPUP_LOADED
  unset _TMUX_PLUGIN_PLATFORM_LOADED _TMUX_PLUGIN_HAS_COMMAND_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/cpu/doctor.sh"
}

teardown() {
  cleanup_test_environment
}

@test "doctor.sh - functions are defined" {
  function_exists cpu_doctor
  function_exists cpu_doctor_tool
  function_exists cpu_doctor_temp
}

@test "doctor.sh - cpu_doctor_tool reports a found tool" {
  has_command() { return 0; }
  [[ "$(cpu_doctor_tool sensors)" == "tool sensors: found" ]]
}

@test "doctor.sh - cpu_doctor_tool reports a missing tool" {
  has_command() { return 1; }
  [[ "$(cpu_doctor_tool sensors)" == "tool sensors: missing" ]]
}

@test "doctor.sh - cpu_doctor_temp explains Apple Silicon" {
  _PLATFORM_OS_CACHE="Darwin"
  _PLATFORM_ARCH_CACHE="arm64"
  [[ "$(cpu_doctor_temp)" == *"Apple Silicon"* ]]
}

@test "doctor.sh - cpu_doctor_temp explains Intel macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  _PLATFORM_ARCH_CACHE="x86_64"
  [[ "$(cpu_doctor_temp)" == *"osx-cpu-temp or istats"* ]]
}

@test "doctor.sh - cpu_doctor_temp explains Linux" {
  _PLATFORM_OS_CACHE="Linux"
  _PLATFORM_ARCH_CACHE="x86_64"
  [[ "$(cpu_doctor_temp)" == *"thermal zone"* ]]
}

@test "doctor.sh - cpu_doctor reports a supported popup" {
  _PLATFORM_OS_CACHE="Linux"
  _PLATFORM_ARCH_CACHE="x86_64"
  has_command() { return 1; }
  cpu_popup_supported() { return 0; }
  run cpu_doctor
  [[ "${output}" == *"tmux-cpu-revamped doctor"* ]]
  [[ "${output}" == *"platform: Linux x86_64"* ]]
  [[ "${output}" == *"popup: supported"* ]]
  [[ "${output}" == *"tool btop: missing"* ]]
}

@test "doctor.sh - cpu_doctor reports an unsupported popup" {
  _PLATFORM_OS_CACHE="Darwin"
  _PLATFORM_ARCH_CACHE="arm64"
  has_command() { return 0; }
  cpu_popup_supported() { return 1; }
  run cpu_doctor
  [[ "${output}" == *"popup: needs tmux 3.2+"* ]]
  [[ "${output}" == *"tool sensors: found"* ]]
}

@test "doctor.sh - cpu_doctor_temp names macmon on Apple Silicon when it is installed" {
  # Arrange
  _PLATFORM_OS_CACHE="Darwin"
  _PLATFORM_ARCH_CACHE="arm64"
  has_command() { [[ "${1}" == "macmon" ]]; }

  # Act
  run cpu_doctor_temp

  # Assert
  [[ "${output}" == "temperature: macmon (Apple Silicon)" ]]
}

@test "doctor.sh - cpu_doctor_temp asks for macmon on Apple Silicon without it" {
  # Arrange
  _PLATFORM_OS_CACHE="Darwin"
  _PLATFORM_ARCH_CACHE="arm64"
  has_command() { return 1; }

  # Act
  run cpu_doctor_temp

  # Assert
  [[ "${output}" == "temperature: unavailable on Apple Silicon until macmon is installed" ]]
}

@test "doctor.sh - cpu_doctor lists macmon among the tools" {
  # Arrange
  _PLATFORM_OS_CACHE="Darwin"
  _PLATFORM_ARCH_CACHE="arm64"
  has_command() { return 1; }
  cpu_popup_supported() { return 0; }

  # Act
  run cpu_doctor

  # Assert
  [[ "${output}" == *"tool macmon: missing"* ]]
}
