#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  for name in $(compgen -v CPU_REVAMPED_); do
    unset "${name}"
  done
  FAKE="${BATS_TEST_TMPDIR}/fake"
  SYS="${BATS_TEST_TMPDIR}/sys"
  export HOME="${BATS_TEST_TMPDIR}/home" FAKE SYS
  mkdir -p "${HOME}" "${FAKE}" "${SYS}" "${BATS_TEST_TMPDIR}/stubs"
  UNTRACED='{ set +x; } 2>/dev/null'
  printf '3.6\n' >"${FAKE}/version"
  : >"${FAKE}/vars"
  : >"${FAKE}/log"
  : >"${FAKE}/asked"
  : >"${FAKE}/slept"
  now 1000000
  fake_tmux
  fake_date
  fake_sleep
  linux
  harness_hide vm_stat sysctl ps iostat top btop htop sensors macmon osx-cpu-temp istats
}

quiet() {
  printf '#!/bin/sh\n%s\n%s\n' "${UNTRACED}" "$2" >"${BATS_TEST_TMPDIR}/stubs/$1"
  chmod +x "${BATS_TEST_TMPDIR}/stubs/$1"
}

var() {
  local kept
  kept=$(grep -v "^$1	" "${FAKE}/vars" || :)
  printf '%s\n%s\t%s\n' "${kept}" "$1" "$2" | grep -v '^$' >"${FAKE}/vars.tmp"
  mv -f "${FAKE}/vars.tmp" "${FAKE}/vars"
}

value() {
  awk -F '\t' -v want="$1" '$1 == want { print $2 }' "${FAKE}/vars"
}

option() {
  var "@cpu_revamped_$1" "$2"
}

held() {
  value "@cpu_revamped_$1"
}

now() {
  printf '%s\n' "$1" >"${FAKE}/now"
}

later() {
  local current
  current=$(cat "${FAKE}/now")
  now $((current + ${1:-100}))
}

unstub() {
  rm -f "${BATS_TEST_TMPDIR}/stubs/$1"
}

fake_date() {
  quiet date 'cat "'"${FAKE}"'/now"'
}

fake_sleep() {
  quiet sleep 'printf "%s\n" "$*" >>"'"${FAKE}"'/slept"'
}

macos() {
  export REVAMPED_TEST_UNAME_S=Darwin
}

apple_silicon() {
  export REVAMPED_TEST_UNAME_S=Darwin REVAMPED_TEST_UNAME_M=arm64
}

intel_mac() {
  export REVAMPED_TEST_UNAME_S=Darwin REVAMPED_TEST_UNAME_M=x86_64
}

linux() {
  export REVAMPED_TEST_UNAME_S=Linux
}

says() {
  printf '%s\n' "$2" >"${FAKE}/$1.out"
  quiet "$1" 'printf "%s %s\n" "'"$1"'" "$*" >>"'"${FAKE}"'/asked"; cat "'"${FAKE}/$1"'.out"'
}

sysctl_set() {
  printf '%s\n' "$2" >"${FAKE}/sysctl.$1"
  quiet sysctl 'printf "sysctl %s\n" "$*" >>"'"${FAKE}"'/asked"
case "$*" in
"-n vm.loadavg") name=loadavg ;;
"-n hw.ncpu") name=ncpu ;;
"-n machdep.cpu.brand_string") name=brand ;;
"-n hw.cpufrequency") name=cpufreq ;;
*) exit 1 ;;
esac
[ -f "'"${FAKE}"'/sysctl.${name}" ] || exit 1
exec "'"${BATS_TEST_TMPDIR}"'/farm/cat" "'"${FAKE}"'/sysctl.${name}"'
}

mac_host() {
  sysctl_set loadavg "{ 1.52 1.60 1.70 }"
  sysctl_set ncpu 12
  macos
}

iostat_says() {
  says iostat "${1:-          cpu    load average
    us sy id   1m   5m   15m
    10  5 85  1.52 1.60  1.70
    20 10 70  1.52 1.60  1.70}"
}

top_says() {
  says top "${1:-Processes: 400 total
CPU usage: 12.5% user, 7.5% sys, 80.0% idle
CPU usage: 25.0% user, 15.0% sys, 60.0% idle}"
}

proc_file() {
  printf '%s\n' "$2" >"${FAKE}/proc.$1"
  quiet cat 'case "$1" in
/proc/stat) name=stat ;;
/proc/cpuinfo) name=cpuinfo ;;
/proc/loadavg) name=loadavg ;;
*/cpufreq/scaling_cur_freq) name=scaling ;;
*/cpufreq/scaling_governor) name=governor ;;
*) exec "'"${BATS_TEST_TMPDIR}"'/farm/cat" "$@" ;;
esac
printf "cat %s\n" "$1" >>"'"${FAKE}"'/asked"
if [ "${name}" = stat ] && [ -f "'"${FAKE}"'/proc.stat.1" ]; then
  count=0
  [ ! -f "'"${FAKE}"'/stat.count" ] || read -r count <"'"${FAKE}"'/stat.count"
  count=$((count + 1))
  printf "%s\n" "${count}" >"'"${FAKE}"'/stat.count"
  [ "${count}" -lt 2 ] || rm -f "'"${FAKE}"'/stat.count"
  exec "'"${BATS_TEST_TMPDIR}"'/farm/cat" "'"${FAKE}"'/proc.stat.${count}"
fi
[ -f "'"${FAKE}"'/proc.${name}" ] || exit 1
exec "'"${BATS_TEST_TMPDIR}"'/farm/cat" "'"${FAKE}"'/proc.${name}"'
}

busy() {
  rm -f "${FAKE}/stat.count" "${FAKE}/proc.stat"
  printf '%s\n' "${1:-cpu  1000 0 500 8000 500 0 0 0 0 0}" >"${FAKE}/proc.stat.1"
  printf '%s\n' "${2:-cpu  1300 0 600 8100 500 0 0 0 0 0}" >"${FAKE}/proc.stat.2"
  proc_file stat "x"
}

cpuinfo() {
  proc_file cpuinfo "${1:-processor	: 0
model name	: Test CPU
cpu MHz		: 2194.842

processor	: 1
cpu MHz		: 2200.000

processor	: 2
cpu MHz		: 2300.000

processor	: 3
cpu MHz		: 2400.000}"
}

loadavg() {
  proc_file loadavg "${1:-0.50 1.25 2.00 1/200 12345}"
}

governor() {
  proc_file governor "${1:-powersave}"
}

scaling() {
  proc_file scaling "${1:-3200000}"
}

linux_host() {
  busy
  cpuinfo
  loadavg
  governor
}

processes() {
  says ps "${1:-  0.5 /sbin/launchd
 42.4 /Applications/My App.app/Contents/MacOS/My App
  3.0 tmux}"
}

thermal_zone() {
  mkdir -p "${SYS}/class/thermal/thermal_zone$1"
  printf '%s\n' "$2" >"${SYS}/class/thermal/thermal_zone$1/type"
  printf '%s\n' "$3" >"${SYS}/class/thermal/thermal_zone$1/temp"
}

coretemp_input() {
  mkdir -p "${SYS}/devices/platform/coretemp.0/hwmon/hwmon$1"
  printf '%s\n' "$3" >"${SYS}/devices/platform/coretemp.0/hwmon/hwmon$1/temp$2_input"
}

hwmon_chip() {
  mkdir -p "${SYS}/class/hwmon/hwmon$1"
  printf '%s\n' "$2" >"${SYS}/class/hwmon/hwmon$1/name"
}

hwmon_input() {
  printf '%s\n' "$3" >"${SYS}/class/hwmon/hwmon$1/temp$2_input"
  [[ -z "${4:-}" ]] || printf '%s\n' "$4" >"${SYS}/class/hwmon/hwmon$1/temp$2_label"
}

sampled() {
  option percent "${1:-42}"
  option percent_ts "${2:-1000000}"
}

asked() {
  cat "${FAKE}/asked"
}

fake_tmux() {
  cat >"${BATS_TEST_TMPDIR}/stubs/tmux" <<EOF
#!/bin/sh
${UNTRACED}
printf '%s\n' "\$*" >>"${FAKE}/log"
expanded() {
  printf '%s\n' "\$1" | awk -v vars="${FAKE}/vars" '
    BEGIN { while ((getline row < vars) > 0) { at = index(row, "\t"); value[substr(row, 1, at - 1)] = substr(row, at + 1) } }
    {
      line = \$0
      out = ""
      while ((at = index(line, "#{")) > 0) {
        stop = index(substr(line, at), "}")
        name = substr(line, at + 2, stop - 3)
        out = out substr(line, 1, at - 1) value[name]
        line = substr(line, at + stop)
      }
      print out line
    }
  '
}
looked() {
  awk -F '\t' -v want="\$1" '\$1 == want { print \$2 }' "${FAKE}/vars"
}
put() {
  kept=\$(grep -v "^\$1	" "${FAKE}/vars" || :)
  printf '%s\n%s\t%s\n' "\${kept}" "\$1" "\$2" | grep -v '^\$' >"${FAKE}/vars.tmp"
  mv -f "${FAKE}/vars.tmp" "${FAKE}/vars"
}
written() {
  while [ "\$#" -gt 0 ]; do
    if [ "\$1" = set-option ] && [ "\${2:-}" = -gq ] && [ "\$#" -ge 4 ]; then
      put "\$3" "\$4"
      shift 4
      continue
    fi
    shift
  done
}
case "\$1" in
-V)
  IFS= read -r version <"${FAKE}/version"
  printf 'tmux %s\n' "\${version}"
  ;;
display-message)
  [ "\$2" != -p ] || expanded "\$3"
  ;;
show-option)
  looked "\$3"
  ;;
list-keys)
  [ ! -f "${FAKE}/keys" ] || cat "${FAKE}/keys"
  ;;
list-clients)
  [ ! -f "${FAKE}/clients" ] || cat "${FAKE}/clients"
  ;;
*)
  case "\$*" in
  *" ; "*) [ ! -f "${FAKE}/refused" ] || exit 1 ;;
  *) [ ! -f "${FAKE}/refused" ] || ! grep -qF -- "\$*" "${FAKE}/refused" || exit 1 ;;
  esac
  written "\$@"
  ;;
esac
exit 0
EOF
  chmod +x "${BATS_TEST_TMPDIR}/stubs/tmux"
}

tmux_is() {
  printf '%s\n' "$1" >"${FAKE}/version"
}

planned() {
  lib_run cpu "${1:-}"'cpu_revamped_plan; cpu_revamped_lines'
}

sends() {
  grep -v -e '^display-message -p' -e '^-V' -e '^list-' -e '^show-option' "${FAKE}/log" || :
}

sent() {
  grep -c -- "$1" "${FAKE}/log" || :
}

tool() {
  # shellcheck disable=SC2086
  run ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/cpu-revamped" "$@"
}

tool_path() {
  printf "'%s'" "${REVAMPED_TESTS_DIR}/../bin/cpu-revamped"
}

bin_path() {
  printf "'%s'" "${REVAMPED_TESTS_DIR%/test}/bin/cpu-revamped"
}

has_line() {
  local line
  for line in "${lines[@]}"; do
    [[ "${line}" == "$1" ]] && return 0
  done
  return 1
}

answers() {
  export REVAMPED_TEST_GUM_ANSWERS="${BATS_TEST_TMPDIR}/answers"
  printf '%s\n' "$@" >"${REVAMPED_TEST_GUM_ANSWERS}"
}

eventually() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2; do
    "$@" && return 0
    /bin/sleep "${delay}"
  done
  "$@"
}

holds() {
  local now
  now=$(held "$1")
  [[ "${now}" == "$2" ]]
}
