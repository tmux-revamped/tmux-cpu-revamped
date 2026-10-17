#!/usr/bin/env bash
#
# doctor.sh: capability report explaining which sources this host exposes.
#
# Answers the top support question: why a token is empty here. It names the
# platform, whether the popup is available, which temperature path applies, and
# which optional tools are installed. Every probe goes through an existing seam,
# so the report is testable without touching real hardware.

[[ -n "${_CPU_REVAMPED_DOCTOR_LOADED:-}" ]] && return 0
_CPU_REVAMPED_DOCTOR_LOADED=1

_CPU_DOCTOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_CPU_DOCTOR_DIR}/../utils/platform.sh"
# shellcheck source=/dev/null
source "${_CPU_DOCTOR_DIR}/../utils/has-command.sh"
# shellcheck source=/dev/null
source "${_CPU_DOCTOR_DIR}/popup.sh"

# cpu_doctor_tool NAME -> one line stating whether NAME is on PATH.
cpu_doctor_tool() {
  if has_command "${1}"; then
    echo "tool ${1}: found"
  else
    echo "tool ${1}: missing"
  fi
}

# cpu_doctor_temp -> one line explaining the temperature source on this host.
cpu_doctor_temp() {
  if is_apple_silicon && has_command macmon; then
    echo "temperature: macmon (Apple Silicon)"
  elif is_apple_silicon; then
    echo "temperature: unavailable on Apple Silicon until macmon is installed"
  elif is_macos; then
    echo "temperature: osx-cpu-temp or istats (Intel Macs)"
  else
    echo "temperature: thermal zone, coretemp, k10temp, or sensors"
  fi
}

# cpu_doctor -> print the full capability report.
cpu_doctor() {
  echo "tmux-cpu-revamped doctor"
  echo "platform: $(platform_os) $(platform_arch)"
  if cpu_popup_supported; then
    echo "popup: supported"
  else
    echo "popup: needs tmux 3.2+"
  fi
  cpu_doctor_temp
  cpu_doctor_tool macmon
  cpu_doctor_tool sensors
  cpu_doctor_tool osx-cpu-temp
  cpu_doctor_tool istats
  cpu_doctor_tool btop
}

export -f cpu_doctor_tool
export -f cpu_doctor_temp
export -f cpu_doctor
