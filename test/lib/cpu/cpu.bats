#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _CPU_REVAMPED_CPU_LOADED
  export CPU_SAMPLE_INTERVAL=0
  source "${BATS_TEST_DIRNAME}/../../../src/lib/cpu/cpu.sh"
}

teardown() {
  cleanup_test_environment
}

@test "cpu.sh - _cpu_stat_total_idle sums total and idle" {
  [[ "$(_cpu_stat_total_idle "cpu 100 0 50 800 50 0 0")" == "1000 850" ]]
}

@test "cpu.sh - _cpu_stat_total_idle skips non-numeric fields" {
  [[ "$(_cpu_stat_total_idle "cpu 100 x 50 800 50")" == "1000 850" ]]
}

@test "cpu.sh - cpu_pct_from_stat computes the interval load" {
  [[ "$(cpu_pct_from_stat "cpu 0 0 0 100 0" "cpu 0 0 50 150 0")" == "50" ]]
}

@test "cpu.sh - cpu_pct_from_stat returns 0 for a zero interval" {
  [[ "$(cpu_pct_from_stat "cpu 0 0 0 100 0" "cpu 0 0 0 100 0")" == "0" ]]
}

@test "cpu.sh - cpu_pct_from_top derives load from idle" {
  local txt="CPU usage: 5.0% user, 3.0% sys, 92.0% idle"
  [[ "$(cpu_pct_from_top "${txt}")" == "8" ]]
}

@test "cpu.sh - cpu_pct_from_top uses the last usage line" {
  local txt=$'CPU usage: 1.0% user, 1.0% sys, 98.0% idle\nCPU usage: 10.0% user, 10.0% sys, 80.0% idle'
  [[ "$(cpu_pct_from_top "${txt}")" == "20" ]]
}

@test "cpu.sh - cpu_pct_from_top returns 0 on malformed input" {
  [[ "$(cpu_pct_from_top "no usage here")" == "0" ]]
}

@test "cpu.sh - cpu_temp_from_sensors reads a Core temperature" {
  [[ "$(cpu_temp_from_sensors "Core 0:        +45.0°C  (high)")" == "45" ]]
}

@test "cpu.sh - cpu_temp_from_sensors reads a Tctl temperature" {
  [[ "$(cpu_temp_from_sensors "Tctl:          +60.0°C")" == "60" ]]
}

@test "cpu.sh - cpu_temp_from_sensors is empty with no match" {
  [[ -z "$(cpu_temp_from_sensors "fan1: 1200 RPM")" ]]
}

@test "cpu.sh - cpu_temp_from_thermal converts millidegrees" {
  [[ "$(cpu_temp_from_thermal "45000")" == "45" ]]
}

@test "cpu.sh - cpu_temp_from_thermal is empty for junk" {
  [[ -z "$(cpu_temp_from_thermal "abc")" ]]
}

@test "cpu.sh - _sample_proc_cpu spaces two reads" {
  local statef="${TEST_TMPDIR}/cnt"
  echo 0 > "${statef}"
  _read_proc_cpu_line() {
    local n
    n=$(cat "${statef}")
    n=$(( n + 1 ))
    echo "${n}" > "${statef}"
    if [[ "${n}" -eq 1 ]]; then echo "cpu 0 0 0 100 0"; else echo "cpu 0 0 50 150 0"; fi
  }
  sleep() { :; }
  [[ "$(_sample_proc_cpu)" == "50" ]]
}

@test "cpu.sh - read_cpu_percentage uses the Linux sampler" {
  _PLATFORM_OS_CACHE="Linux"
  _sample_proc_cpu() { echo "33"; }
  [[ "$(read_cpu_percentage)" == "33" ]]
}

@test "cpu.sh - read_cpu_percentage prefers iostat on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  has_command() { return 0; }
  _read_iostat() { printf '            cpu    load average\n us sy id   1m   5m   15m\n 10  5 85  2.1  2.0  1.9\n 30 12 58  2.1  2.0  1.9\n'; }

  run read_cpu_percentage

  [[ "${output}" == "42" ]]
}

@test "cpu.sh - cpu_pct_from_iostat is 0 for unreadable output" {
  run cpu_pct_from_iostat "no samples"

  [[ "${output}" == "0" ]]
}

@test "cpu.sh - read_cpu_percentage uses top on macOS without iostat" {
  _PLATFORM_OS_CACHE="Darwin"
  has_command() { [[ "${1}" == "top" ]]; }
  _read_top() { echo "CPU usage: 1.0% user, 9.0% sys, 90.0% idle"; }
  [[ "$(read_cpu_percentage)" == "10" ]]
}

@test "cpu.sh - read_cpu_percentage is 0 on macOS without top" {
  _PLATFORM_OS_CACHE="Darwin"
  has_command() { return 1; }
  [[ "$(read_cpu_percentage)" == "0" ]]
}

@test "cpu.sh - read_cpu_percentage is 0 on an unknown platform" {
  _PLATFORM_OS_CACHE="Plan9"
  [[ "$(read_cpu_percentage)" == "0" ]]
}

@test "cpu.sh - cpu_temp_from_sensors reads more sensor labels" {
  [[ "$(cpu_temp_from_sensors 'Tdie: +52.0°C')" == "52" ]]
  [[ "$(cpu_temp_from_sensors 'CPU Temperature: +47.0°C')" == "47" ]]
}

@test "cpu.sh - cpu_temp_from_istats rounds and drops zero" {
  [[ "$(cpu_temp_from_istats 'CPU temp: 45.2 C')" == "45" ]]
  [[ -z "$(cpu_temp_from_istats 'CPU temp: 0.0 C')" ]]
}

@test "cpu.sh - cpu_freq_apple looks up the chip clock" {
  [[ "$(cpu_freq_apple 'Apple M3 Max')" == "4000" ]]
  [[ "$(cpu_freq_apple 'Apple M1')" == "3200" ]]
  [[ "$(cpu_freq_apple 'Intel')" == "0" ]]
}

@test "cpu.sh - cpu_freq_from_cpuinfo parses the MHz field" {
  [[ "$(cpu_freq_from_cpuinfo 'cpu MHz : 2400.000')" == "2400" ]]
}

@test "cpu.sh - _read_cpu_thermal reads a typed zone fixture" {
  mkdir -p "${TEST_TMPDIR}/tz0"
  echo 60000 > "${TEST_TMPDIR}/tz0/temp"
  echo "x86_pkg_temp" > "${TEST_TMPDIR}/tz0/type"
  [[ "$(_read_cpu_thermal "${TEST_TMPDIR}/tz*/temp")" == "60" ]]
}

@test "cpu.sh - _read_cpu_thermal skips non-cpu zones" {
  mkdir -p "${TEST_TMPDIR}/tz0"
  echo 40000 > "${TEST_TMPDIR}/tz0/temp"
  echo "battery" > "${TEST_TMPDIR}/tz0/type"
  [[ -z "$(_read_cpu_thermal "${TEST_TMPDIR}/tz*/temp")" ]]
}

@test "cpu.sh - _read_coretemp reads a hwmon fixture" {
  mkdir -p "${TEST_TMPDIR}/hw"
  echo 58000 > "${TEST_TMPDIR}/hw/temp1_input"
  [[ "$(_read_coretemp "${TEST_TMPDIR}/hw/temp*_input")" == "58" ]]
}

@test "cpu.sh - _read_k10temp prefers the Tctl die sensor" {
  mkdir -p "${TEST_TMPDIR}/hwmon0"
  echo "k10temp" > "${TEST_TMPDIR}/hwmon0/name"
  echo 42000 > "${TEST_TMPDIR}/hwmon0/temp1_input"
  echo "Tctl" > "${TEST_TMPDIR}/hwmon0/temp1_label"
  echo 38000 > "${TEST_TMPDIR}/hwmon0/temp3_input"
  echo "Tccd1" > "${TEST_TMPDIR}/hwmon0/temp3_label"
  [[ "$(_read_k10temp "${TEST_TMPDIR}/hwmon*")" == "42" ]]
}

@test "cpu.sh - _read_k10temp falls back to the hottest labelled sensor" {
  mkdir -p "${TEST_TMPDIR}/hwmon0"
  echo "k10temp" > "${TEST_TMPDIR}/hwmon0/name"
  echo 49000 > "${TEST_TMPDIR}/hwmon0/temp2_input"
  echo "Tccd1" > "${TEST_TMPDIR}/hwmon0/temp2_label"
  [[ "$(_read_k10temp "${TEST_TMPDIR}/hwmon*")" == "49" ]]
}

@test "cpu.sh - _read_k10temp ignores non-k10temp hwmon" {
  mkdir -p "${TEST_TMPDIR}/hwmon0"
  echo "nvme" > "${TEST_TMPDIR}/hwmon0/name"
  echo 55000 > "${TEST_TMPDIR}/hwmon0/temp1_input"
  [[ -z "$(_read_k10temp "${TEST_TMPDIR}/hwmon*")" ]]
}

@test "cpu.sh - read_cpu_temp reads a thermal zone on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  _read_cpu_thermal() { echo "60"; }
  [[ "$(read_cpu_temp)" == "60" ]]
}

@test "cpu.sh - read_cpu_temp falls back to coretemp" {
  _PLATFORM_OS_CACHE="Linux"
  _read_cpu_thermal() { echo ""; }
  _read_coretemp() { echo "58"; }
  [[ "$(read_cpu_temp)" == "58" ]]
}

@test "cpu.sh - read_cpu_temp falls back to k10temp on Ryzen" {
  _PLATFORM_OS_CACHE="Linux"
  _read_cpu_thermal() { echo ""; }
  _read_coretemp() { echo ""; }
  _read_k10temp() { echo "61"; }
  [[ "$(read_cpu_temp)" == "61" ]]
}

@test "cpu.sh - read_cpu_temp falls back to sensors" {
  _PLATFORM_OS_CACHE="Linux"
  _read_cpu_thermal() { echo ""; }
  _read_coretemp() { echo ""; }
  _read_k10temp() { echo ""; }
  has_command() { [[ "$1" == "sensors" ]]; }
  _read_sensors() { echo "Core 0: +50.0°C"; }
  [[ "$(read_cpu_temp)" == "50" ]]
}

@test "cpu.sh - read_cpu_temp is empty when Linux has no source" {
  _PLATFORM_OS_CACHE="Linux"
  _read_cpu_thermal() { echo ""; }
  _read_coretemp() { echo ""; }
  _read_k10temp() { echo ""; }
  has_command() { return 1; }
  [[ -z "$(read_cpu_temp)" ]]
}

@test "cpu.sh - read_cpu_temp reads osx-cpu-temp on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  has_command() { [[ "$1" == "osx-cpu-temp" ]]; }
  _read_osx_temp() { echo "CPU: 61.2 °C"; }
  [[ "$(read_cpu_temp)" == "61.2" ]]
}

@test "cpu.sh - read_cpu_temp falls back to istats on Apple Silicon" {
  _PLATFORM_OS_CACHE="Darwin"
  has_command() { [[ "$1" == "osx-cpu-temp" || "$1" == "istats" ]]; }
  _read_osx_temp() { echo "0.0°C"; }
  _read_istats_cpu() { echo "CPU temp: 48.0 C"; }
  [[ "$(read_cpu_temp)" == "48" ]]
}

@test "cpu.sh - read_cpu_temp is empty on macOS without a tool" {
  _PLATFORM_OS_CACHE="Darwin"
  has_command() { return 1; }
  [[ -z "$(read_cpu_temp)" ]]
}

@test "cpu.sh - read_cpu_freq uses the Apple Silicon table" {
  _PLATFORM_OS_CACHE="Darwin"
  _PLATFORM_ARCH_CACHE="arm64"
  _read_brand_string() { echo "Apple M3 Max"; }
  [[ "$(read_cpu_freq)" == "4000" ]]
}

@test "cpu.sh - read_cpu_freq reads sysctl on Intel macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  _PLATFORM_ARCH_CACHE="x86_64"
  _read_sysctl_cpufreq() { echo "2400000000"; }
  [[ "$(read_cpu_freq)" == "2400" ]]
}

@test "cpu.sh - read_cpu_freq reads cpuinfo on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  _read_proc_cpuinfo_mhz() { echo "cpu MHz : 3200.000"; }
  [[ "$(read_cpu_freq)" == "3200" ]]
}

@test "cpu.sh - read_cpu_freq falls back to scaling freq on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  _read_proc_cpuinfo_mhz() { echo ""; }
  _read_scaling_cur_freq() { echo "2800000"; }
  [[ "$(read_cpu_freq)" == "2800" ]]
}

@test "cpu.sh - read_load_average reads sysctl on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  _read_sysctl_loadavg() { echo "{ 1.23 2.34 3.45 }"; }
  [[ "$(read_load_average)" == "1.23" ]]
}

@test "cpu.sh - read_load_average reads /proc on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  _read_proc_loadavg() { echo "0.75 0.50 0.30 1/200 1234"; }
  [[ "$(read_load_average)" == "0.75" ]]
}

@test "cpu.sh - read_cpu_count reads sysctl on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  _read_sysctl_ncpu() { echo "12"; }
  [[ "$(read_cpu_count)" == "12" ]]
}

@test "cpu.sh - read_cpu_count reads /proc on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  _read_proc_nproc() { echo "8"; }
  [[ "$(read_cpu_count)" == "8" ]]
}

@test "cpu.sh - read_cpu_count is 1 on an unknown platform" {
  _PLATFORM_OS_CACHE="Plan9"
  [[ "$(read_cpu_count)" == "1" ]]
}

@test "cpu.sh - host-probe seams are callable" {
  sensors() { :; }
  top() { :; }
  osx-cpu-temp() { :; }
  istats() { :; }
  run _read_sensors
  run _read_top
  run _read_osx_temp
  run _read_istats_cpu
  run _read_brand_string
  run _read_sysctl_cpufreq
  run _read_proc_cpuinfo_mhz
  run _read_scaling_cur_freq
  run _read_sysctl_loadavg
  run _read_proc_loadavg
  run _read_sysctl_ncpu
  run _read_proc_nproc
  run _read_cpu_thermal
  run _read_coretemp
  true
}

@test "cpu.sh - cpu_top_from_ps picks the busiest process" {
  local txt=$'%CPU COMMAND\n 5.0 bash\n12.3 /usr/bin/foo\n 2.0 zsh'
  [[ "$(cpu_top_from_ps "${txt}")" == "foo 12%" ]]
}

@test "cpu.sh - cpu_top_from_ps basenames the command" {
  local txt=$'%CPU COMMAND\n80.0 /opt/app/server'
  [[ "$(cpu_top_from_ps "${txt}")" == "server 80%" ]]
}

@test "cpu.sh - cpu_top_from_ps is empty with only a header" {
  [[ -z "$(cpu_top_from_ps '%CPU COMMAND')" ]]
}

@test "cpu.sh - read_cpu_top_process reads the ps seam" {
  _read_ps_cpu() { printf '%s\n' $'%CPU COMMAND\n42.0 node'; }
  [[ "$(read_cpu_top_process)" == "node 42%" ]]
}

@test "cpu.sh - read_cpu_governor reads scaling_governor on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  _read_scaling_governor() { echo "performance"; }
  [[ "$(read_cpu_governor)" == "performance" ]]
}

@test "cpu.sh - read_cpu_governor is empty on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  [[ -z "$(read_cpu_governor)" ]]
}

@test "cpu.sh - read_load_average5 reads sysctl on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  _read_sysctl_loadavg() { echo "{ 1.23 2.34 3.45 }"; }
  [[ "$(read_load_average5)" == "2.34" ]]
}

@test "cpu.sh - read_load_average5 reads /proc on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  _read_proc_loadavg() { echo "0.75 0.50 0.30 1/200 1234"; }
  [[ "$(read_load_average5)" == "0.50" ]]
}

@test "cpu.sh - read_load_average5 is empty on an unknown platform" {
  _PLATFORM_OS_CACHE="Plan9"
  [[ -z "$(read_load_average5)" ]]
}

@test "cpu.sh - read_load_average15 reads sysctl on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  _read_sysctl_loadavg() { echo "{ 1.23 2.34 3.45 }"; }
  [[ "$(read_load_average15)" == "3.45" ]]
}

@test "cpu.sh - read_load_average15 reads /proc on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  _read_proc_loadavg() { echo "0.75 0.50 0.30 1/200 1234"; }
  [[ "$(read_load_average15)" == "0.30" ]]
}

@test "cpu.sh - read_load_average15 is empty on an unknown platform" {
  _PLATFORM_OS_CACHE="Plan9"
  [[ -z "$(read_load_average15)" ]]
}

@test "cpu.sh - added host-probe seams are callable" {
  run _read_ps_cpu
  run _read_scaling_governor
  true
}

@test "cpu - a comma-decimal locale still formats with a dot" {
  locale -a 2>/dev/null | grep -qiE '^pt_BR\.utf-?8$' || skip "the pt_BR.UTF-8 locale is not installed"
  LC_ALL=pt_BR.UTF-8 LC_NUMERIC=pt_BR.UTF-8 run cpu_temp_from_istats 'CPU temp: 45.6°C'

  [[ "${output}" == "46" ]]
}

@test "cpu - the busiest process is picked by its decimals under a comma-decimal locale" {
  locale -a 2>/dev/null | grep -qiE '^pt_BR\.utf-?8$' || skip "the pt_BR.UTF-8 locale is not installed"
  local txt
  txt=$'%CPU COMM\n12.3 /bin/first\n12.7 /bin/second'

  LC_ALL=pt_BR.UTF-8 LC_NUMERIC=pt_BR.UTF-8 run cpu_top_from_ps "${txt}"

  [[ "${output}" == "second 12%" ]]
}
