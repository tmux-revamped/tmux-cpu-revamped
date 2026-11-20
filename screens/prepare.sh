#!/bin/sh
set -eu

: "${SCREENS_REPO:?}"
demo=/Users/Shared/demo
rm -rf "${demo}"
mkdir -p "${demo}/home" "${demo}/bin" "${demo}/tmux-cpu-revamped"
cp -Rpf "${SCREENS_REPO}/bin" "${SCREENS_REPO}/lib" "${SCREENS_REPO}/cpu-revamped.tmux" "${demo}/tmux-cpu-revamped/"
for tool in tmux gum; do
  tool_path=$(command -v "${tool}")
  ln -s "${tool_path}" "${demo}/bin/${tool}"
done

cat >"${demo}/bin/iostat" <<'IOSTAT'
#!/bin/sh
phase=$(cat /Users/Shared/demo/phase 2>/dev/null) || phase=$((($(date +%s) / 5) % 4))
case "${phase}" in
0) idle=82 ;;
1) idle=58 ;;
2) idle=34 ;;
*) idle=12 ;;
esac
printf '          cpu    load average\n'
printf '    us sy id   1m   5m   15m\n'
printf '    10  5 85  1.10 1.40  1.55\n'
printf '    %s %s %s  1.10 1.40  1.55\n' "$(((100 - idle) * 2 / 3))" "$(((100 - idle) / 3))" "${idle}"
IOSTAT

cat >"${demo}/bin/sysctl" <<'SYSCTL'
#!/bin/sh
case "$*" in
"-n vm.loadavg")
  phase=$(cat /Users/Shared/demo/phase 2>/dev/null) || phase=$((($(date +%s) / 5) % 4))
  case "${phase}" in
  0) printf '{ 1.10 1.40 1.55 }\n' ;;
  1) printf '{ 3.60 2.80 2.10 }\n' ;;
  2) printf '{ 7.20 5.10 3.40 }\n' ;;
  *) printf '{ 12.80 9.20 6.10 }\n' ;;
  esac
  ;;
"-n hw.ncpu") printf '10\n' ;;
"-n machdep.cpu.brand_string") printf 'Apple M2 Pro\n' ;;
"-n hw.cpufrequency") printf '3490000000\n' ;;
*) exit 1 ;;
esac
SYSCTL

cat >"${demo}/bin/macmon" <<'MACMON'
#!/bin/sh
phase=$(cat /Users/Shared/demo/phase 2>/dev/null) || phase=$((($(date +%s) / 5) % 4))
case "${phase}" in
0) degrees=47.4 ;;
1) degrees=58.2 ;;
2) degrees=70.6 ;;
*) degrees=84.3 ;;
esac
printf '{"cpu_temp_avg":%s,"gpu_temp_avg":40.0}\n' "${degrees}"
MACMON

cat >"${demo}/bin/osx-cpu-temp" <<'OSXTEMP'
#!/bin/sh
phase=$(cat /Users/Shared/demo/phase 2>/dev/null) || phase=$((($(date +%s) / 5) % 4))
case "${phase}" in
0) degrees=47.4 ;;
1) degrees=58.2 ;;
2) degrees=70.6 ;;
*) degrees=84.3 ;;
esac
printf '%s°C\n' "${degrees}"
OSXTEMP

cat >"${demo}/bin/ps" <<'PROCESSES'
#!/bin/sh
printf '  3.1 tmux\n 71.4 /usr/local/bin/node\n 12.2 postgres\n'
PROCESSES

cat >"${demo}/bin/top" <<'MONITOR'
#!/bin/sh
while :; do
  printf '\033[H\033[2J'
  printf 'Processes: 412 total, 4 running, 408 sleeping\n'
  printf 'CPU usage: 41.2%% user, 12.8%% sys, 46.0%% idle\n\n'
  printf '  PID COMMAND      %%CPU  MEM\n'
  printf '  812 node         71.4  1.2G\n'
  printf '  431 postgres     12.2  480M\n'
  printf '  118 tmux          3.1   18M\n'
  sleep 1
done
MONITOR

cat >"${demo}/bin/osascript" <<'CORES'
#!/bin/sh
case "$*" in
"-l JavaScript -e "*) ;;
*) exit 0 ;;
esac
awk -v now="$(date +%s)" 'BEGIN {
  count = split("12 38 71 94 5 55 82 27 63 46", share, " ")
  for (i = 1; i <= count; i++) { printf "cpu%d %d 0 0 %d\n", i - 1, now * share[i], now * (100 - share[i]) }
}'
CORES

cat >"${demo}/bin/pmset" <<'THERMAL'
#!/bin/sh
printf 'Note: No thermal warning level has been recorded\n'
printf 'Note: No performance warning level has been recorded\n'
printf 'CPU_Scheduler_Limit = 100\n'
if [ "$(cat /Users/Shared/demo/throttle 2>/dev/null)" = 1 ]; then
  printf 'CPU_Speed_Limit = 70\n'
else
  printf 'CPU_Speed_Limit = 100\n'
fi
THERMAL

chmod +x "${demo}/bin/iostat" "${demo}/bin/sysctl" "${demo}/bin/macmon" "${demo}/bin/osx-cpu-temp" "${demo}/bin/ps" "${demo}/bin/top" "${demo}/bin/osascript" "${demo}/bin/pmset"
