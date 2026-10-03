#!/usr/bin/env bash
#
# cpu.sh: CPU load and temperature acquisition.
#
# The parser functions are pure: they take command output as text and return a
# number, which is what makes them testable without real hardware. The reader
# functions perform the actual sampling and run only inside the background worker,
# so their cost never lands on the status render. The thin _read_* seams exist so
# tests can stub the host probes deterministically.

[[ -n "${_CPU_REVAMPED_CPU_LOADED:-}" ]] && return 0
_CPU_REVAMPED_CPU_LOADED=1

_CPU_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_CPU_LIB_DIR}/../utils/platform.sh"
# shellcheck source=/dev/null
source "${_CPU_LIB_DIR}/../utils/has-command.sh"

# Seconds the Linux sampler waits between the two /proc/stat reads.
CPU_SAMPLE_INTERVAL="${CPU_SAMPLE_INTERVAL:-0.3}"

# _cpu_stat_total_idle LINE -> "<total> <idle>" parsed from a /proc/stat cpu line.
_cpu_stat_total_idle() {
  local line="${1}"
  local -a f
  read -ra f <<< "${line}"
  local total=0 i
  for (( i = 1; i < ${#f[@]}; i++ )); do
    [[ "${f[i]}" =~ ^[0-9]+$ ]] || continue
    total=$(( total + f[i] ))
  done
  local idle=$(( ${f[4]:-0} + ${f[5]:-0} ))
  echo "${total} ${idle}"
}

# cpu_pct_from_stat LINE1 LINE2 -> integer load percent across the interval.
cpu_pct_from_stat() {
  local t1 i1 t2 i2
  read -r t1 i1 <<< "$(_cpu_stat_total_idle "${1}")"
  read -r t2 i2 <<< "$(_cpu_stat_total_idle "${2}")"
  local dt=$(( t2 - t1 )) di=$(( i2 - i1 ))
  (( dt <= 0 )) && { echo 0; return 0; }
  local used=$(( dt - di ))
  (( used < 0 )) && used=0
  LC_ALL=C awk -v u="${used}" -v t="${dt}" 'BEGIN { printf "%.0f", (u / t) * 100 }'
}

# cpu_pct_from_top TEXT -> integer load percent from a macOS `top` CPU usage line.
cpu_round_celsius() {
  local pattern='^[^0-9]*([0-9]+)(\.([0-9]))?' whole tenth
  [[ "${1}" =~ ${pattern} ]] || return 0
  whole=$((10#${BASH_REMATCH[1]}))
  tenth="${BASH_REMATCH[3]:-0}"
  ((whole > 0 || tenth > 0)) || return 0
  ((tenth >= 5)) && whole=$((whole + 1))
  printf '%s\n' "${whole}"
}

cpu_temp_from_macmon() {
  local pattern='"cpu_temp_avg":([0-9.]+)'
  [[ "${1}" =~ ${pattern} ]] || return 0
  cpu_round_celsius "${BASH_REMATCH[1]}"
}

cpu_pct_from_iostat() {
  local idle
  idle=$(printf '%s\n' "${1}" | LC_ALL=C awk 'NF >= 3 && $3 ~ /^[0-9]+$/ { i = $3 } END { print i }')
  [[ "${idle}" =~ ^[0-9]+$ ]] || { echo 0; return 0; }
  echo $(( 100 - idle ))
}

cpu_pct_from_top() {
  local idle
  idle=$(printf '%s\n' "${1}" | grep -i "CPU usage" | tail -1 \
    | sed -E 's/.*[, ]([0-9.]+)%[[:space:]]*idle.*/\1/')
  [[ "${idle}" =~ ^[0-9.]+$ ]] || { echo 0; return 0; }
  LC_ALL=C awk -v i="${idle}" 'BEGIN { printf "%.0f", 100 - i }'
}

# cpu_temp_from_sensors TEXT -> integer Celsius from `sensors` output.
cpu_temp_from_sensors() {
  printf '%s\n' "${1}" \
    | grep -m1 -E 'Tctl|Tdie|Package id 0|Core 0|CPU Temperature|k10temp' \
    | grep -oE '\+[0-9]+' | head -1 | tr -d '+'
}

# cpu_temp_from_thermal MILLIDEG -> integer Celsius from a thermal-zone reading.
cpu_temp_from_thermal() {
  [[ "${1}" =~ ^[0-9]+$ ]] || { echo ""; return 0; }
  echo $(( ${1} / 1000 ))
}

# cpu_temp_from_istats TEXT -> integer Celsius from `istats cpu temp`, empty at 0.
cpu_temp_from_istats() {
  local t
  t=$(printf '%s\n' "${1}" | grep -oE '[0-9]+\.[0-9]+' | head -1)
  [[ -z "${t}" ]] && t=$(printf '%s\n' "${1}" | grep -oE '[0-9]+' | head -1)
  [[ "${t}" =~ ^[0-9]+\.?[0-9]*$ ]] || { echo ""; return 0; }
  local i
  i=$(LC_ALL=C awk -v v="${t}" 'BEGIN { printf "%.0f", v }')
  (( i > 0 )) && echo "${i}"
}

# cpu_freq_apple BRAND_STRING -> max CPU clock MHz for an Apple Silicon chip.
cpu_freq_apple() {
  local gen
  gen=$(printf '%s' "${1}" | grep -oE 'M[1-5]' | grep -oE '[1-5]' | head -1)
  [[ "${gen}" =~ ^[1-5]$ ]] || { echo "0"; return 0; }
  local t=(0 3200 3400 4000 4200 4500)
  echo "${t[gen]}"
}

# cpu_freq_from_cpuinfo TEXT -> integer MHz from a "cpu MHz" /proc/cpuinfo line.
cpu_freq_from_cpuinfo() {
  printf '%s\n' "${1}" | awk '{print int($NF)}'
}

# Host-probe seams. Tests override these to inject fixtures.
_read_proc_cpu_line() { grep -m1 '^cpu ' /proc/stat 2>/dev/null; }
_read_sensors() { sensors 2>/dev/null; }
_read_top() { top -l2 -n0 2>/dev/null; }
_read_iostat() { iostat -c 2 -w 1 -n 0 2>/dev/null; }
_read_osx_temp() { osx-cpu-temp 2>/dev/null; }
_read_macmon() { macmon pipe -s 1 -i 200 2>/dev/null; }
_read_istats_cpu() { istats cpu temp 2>/dev/null; }
_read_brand_string() { sysctl -n machdep.cpu.brand_string 2>/dev/null; }
_read_sysctl_cpufreq() { sysctl -n hw.cpufrequency 2>/dev/null; }
_read_proc_cpuinfo_mhz() { grep -m1 'cpu MHz' /proc/cpuinfo 2>/dev/null; }
_read_scaling_cur_freq() { cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null; }
_read_sysctl_loadavg() { sysctl -n vm.loadavg 2>/dev/null; }
_read_proc_loadavg() { cat /proc/loadavg 2>/dev/null; }
_read_sysctl_ncpu() { sysctl -n hw.ncpu 2>/dev/null; }
_read_proc_nproc() { grep -c '^processor' /proc/cpuinfo 2>/dev/null; }

# _read_cpu_thermal [GLOB] -> highest cpu-zone temperature in Celsius, empty when
# none. The GLOB argument exists so tests can point it at a fixture directory.
# shellcheck disable=SC2120
_read_cpu_thermal() {
  local glob="${1:-/sys/class/thermal/thermal_zone*/temp}"
  local max="" z type val
  for z in ${glob}; do
    [[ -r "${z}" ]] || continue
    type=$(cat "${z%temp}type" 2>/dev/null)
    case "${type}" in *cpu*|*x86*|*acpitz*) ;; *) continue ;; esac
    val=$(awk '{print int($1/1000)}' "${z}" 2>/dev/null)
    [[ "${val}" =~ ^[0-9]+$ ]] || continue
    { [[ -z "${max}" ]] || (( val > max )); } && max="${val}"
  done
  echo "${max}"
}

# _read_coretemp [GLOB] -> highest coretemp hwmon temperature in Celsius.
# shellcheck disable=SC2120
_read_coretemp() {
  local glob="${1:-/sys/devices/platform/coretemp.0/hwmon/hwmon*/temp*_input}"
  local max="" h val
  for h in ${glob}; do
    [[ -r "${h}" ]] || continue
    val=$(awk '{print int($1/1000)}' "${h}" 2>/dev/null)
    [[ "${val}" =~ ^[0-9]+$ ]] || continue
    { [[ -z "${max}" ]] || (( val > max )); } && max="${val}"
  done
  echo "${max}"
}

# _read_k10temp [GLOB] -> AMD Ryzen k10temp CPU temperature in Celsius read
# directly from hwmon, preferring the Tctl/Tdie die sensor over board sensors.
# Closes the Ryzen gap left when lm-sensors is not installed.
# shellcheck disable=SC2120
_read_k10temp() {
  local glob="${1:-/sys/class/hwmon/hwmon*}"
  local h name inp label val tctl="" best=""
  for h in ${glob}; do
    [[ -r "${h}/name" ]] || continue
    name=$(cat "${h}/name" 2>/dev/null)
    [[ "${name}" == "k10temp" ]] || continue
    for inp in "${h}"/temp*_input; do
      [[ -r "${inp}" ]] || continue
      val=$(awk '{print int($1/1000)}' "${inp}" 2>/dev/null)
      [[ "${val}" =~ ^[0-9]+$ ]] || continue
      label=$(cat "${inp%_input}_label" 2>/dev/null)
      case "${label}" in
        Tctl|Tdie)
          if [[ -z "${tctl}" ]] || (( val > tctl )); then tctl="${val}"; fi ;;
        *)
          if [[ -z "${best}" ]] || (( val > best )); then best="${val}"; fi ;;
      esac
    done
  done
  [[ -n "${tctl}" ]] && { echo "${tctl}"; return 0; }
  echo "${best}"
}

# _sample_proc_cpu -> load percent from two spaced /proc/stat reads.
_sample_proc_cpu() {
  local l1 l2
  l1=$(_read_proc_cpu_line)
  sleep "${CPU_SAMPLE_INTERVAL}"
  l2=$(_read_proc_cpu_line)
  cpu_pct_from_stat "${l1}" "${l2}"
}

# read_cpu_percentage -> sample CPU load. Slow path, worker only.
read_cpu_percentage() {
  if is_linux; then
    _sample_proc_cpu
  elif is_macos && has_command iostat; then
    cpu_pct_from_iostat "$(_read_iostat)"
  elif is_macos && has_command top; then
    cpu_pct_from_top "$(_read_top)"
  else
    echo 0
  fi
}

# read_cpu_temp -> CPU temperature in Celsius, empty when no sensor is available.
read_cpu_temp() {
  if is_linux; then
    local t
    t=$(_read_cpu_thermal); [[ -n "${t}" ]] && { echo "${t}"; return 0; }
    t=$(_read_coretemp); [[ -n "${t}" ]] && { echo "${t}"; return 0; }
    t=$(_read_k10temp); [[ -n "${t}" ]] && { echo "${t}"; return 0; }
    has_command sensors && cpu_temp_from_sensors "$(_read_sensors)"
  elif is_macos; then
    local t=""
    if is_apple_silicon && has_command macmon; then
      t=$(cpu_temp_from_macmon "$(_read_macmon)")
    fi
    if [[ -z "${t}" ]] && has_command osx-cpu-temp; then
      # osx-cpu-temp reads Intel SMC keys and returns 0.0 on Apple Silicon.
      t=$(cpu_round_celsius "$(_read_osx_temp)")
    fi
    if [[ -z "${t}" ]] && has_command istats; then
      t=$(cpu_temp_from_istats "$(_read_istats_cpu)")
    fi
    [[ -n "${t}" ]] && echo "${t}"
  fi
}

# read_cpu_freq -> CPU clock in MHz, empty or 0 when unavailable.
read_cpu_freq() {
  if is_apple_silicon; then
    cpu_freq_apple "$(_read_brand_string)"
  elif is_macos; then
    local f
    f=$(_read_sysctl_cpufreq)
    [[ "${f}" =~ ^[0-9]+$ ]] && (( f > 0 )) && echo $(( f / 1000000 ))
  elif is_linux; then
    local line
    line=$(_read_proc_cpuinfo_mhz)
    if [[ -n "${line}" ]]; then
      cpu_freq_from_cpuinfo "${line}"
    else
      local s
      s=$(_read_scaling_cur_freq)
      [[ "${s}" =~ ^[0-9]+$ ]] && echo $(( s / 1000 ))
    fi
  fi
}

# read_load_average -> the 1-minute load average.
read_load_average() {
  if is_macos; then
    _read_sysctl_loadavg | awk '{print $2}'
  elif is_linux; then
    _read_proc_loadavg | awk '{print $1}'
  fi
}

# read_cpu_count -> number of logical CPUs.
read_cpu_count() {
  if is_macos; then
    _read_sysctl_ncpu
  elif is_linux; then
    _read_proc_nproc
  else
    echo "1"
  fi
}

# Host-probe seams for the added metrics.
_read_ps_cpu() { LC_ALL=C ps -Ao pcpu,comm 2>/dev/null; }
_read_scaling_governor() { cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null; }

# cpu_top_from_ps TEXT -> "<name> <pct>%" for the highest %CPU process, empty when
# the input has no data rows. Pure: parses the text a seam supplies.
cpu_top_from_ps() {
  printf '%s\n' "${1}" | LC_ALL=C awk 'NR > 1 && $1 + 0 > m { m = $1; c = $2 } END { if (c != "") { sub(/.*\//, "", c); printf "%s %d%%", c, m + 0 } }'
}

# read_cpu_top_process -> the busiest process by CPU. Slow path, worker only.
read_cpu_top_process() {
  cpu_top_from_ps "$(_read_ps_cpu)"
}

# read_cpu_governor -> the Linux CPU frequency governor, empty elsewhere.
read_cpu_governor() {
  if is_linux; then
    _read_scaling_governor
  fi
}

# read_load_average5 -> the 5-minute load average.
read_load_average5() {
  if is_macos; then
    _read_sysctl_loadavg | awk '{print $3}'
  elif is_linux; then
    _read_proc_loadavg | awk '{print $2}'
  fi
}

# read_load_average15 -> the 15-minute load average.
read_load_average15() {
  if is_macos; then
    _read_sysctl_loadavg | awk '{print $4}'
  elif is_linux; then
    _read_proc_loadavg | awk '{print $3}'
  fi
}

export -f _cpu_stat_total_idle
export -f cpu_pct_from_stat
export -f cpu_pct_from_top
export -f cpu_pct_from_iostat
export -f cpu_temp_from_macmon
export -f cpu_round_celsius
export -f cpu_temp_from_sensors
export -f cpu_temp_from_thermal
export -f cpu_temp_from_istats
export -f cpu_freq_apple
export -f cpu_freq_from_cpuinfo
export -f _read_proc_cpu_line
export -f _read_sensors
export -f _read_top
export -f _read_iostat
export -f _read_macmon
export -f _read_osx_temp
export -f _read_istats_cpu
export -f _read_brand_string
export -f _read_sysctl_cpufreq
export -f _read_proc_cpuinfo_mhz
export -f _read_scaling_cur_freq
export -f _read_sysctl_loadavg
export -f _read_proc_loadavg
export -f _read_sysctl_ncpu
export -f _read_proc_nproc
export -f _read_cpu_thermal
export -f _read_coretemp
export -f _read_k10temp
export -f _sample_proc_cpu
export -f read_cpu_percentage
export -f read_cpu_temp
export -f read_cpu_freq
export -f read_load_average
export -f read_cpu_count
export -f _read_ps_cpu
export -f _read_scaling_governor
export -f cpu_top_from_ps
export -f read_cpu_top_process
export -f read_cpu_governor
export -f read_load_average5
export -f read_load_average15
