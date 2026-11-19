#!/bin/sh

[ -n "${CPU_REVAMPED_CPU_LOADED:-}" ] && return 0
CPU_REVAMPED_CPU_LOADED=1

# shellcheck source=SCRIPTDIR/state.sh
. "${REVAMPED_LIB:?}/state.sh"
# shellcheck source=SCRIPTDIR/platform.sh
. "${REVAMPED_LIB}/platform.sh"
# shellcheck source=SCRIPTDIR/command.sh
. "${REVAMPED_LIB}/command.sh"
# shellcheck source=SCRIPTDIR/cache.sh
. "${REVAMPED_LIB}/cache.sh"
# shellcheck source=SCRIPTDIR/publish.sh
. "${REVAMPED_LIB}/publish.sh"
# shellcheck source=SCRIPTDIR/ticker.sh
. "${REVAMPED_LIB}/ticker.sh"

cpu_revamped_format() {
  printf '%s\n' "${CPU_REVAMPED_SETTINGS}" | awk -F '\t' -v live="${CPU_REVAMPED_LIVE}" '{ printf "%s#{@cpu_revamped_%s}", (NR > 1 ? "\t" : ""), $1 } END { count = split(live, name, " "); for (i = 1; i <= count; i++) { printf "\t#{@cpu_revamped_%s}", name[i] } }'
}

cpu_revamped_resolve() {
  env | CPU_REVAMPED_ROWS="${CPU_REVAMPED_SETTINGS}" CPU_REVAMPED_VALUES="$1" awk -v live="${CPU_REVAMPED_LIVE}" '
    BEGIN {
      count = split(ENVIRON["CPU_REVAMPED_ROWS"], rows, "\n")
      split(ENVIRON["CPU_REVAMPED_VALUES"], given, "\t")
      for (i = 1; i <= count; i++) {
        at = index(rows[i], "\t")
        if (at == 0) { at = length(rows[i]) + 1 }
        name[i] = substr(rows[i], 1, at - 1)
        value[i] = (given[i] != "") ? given[i] : substr(rows[i], at + 1)
        want["CPU_REVAMPED_" toupper(name[i])] = i
      }
    }
    {
      at = index($0, "=")
      key = substr($0, 1, at - 1)
      if (key in want) {
        value[want[key]] = substr($0, at + 1)
      }
    }
    END {
      for (i = 1; i <= count; i++) { print name[i] "\t" value[i] }
      extra = split(live, state, " ")
      for (i = 1; i <= extra; i++) { print state[i] "\t" given[count + i] }
    }
  '
}

cpu_revamped_setting_rows() {
  cpu_revamped_setting_rows_format=$(cpu_revamped_format)
  cpu_revamped_setting_rows_live=$(tmux display-message -p "${cpu_revamped_setting_rows_format}" 2>/dev/null) || cpu_revamped_setting_rows_live=""
  cpu_revamped_resolve "${cpu_revamped_setting_rows_live}"
}

cpu_revamped_load() {
  cpu_revamped_load_values=$(cpu_revamped_setting_rows)
  while IFS='	' read -r cpu_revamped_load_name cpu_revamped_load_value; do
    IFS= read -r "CPU_REVAMPED_S_${cpu_revamped_load_name}" <<EOF
${cpu_revamped_load_value}
EOF
  done <<EOF
${cpu_revamped_load_values}
EOF
}

cpu_revamped_parse_version() {
  printf '%s\n' "$1" | sed -En 's/^tmux[ -]([a-z]+-)?([0-9]+\.[0-9]+).*/\2/p'
}

cpu_revamped_version_ge() {
  case "$1:$2" in
  *[!0-9.:]* | :* | *:) return 1 ;;
  *) ;;
  esac
  cpu_revamped_version_ge_have="${1%%.*}"
  cpu_revamped_version_ge_want="${2%%.*}"
  [ "${cpu_revamped_version_ge_have}" -gt "${cpu_revamped_version_ge_want}" ] && return 0
  [ "${cpu_revamped_version_ge_have}" -eq "${cpu_revamped_version_ge_want}" ] || return 1
  cpu_revamped_version_ge_have="${1#*.}"
  cpu_revamped_version_ge_want="${2#*.}"
  [ "${cpu_revamped_version_ge_have%%.*}" -ge "${cpu_revamped_version_ge_want%%.*}" ]
}

cpu_revamped_emit() {
  for cpu_revamped_emit_arg in "$@"; do
    case "${cpu_revamped_emit_arg}" in
    *\;) cpu_revamped_emit_arg="${cpu_revamped_emit_arg%;}\\;" ;;
    *) ;;
    esac
    CPU_REVAMPED_PLAN="${CPU_REVAMPED_PLAN}${cpu_revamped_emit_arg:-${CPU_REVAMPED_EMPTY}}
"
  done
  CPU_REVAMPED_PLAN="${CPU_REVAMPED_PLAN}
"
}

cpu_revamped_literal() {
  printf '%s\n' "$1" | sed -e "s/'/'\\\\''/g" -e "s/#/'\"\$(printf '%b' '\\\\0043')\"'/g" -e "1s/^/'/" -e "\$s/\$/'/"
}

cpu_revamped_send() {
  set --
  cpu_revamped_send_sep=""
  while IFS= read -r cpu_revamped_send_line; do
    if [ -z "${cpu_revamped_send_line}" ]; then
      [ "$#" -eq 0 ] || cpu_revamped_send_sep=";"
      continue
    fi
    [ -z "${cpu_revamped_send_sep}" ] || set -- "$@" "${cpu_revamped_send_sep}"
    cpu_revamped_send_sep=""
    [ "${cpu_revamped_send_line}" != "${CPU_REVAMPED_EMPTY}" ] || cpu_revamped_send_line=""
    set -- "$@" "${cpu_revamped_send_line}"
  done <<PLAN
${CPU_REVAMPED_PLAN}
PLAN
  [ "$#" -gt 0 ] || return 0
  tmux "$@" 2>/dev/null
}

cpu_revamped_send_each() {
  cpu_revamped_send_each_status=0
  set --
  while IFS= read -r cpu_revamped_send_each_line; do
    if [ -n "${cpu_revamped_send_each_line}" ]; then
      [ "${cpu_revamped_send_each_line}" != "${CPU_REVAMPED_EMPTY}" ] || cpu_revamped_send_each_line=""
      set -- "$@" "${cpu_revamped_send_each_line}"
      continue
    fi
    [ "$#" -gt 0 ] || continue
    tmux "$@" || cpu_revamped_send_each_status=1
    set --
  done <<PLAN
${CPU_REVAMPED_PLAN}
PLAN
  return "${cpu_revamped_send_each_status}"
}

cpu_revamped_deliver() {
  ! cpu_revamped_send || return 0
  cpu_revamped_send_each
}

cpu_revamped_lines() {
  printf '%s' "${CPU_REVAMPED_PLAN}" | awk -v empty="${CPU_REVAMPED_EMPTY}" '$0 == empty { $0 = "\"\"" } $0 == "" && line != "" { print line; line = ""; next } $0 == "" { next } { line = (line == "" ? $0 : line " " $0) } END { if (line != "") { print line } }'
}

cpu_revamped_json() {
  printf '%s' "${CPU_REVAMPED_PLAN}" | awk -v empty="${CPU_REVAMPED_EMPTY}" '
    function quote(s,    out, i, c) {
      out = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") { out = out "\\\\" } else if (c == "\"") { out = out "\\\"" } else { out = out c }
      }
      return "\"" out "\""
    }
    /^$/ { if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" } args = ""; next }
    $0 == empty { $0 = "" }
    { args = args (args == "" ? "" : ",") quote($0) }
    END {
      if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" }
      print "{\"bindings\":[" rows "]}"
    }
  '
}

cpu_revamped_bindings() {
  printf '%s' "${CPU_REVAMPED_PLAN}" | awk 'previous == "" && $0 == "bind-key" { count++ } { previous = $0 } END { print count + 0 }'
}

cpu_revamped_setting_name() {
  cpu_revamped_setting_name_raw=$(printf '%s\n' "${1#--}" | tr '-' '_')
  case " ${CPU_REVAMPED_NAMES} " in
  *" ${cpu_revamped_setting_name_raw} "*) printf '%s\n' "${cpu_revamped_setting_name_raw}" ;;
  *) printf '\n' ;;
  esac
}

cpu_revamped_bind() {
  case "$1" in
  "" | off) return 0 ;;
  *) ;;
  esac
  cpu_revamped_bind_key="$1" cpu_revamped_bind_note="$2"
  shift 2
  set -- "${cpu_revamped_bind_key}" "$@"
  [ "${CPU_REVAMPED_NOTES}" != 1 ] || set -- -N "${cpu_revamped_bind_note}" "$@"
  cpu_revamped_emit bind-key "$@"
}

cpu_revamped_job_quote() {
  printf '%s\n' "$1" | sed -e "s/'/'\\\\''/g" -e 's/#/##/g' -e 's/%/%%/g' -e "1s/^/'/" -e "\$s/\$/'/"
}

cpu_revamped_carried() {
  cpu_revamped_carried_set=$(env | sed -n 's/^CPU_REVAMPED_\([A-Z_]*\)=\(.*\)$/\1 \2/p')
  [ -n "${cpu_revamped_carried_set}" ] || return 0
  printf '%s\n' "${cpu_revamped_carried_set}" | CPU_REVAMPED_WANTED="${CPU_REVAMPED_CARRIED}" awk '
    BEGIN { count = split(ENVIRON["CPU_REVAMPED_WANTED"], name, " "); for (i = 1; i <= count; i++) { wanted[toupper(name[i])] = i } }
    {
      key = $1
      if (!(key in wanted)) { next }
      given[wanted[key]] = 1
      value[wanted[key]] = substr($0, length(key) + 2)
    }
    END {
      for (i = 1; i <= count; i++) {
        if (!given[i]) { continue }
        flag = name[i]
        gsub(/_/, "-", flag)
        print flag "\t" value[i]
      }
    }
  '
}

cpu_revamped_tools() {
  cpu_revamped_tools_path="${REVAMPED_LIB%/lib}/bin/cpu-revamped"
  CPU_REVAMPED_TOOL=$(cpu_revamped_literal "${cpu_revamped_tools_path}")
  CPU_REVAMPED_JOB=$(cpu_revamped_job_quote "${cpu_revamped_tools_path}")
  cpu_revamped_tools_rows=$(cpu_revamped_carried)
  while IFS='	' read -r cpu_revamped_tools_flag cpu_revamped_tools_value; do
    [ -n "${cpu_revamped_tools_flag}" ] || continue
    CPU_REVAMPED_TOOL="${CPU_REVAMPED_TOOL} --${cpu_revamped_tools_flag} $(cpu_revamped_literal "${cpu_revamped_tools_value}")"
    CPU_REVAMPED_JOB="${CPU_REVAMPED_JOB} --${cpu_revamped_tools_flag} $(cpu_revamped_job_quote "${cpu_revamped_tools_value}")"
  done <<EOF
${cpu_revamped_tools_rows}
EOF
}

cpu_revamped_held() {
  tmux list-keys -T prefix 2>/dev/null | awk '
    {
      at = 2
      if ($at == "-r") { at++ }
      if ($at == "-T") { at += 2 }
      key = $at
      if (key ~ /^\\./) { key = substr(key, 2) }
      rest = ""
      for (i = at + 1; i <= NF; i++) { rest = rest " " $i }
      if (index(rest, "cpu-revamped") == 0) { printf "%s ", key }
    }
  '
}

cpu_revamped_doubled() {
  cpu_revamped_doubled_rest="$1" cpu_revamped_doubled_hash='#' CPU_REVAMPED_DOUBLED=""
  while [ "${cpu_revamped_doubled_rest}" != "${cpu_revamped_doubled_rest#*"${cpu_revamped_doubled_hash}"}" ]; do
    CPU_REVAMPED_DOUBLED="${CPU_REVAMPED_DOUBLED}${cpu_revamped_doubled_rest%%"${cpu_revamped_doubled_hash}"*}${cpu_revamped_doubled_hash}${cpu_revamped_doubled_hash}"
    cpu_revamped_doubled_rest="${cpu_revamped_doubled_rest#*"${cpu_revamped_doubled_hash}"}"
  done
  CPU_REVAMPED_DOUBLED="${CPU_REVAMPED_DOUBLED}${cpu_revamped_doubled_rest}"
}

cpu_revamped_now() {
  CPU_REVAMPED_NOW=$(date +%s 2>/dev/null) || CPU_REVAMPED_NOW=0
}

cpu_revamped_version() {
  cpu_revamped_version_raw=$(tmux -V 2>/dev/null) || cpu_revamped_version_raw=""
  CPU_REVAMPED_TMUX=$(cpu_revamped_parse_version "${cpu_revamped_version_raw}")
}

cpu_revamped_number() {
  CPU_REVAMPED_NUMBER="$1"
  revamped_cache_is_number "$1" || CPU_REVAMPED_NUMBER="$2"
}

cpu_revamped_store() {
  cpu_revamped_emit set-option -gq "@cpu_revamped_$1" "$2"
  IFS= read -r "CPU_REVAMPED_S_$1" <<EOF
$2
EOF
}

cpu_revamped_raw_add() {
  CPU_REVAMPED_RAW="${CPU_REVAMPED_RAW}
${CPU_REVAMPED_MARK}$1
$2"
}

cpu_revamped_raw_read() {
  cpu_revamped_raw_read_name="$1"
  shift
  cpu_revamped_raw_read_text=$("$@" 2>/dev/null) || cpu_revamped_raw_read_text=""
  cpu_revamped_raw_add "${cpu_revamped_raw_read_name}" "${cpu_revamped_raw_read_text}"
}

cpu_revamped_pause() {
  sleep "${CPU_REVAMPED_SAMPLE}"
}

cpu_revamped_raw_macos() {
  if revamped_has_command iostat; then
    cpu_revamped_raw_read iostat iostat -c 2 -w 1 -n 0
  elif revamped_has_command top; then
    cpu_revamped_raw_read top top -l2 -n0
  fi
}

cpu_revamped_raw_percent() {
  if revamped_is_linux; then
    cpu_revamped_raw_read stat1 cat /proc/stat
    cpu_revamped_pause
    cpu_revamped_raw_read stat2 cat /proc/stat
  elif revamped_is_macos; then
    cpu_revamped_raw_macos
  fi
}

cpu_revamped_raw_freq() {
  if revamped_is_apple_silicon; then
    cpu_revamped_raw_read brand sysctl -n machdep.cpu.brand_string
  elif revamped_is_macos; then
    cpu_revamped_raw_read cpufreq sysctl -n hw.cpufrequency
  elif revamped_is_linux; then
    cpu_revamped_raw_read freqinfo cat /proc/cpuinfo
    cpu_revamped_raw_read scaling cat "${CPU_REVAMPED_SYS}/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
  fi
}

cpu_revamped_raw_load() {
  if revamped_is_macos; then
    cpu_revamped_raw_read vmloadavg sysctl -n vm.loadavg
    cpu_revamped_raw_read ncpu sysctl -n hw.ncpu
  elif revamped_is_linux; then
    cpu_revamped_raw_read loadavg cat /proc/loadavg
    cpu_revamped_raw_read countinfo cat /proc/cpuinfo
  fi
}

cpu_revamped_raw_governor() {
  revamped_is_linux || return 0
  cpu_revamped_raw_read governor cat "${CPU_REVAMPED_SYS}/devices/system/cpu/cpu0/cpufreq/scaling_governor"
}

cpu_revamped_raw_processes() {
  cpu_revamped_raw_processes_text=$(LC_ALL=C ps axo pcpu=,comm= 2>/dev/null) || cpu_revamped_raw_processes_text=""
  cpu_revamped_raw_add ps "${cpu_revamped_raw_processes_text}"
}

cpu_revamped_round() {
  LC_ALL=C awk -v text="$1" 'BEGIN { if (match(text, /[0-9]+(\.[0-9])?/)) { value = substr(text, RSTART, RLENGTH) + 0; if (value > 0) { print int(value + 0.5) } } }'
}

cpu_revamped_degrees() {
  case "$1" in
  '' | *[!0-9]*) return 1 ;;
  *) ;;
  esac
  cpu_revamped_degrees_value="${1#"${1%%[!0]*}"}"
  CPU_REVAMPED_NUMBER=$((${cpu_revamped_degrees_value:-0} / 1000))
}

cpu_revamped_slurp() {
  CPU_REVAMPED_LINE=""
  [ -r "$1" ] || return 1
  read -r CPU_REVAMPED_LINE 2>/dev/null <"$1"
}

cpu_revamped_hotter() {
  if [ -z "${CPU_REVAMPED_F_temp}" ] || [ "${CPU_REVAMPED_NUMBER}" -gt "${CPU_REVAMPED_F_temp}" ]; then
    CPU_REVAMPED_F_temp="${CPU_REVAMPED_NUMBER}"
  fi
}

cpu_revamped_temp_thermal() {
  for cpu_revamped_temp_thermal_file in "${CPU_REVAMPED_SYS}"/class/thermal/thermal_zone*/temp; do
    [ -r "${cpu_revamped_temp_thermal_file}" ] || continue
    cpu_revamped_slurp "${cpu_revamped_temp_thermal_file%temp}type" || :
    case "${CPU_REVAMPED_LINE}" in
    *cpu* | *x86* | *acpitz*) : ;;
    *) continue ;;
    esac
    cpu_revamped_slurp "${cpu_revamped_temp_thermal_file}" || continue
    cpu_revamped_degrees "${CPU_REVAMPED_LINE}" || continue
    cpu_revamped_hotter
  done
}

cpu_revamped_temp_coretemp() {
  for cpu_revamped_temp_coretemp_file in "${CPU_REVAMPED_SYS}"/devices/platform/coretemp.0/hwmon/hwmon*/temp*_input; do
    [ -r "${cpu_revamped_temp_coretemp_file}" ] || continue
    cpu_revamped_slurp "${cpu_revamped_temp_coretemp_file}" || continue
    cpu_revamped_degrees "${CPU_REVAMPED_LINE}" || continue
    cpu_revamped_hotter
  done
}

cpu_revamped_temp_input() {
  cpu_revamped_slurp "$1" || return 0
  cpu_revamped_degrees "${CPU_REVAMPED_LINE}" || return 0
  cpu_revamped_slurp "${1%_input}_label" || :
  case "${CPU_REVAMPED_LINE}" in
  Tctl | Tdie)
    if [ -z "${cpu_revamped_temp_k10_tctl}" ] || [ "${CPU_REVAMPED_NUMBER}" -gt "${cpu_revamped_temp_k10_tctl}" ]; then
      cpu_revamped_temp_k10_tctl="${CPU_REVAMPED_NUMBER}"
    fi
    ;;
  *)
    if [ -z "${cpu_revamped_temp_k10_best}" ] || [ "${CPU_REVAMPED_NUMBER}" -gt "${cpu_revamped_temp_k10_best}" ]; then
      cpu_revamped_temp_k10_best="${CPU_REVAMPED_NUMBER}"
    fi
    ;;
  esac
}

cpu_revamped_temp_k10() {
  cpu_revamped_temp_k10_tctl="" cpu_revamped_temp_k10_best=""
  for cpu_revamped_temp_k10_dir in "${CPU_REVAMPED_SYS}"/class/hwmon/hwmon*; do
    cpu_revamped_slurp "${cpu_revamped_temp_k10_dir}/name" || continue
    [ "${CPU_REVAMPED_LINE}" = k10temp ] || continue
    for cpu_revamped_temp_k10_input in "${cpu_revamped_temp_k10_dir}"/temp*_input; do
      [ -r "${cpu_revamped_temp_k10_input}" ] || continue
      cpu_revamped_temp_input "${cpu_revamped_temp_k10_input}"
    done
  done
  CPU_REVAMPED_F_temp="${cpu_revamped_temp_k10_tctl:-${cpu_revamped_temp_k10_best}}"
}

cpu_revamped_temp_sensors() {
  revamped_has_command sensors || return 0
  cpu_revamped_temp_sensors_text=$(sensors 2>/dev/null) || cpu_revamped_temp_sensors_text=""
  CPU_REVAMPED_F_temp=$(printf '%s\n' "${cpu_revamped_temp_sensors_text}" | awk '/Tctl|Tdie|Package id 0|Core 0|CPU Temperature|k10temp/ { if (match($0, /\+[0-9]+/)) { print substr($0, RSTART + 1, RLENGTH - 1) } exit }')
}

cpu_revamped_temp_linux() {
  cpu_revamped_temp_thermal
  [ -n "${CPU_REVAMPED_F_temp}" ] || cpu_revamped_temp_coretemp
  [ -n "${CPU_REVAMPED_F_temp}" ] || cpu_revamped_temp_k10
  [ -n "${CPU_REVAMPED_F_temp}" ] || cpu_revamped_temp_sensors
}

cpu_revamped_temp_macmon() {
  cpu_revamped_temp_macmon_text=$(macmon pipe -s 1 -i 200 2>/dev/null) || cpu_revamped_temp_macmon_text=""
  cpu_revamped_temp_macmon_rest="${cpu_revamped_temp_macmon_text#*\"cpu_temp_avg\":}"
  [ "${cpu_revamped_temp_macmon_rest}" != "${cpu_revamped_temp_macmon_text}" ] || return 0
  CPU_REVAMPED_F_temp=$(cpu_revamped_round "${cpu_revamped_temp_macmon_rest%%[!0-9.]*}")
}

cpu_revamped_istats_parse() {
  LC_ALL=C awk '
    { if (decimal == "" && match($0, /[0-9]+\.[0-9]+/)) { decimal = substr($0, RSTART, RLENGTH) } if (whole == "" && match($0, /[0-9]+/)) { whole = substr($0, RSTART, RLENGTH) } }
    END { value = (decimal != "") ? decimal : whole; if (value != "" && value + 0 > 0) { printf "%.0f\n", value } }
  '
}

cpu_revamped_temp_istats() {
  cpu_revamped_temp_istats_text=$(istats cpu temp 2>/dev/null) || cpu_revamped_temp_istats_text=""
  CPU_REVAMPED_F_temp=$(printf '%s\n' "${cpu_revamped_temp_istats_text}" | cpu_revamped_istats_parse)
}

cpu_revamped_temp_macos() {
  if revamped_is_apple_silicon && revamped_has_command macmon; then
    cpu_revamped_temp_macmon
  fi
  if [ -z "${CPU_REVAMPED_F_temp}" ] && revamped_has_command osx-cpu-temp; then
    cpu_revamped_temp_macos_text=$(osx-cpu-temp 2>/dev/null) || cpu_revamped_temp_macos_text=""
    CPU_REVAMPED_F_temp=$(cpu_revamped_round "${cpu_revamped_temp_macos_text}")
  fi
  if [ -z "${CPU_REVAMPED_F_temp}" ] && revamped_has_command istats; then
    cpu_revamped_temp_istats
  fi
}

cpu_revamped_temp_read() {
  CPU_REVAMPED_F_temp=""
  if revamped_is_linux; then
    cpu_revamped_temp_linux
  elif revamped_is_macos; then
    cpu_revamped_temp_macos
  fi
}

cpu_revamped_figures() {
  LC_ALL=C awk -v history="${CPU_REVAMPED_S_history}" -v keep="$1" -v mark="${CPU_REVAMPED_MARK}" '
    index($0, mark) == 1 { section = substr($0, length(mark) + 1); next }
    section ~ /^stat[12]$/ && $1 == "cpu" {
      total = 0
      for (i = 2; i <= NF; i++) { if ($i ~ /^[0-9]+$/) { total += $i } }
      idle = $5 + $6
      if (section == "stat1") { first_total = total; first_idle = idle } else { second_total = total; second_idle = idle; sampled = 1 }
    }
    section == "iostat" && NF >= 3 && $3 ~ /^[0-9]+$/ { spare = $3; read_rows = 1 }
    section == "top" && tolower($0) ~ /cpu usage/ { usage = $0 }
    section == "brand" && !have_clock {
      have_clock = 1
      clock = 0
      if (match($0, /M[1-5]/)) { split("3200 3400 4000 4200 4500", steps, " "); clock = steps[substr($0, RSTART + 1, 1)] }
    }
    section == "cpufreq" && !have_clock && $1 ~ /^[0-9]+$/ && $1 + 0 > 0 { clock = int($1 / 1000000); have_clock = 1 }
    section == "freqinfo" && index($0, "cpu MHz") { if (!have_info) { split($0, parts, ":"); megahertz = int(parts[2]); have_info = 1 } }
    section == "scaling" && $1 ~ /^[0-9]+$/ { scaled = int($1 / 1000); have_scaled = 1 }
    section == "ncpu" && $1 ~ /^[0-9]+$/ { count = $1 }
    section == "countinfo" && $1 == "processor" { cores++ }
    section == "vmloadavg" && NF >= 4 { one = $2; five = $3; fifteen = $4 }
    section == "loadavg" && NF >= 3 { one = $1; five = $2; fifteen = $3 }
    section == "governor" && governor == "" { governor = $1 }
    section == "ps" && NF >= 2 && $1 + 0 > most {
      most = $1 + 0
      holder = $2
      for (i = 3; i <= NF; i++) { holder = holder " " $i }
    }
    END {
      if (sampled) {
        span = second_total - first_total
        used = span - (second_idle - first_idle)
        if (used < 0) { used = 0 }
        percent = (span <= 0) ? 0 : sprintf("%.0f", used / span * 100)
      } else if (read_rows) {
        percent = sprintf("%.0f", 100 - spare)
      } else if (usage != "" && match(usage, /[0-9.]+% *idle/)) {
        text = substr(usage, RSTART, RLENGTH)
        sub(/%.*/, "", text)
        percent = sprintf("%.0f", 100 - text)
      } else {
        percent = 0
      }
      if (have_clock) { freq = clock } else if (have_info) { freq = megahertz } else if (have_scaled) { freq = scaled }
      if (cores > 0) { count = cores }
      count_figure = count
      count = split(history, past, " ")
      past[++count] = percent
      history = ""
      for (i = (count > keep ? count - keep + 1 : 1); i <= count; i++) { history = history (history == "" ? "" : " ") past[i] }
      if (holder != "") {
        if (holder ~ /^\//) { sub(/.*\//, "", holder) }
        top = int(most) " " holder
      }
      printf "percent\t%s\nfreq\t%s\nload\t%s\nload5\t%s\nload15\t%s\ncount\t%s\ngovernor\t%s\nhistory\t%s\ntop_process\t%s\n", percent, freq, one, five, fifteen, count_figure, governor, history, top
    }
  '
}

cpu_revamped_measure() {
  CPU_REVAMPED_F_percent="" CPU_REVAMPED_F_freq="" CPU_REVAMPED_F_load="" CPU_REVAMPED_F_load5="" CPU_REVAMPED_F_load15=""
  CPU_REVAMPED_F_count="" CPU_REVAMPED_F_governor="" CPU_REVAMPED_F_history="" CPU_REVAMPED_F_top_process=""
  cpu_revamped_number "${CPU_REVAMPED_S_graph_width}" "${CPU_REVAMPED_DEFAULT_GRAPH}"
  [ "${CPU_REVAMPED_NUMBER}" -gt 0 ] || CPU_REVAMPED_NUMBER="${CPU_REVAMPED_DEFAULT_GRAPH}"
  cpu_revamped_measure_rows=$(printf '%s\n' "${CPU_REVAMPED_RAW}" | cpu_revamped_figures "${CPU_REVAMPED_NUMBER}") || cpu_revamped_measure_rows=""
  while IFS='	' read -r cpu_revamped_measure_name cpu_revamped_measure_value; do
    [ -n "${cpu_revamped_measure_name}" ] || continue
    IFS= read -r "CPU_REVAMPED_F_${cpu_revamped_measure_name}" <<EOF
${cpu_revamped_measure_value}
EOF
  done <<EOF
${cpu_revamped_measure_rows}
EOF
}

cpu_revamped_wanted() {
  for cpu_revamped_wanted_name in "$@"; do
    case " ${CPU_REVAMPED_WANT} " in
    *" ${cpu_revamped_wanted_name} "*) return 0 ;;
    *) ;;
    esac
  done
  return 1
}

cpu_revamped_due() {
  cpu_revamped_due_ts="$1"
  shift
  cpu_revamped_wanted "$@" || return 1
  revamped_cache_is_number "${cpu_revamped_due_ts}" || return 0
  [ "$((CPU_REVAMPED_NOW - cpu_revamped_due_ts))" -gt "${CPU_REVAMPED_DETAIL}" ]
}

cpu_revamped_kept() {
  case " ${CPU_REVAMPED_DUE} " in
  *" $1 "*) return 0 ;;
  *) return 1 ;;
  esac
}

cpu_revamped_gather() {
  if cpu_revamped_due "${CPU_REVAMPED_S_temp_ts}" temp temp_icon temp_fg_color temp_bg_color alert; then
    CPU_REVAMPED_DUE="${CPU_REVAMPED_DUE} temp"
    cpu_revamped_temp_read
  fi
  if cpu_revamped_due "${CPU_REVAMPED_S_freq_ts}" freq; then
    CPU_REVAMPED_DUE="${CPU_REVAMPED_DUE} freq"
    cpu_revamped_raw_freq
  fi
  if cpu_revamped_due "${CPU_REVAMPED_S_load_ts}" load load5 load15 load_color count; then
    CPU_REVAMPED_DUE="${CPU_REVAMPED_DUE} load"
    cpu_revamped_raw_load
  fi
  if cpu_revamped_due "${CPU_REVAMPED_S_top_process_ts}" top_process; then
    CPU_REVAMPED_DUE="${CPU_REVAMPED_DUE} top_process"
    cpu_revamped_raw_processes
  fi
  if cpu_revamped_due "${CPU_REVAMPED_S_governor_ts}" governor; then
    CPU_REVAMPED_DUE="${CPU_REVAMPED_DUE} governor"
    cpu_revamped_raw_governor
  fi
}

cpu_revamped_keep() {
  cpu_revamped_store percent "${CPU_REVAMPED_F_percent}"
  cpu_revamped_store history "${CPU_REVAMPED_F_history}"
  cpu_revamped_store percent_ts "${CPU_REVAMPED_NOW}"
  if cpu_revamped_kept temp; then
    cpu_revamped_store temp "${CPU_REVAMPED_F_temp}"
    cpu_revamped_store temp_ts "${CPU_REVAMPED_NOW}"
  fi
  if cpu_revamped_kept freq; then
    cpu_revamped_store freq "${CPU_REVAMPED_F_freq}"
    cpu_revamped_store freq_ts "${CPU_REVAMPED_NOW}"
  fi
  if cpu_revamped_kept load; then
    cpu_revamped_store load "${CPU_REVAMPED_F_load}"
    cpu_revamped_store load5 "${CPU_REVAMPED_F_load5}"
    cpu_revamped_store load15 "${CPU_REVAMPED_F_load15}"
    cpu_revamped_store count "${CPU_REVAMPED_F_count}"
    cpu_revamped_store load_ts "${CPU_REVAMPED_NOW}"
  fi
  if cpu_revamped_kept top_process; then
    cpu_revamped_store top_process "${CPU_REVAMPED_F_top_process}"
    cpu_revamped_store top_process_ts "${CPU_REVAMPED_NOW}"
  fi
  if cpu_revamped_kept governor; then
    cpu_revamped_store governor "${CPU_REVAMPED_F_governor}"
    cpu_revamped_store governor_ts "${CPU_REVAMPED_NOW}"
  fi
}

cpu_revamped_sample() {
  cpu_revamped_number "${CPU_REVAMPED_S_detail_interval}" "${CPU_REVAMPED_DEFAULT_DETAIL}"
  CPU_REVAMPED_DETAIL="${CPU_REVAMPED_NUMBER}"
  CPU_REVAMPED_RAW="" CPU_REVAMPED_DUE="" CPU_REVAMPED_F_temp=""
  cpu_revamped_raw_percent
  cpu_revamped_gather
  cpu_revamped_measure
  cpu_revamped_keep
}

cpu_revamped_refresh() {
  CPU_REVAMPED_PLAN=""
  cpu_revamped_now
  cpu_revamped_sample
  CPU_REVAMPED_STORED=1
  cpu_revamped_send || CPU_REVAMPED_STORED=0
}

cpu_revamped_limit() {
  cpu_revamped_number "${CPU_REVAMPED_S_interval}" "${CPU_REVAMPED_DEFAULT_INTERVAL}"
  CPU_REVAMPED_LIMIT="${CPU_REVAMPED_NUMBER}"
}

cpu_revamped_stale() {
  revamped_cache_is_number "${CPU_REVAMPED_S_percent_ts}" || return 0
  [ "$((CPU_REVAMPED_NOW - CPU_REVAMPED_S_percent_ts))" -gt "${CPU_REVAMPED_LIMIT}" ]
}

cpu_revamped_locked() {
  [ "${CPU_REVAMPED_S_percent_lock}" = 1 ] || return 1
  revamped_cache_is_number "${CPU_REVAMPED_S_percent_lock_ts}" || return 1
  [ "$((CPU_REVAMPED_NOW - CPU_REVAMPED_S_percent_lock_ts))" -lt "${REVAMPED_CACHE_MAX_RUN_DEFAULT}" ]
}

cpu_revamped_attended() {
  [ "${CPU_REVAMPED_S_throttle_when_detached}" = 1 ] || return 0
  cpu_revamped_attended_clients=$(tmux list-clients -F x 2>/dev/null) || cpu_revamped_attended_clients=""
  [ -n "${cpu_revamped_attended_clients}" ]
}

cpu_revamped_level() {
  if [ "$1" -ge "$3" ]; then
    CPU_REVAMPED_TIER=high
  elif [ "$1" -ge "$2" ]; then
    CPU_REVAMPED_TIER=medium
  else
    CPU_REVAMPED_TIER=low
  fi
}

cpu_revamped_tier() {
  cpu_revamped_number "${CPU_REVAMPED_S_medium_thresh}" "${CPU_REVAMPED_DEFAULT_MEDIUM}"
  cpu_revamped_tier_medium="${CPU_REVAMPED_NUMBER}"
  cpu_revamped_number "${CPU_REVAMPED_S_high_thresh}" "${CPU_REVAMPED_DEFAULT_HIGH}"
  cpu_revamped_level "$1" "${cpu_revamped_tier_medium}" "${CPU_REVAMPED_NUMBER}"
}

cpu_revamped_style() {
  case "$1:${CPU_REVAMPED_TIER}" in
  icon:high) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_high_icon}" ;;
  icon:medium) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_medium_icon}" ;;
  icon:low) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_low_icon}" ;;
  fg_color:high) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_high_fg_color}" ;;
  fg_color:medium) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_medium_fg_color}" ;;
  fg_color:low) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_low_fg_color}" ;;
  bg_color:high) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_high_bg_color}" ;;
  bg_color:medium) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_medium_bg_color}" ;;
  *) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_low_bg_color}" ;;
  esac
}

cpu_revamped_value_tiered() {
  CPU_REVAMPED_OUT=""
  cpu_revamped_number "$2" 0
  cpu_revamped_tier "${CPU_REVAMPED_NUMBER}"
  cpu_revamped_style "$1"
}

cpu_revamped_value_temp_style() {
  CPU_REVAMPED_OUT=""
  revamped_cache_is_number "${CPU_REVAMPED_S_temp}" || return 0
  cpu_revamped_number "${CPU_REVAMPED_S_temp_medium_thresh}" "${CPU_REVAMPED_DEFAULT_TEMP_MEDIUM}"
  cpu_revamped_value_temp_style_medium="${CPU_REVAMPED_NUMBER}"
  cpu_revamped_number "${CPU_REVAMPED_S_temp_high_thresh}" "${CPU_REVAMPED_DEFAULT_TEMP_HIGH}"
  cpu_revamped_level "${CPU_REVAMPED_S_temp}" "${cpu_revamped_value_temp_style_medium}" "${CPU_REVAMPED_NUMBER}"
  case "$1:${CPU_REVAMPED_TIER}" in
  icon:high) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_temp_high_icon}" ;;
  icon:medium) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_temp_medium_icon}" ;;
  icon:low) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_temp_low_icon}" ;;
  fg_color:high) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_temp_high_fg_color}" ;;
  fg_color:medium) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_temp_medium_fg_color}" ;;
  fg_color:low) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_temp_low_fg_color}" ;;
  bg_color:high) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_temp_high_bg_color}" ;;
  bg_color:medium) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_temp_medium_bg_color}" ;;
  *) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_temp_low_bg_color}" ;;
  esac
}

cpu_revamped_value_shaped() {
  CPU_REVAMPED_OUT=""
  [ -n "$2" ] || return 0
  # shellcheck disable=SC2059
  CPU_REVAMPED_OUT=$(printf "$1" "$2")
}

cpu_revamped_value_temp() {
  CPU_REVAMPED_OUT=""
  revamped_cache_is_number "${CPU_REVAMPED_S_temp}" || return 0
  cpu_revamped_value_temp_shown="${CPU_REVAMPED_S_temp}"
  if [ "${CPU_REVAMPED_S_temp_unit}" = F ]; then
    cpu_revamped_value_temp_shown=$(((18 * CPU_REVAMPED_S_temp + 5) / 10 + 32))
  fi
  cpu_revamped_value_temp_format="${CPU_REVAMPED_S_temp_format:-%s°${CPU_REVAMPED_S_temp_unit}}"
  # shellcheck disable=SC2059
  CPU_REVAMPED_OUT=$(printf "${cpu_revamped_value_temp_format}" "${cpu_revamped_value_temp_shown}")
}

cpu_revamped_value_freq() {
  CPU_REVAMPED_OUT=""
  [ "${CPU_REVAMPED_S_freq}" != 0 ] || return 0
  cpu_revamped_value_shaped "${CPU_REVAMPED_S_freq_format}" "${CPU_REVAMPED_S_freq}"
}

cpu_revamped_value_load_color() {
  CPU_REVAMPED_OUT=""
  [ -n "${CPU_REVAMPED_S_load}" ] || return 0
  cpu_revamped_value_load_color_count="${CPU_REVAMPED_S_count}"
  revamped_cache_is_number "${cpu_revamped_value_load_color_count}" || cpu_revamped_value_load_color_count=1
  [ "${cpu_revamped_value_load_color_count}" -gt 0 ] || cpu_revamped_value_load_color_count=1
  CPU_REVAMPED_TIER=$(LC_ALL=C awk -v figure="${CPU_REVAMPED_S_load}" -v cores="${cpu_revamped_value_load_color_count}" -v medium="${CPU_REVAMPED_S_load_medium_ratio}" -v high="${CPU_REVAMPED_S_load_high_ratio}" 'BEGIN { ratio = figure / cores; if (ratio >= high) { print "high" } else if (ratio >= medium) { print "medium" } else { print "low" } }')
  cpu_revamped_style fg_color
}

cpu_revamped_value_alert() {
  CPU_REVAMPED_OUT=""
  cpu_revamped_number "${CPU_REVAMPED_S_percent}" 0
  cpu_revamped_value_alert_percent="${CPU_REVAMPED_NUMBER}"
  cpu_revamped_number "${CPU_REVAMPED_S_high_thresh}" "${CPU_REVAMPED_DEFAULT_HIGH}"
  cpu_revamped_value_alert_high="${CPU_REVAMPED_NUMBER}"
  cpu_revamped_number "${CPU_REVAMPED_S_temp_high_thresh}" "${CPU_REVAMPED_DEFAULT_TEMP_HIGH}"
  if [ "${cpu_revamped_value_alert_percent}" -ge "${cpu_revamped_value_alert_high}" ]; then
    CPU_REVAMPED_OUT="${CPU_REVAMPED_S_alert_icon}"
  elif revamped_cache_is_number "${CPU_REVAMPED_S_temp}" && [ "${CPU_REVAMPED_S_temp}" -ge "${CPU_REVAMPED_NUMBER}" ]; then
    CPU_REVAMPED_OUT="${CPU_REVAMPED_S_alert_icon}"
  fi
}

cpu_revamped_value_top() {
  CPU_REVAMPED_OUT=""
  [ -n "${CPU_REVAMPED_S_top_process}" ] || return 0
  cpu_revamped_doubled "${CPU_REVAMPED_S_top_process#* }"
  CPU_REVAMPED_OUT="${CPU_REVAMPED_DOUBLED} ${CPU_REVAMPED_S_top_process%% *}%"
}

cpu_revamped_value_graph() {
  CPU_REVAMPED_OUT=""
  cpu_revamped_value_graph_rest="${CPU_REVAMPED_S_history}" cpu_revamped_value_graph_bytes=""
  while [ -n "${cpu_revamped_value_graph_rest}" ]; do
    cpu_revamped_value_graph_item="${cpu_revamped_value_graph_rest%% *}"
    cpu_revamped_value_graph_rest="${cpu_revamped_value_graph_rest#"${cpu_revamped_value_graph_item}"}"
    cpu_revamped_value_graph_rest="${cpu_revamped_value_graph_rest# }"
    cpu_revamped_number "${cpu_revamped_value_graph_item%%.*}" 0
    [ "${CPU_REVAMPED_NUMBER}" -le 100 ] || CPU_REVAMPED_NUMBER=100
    cpu_revamped_value_graph_step=$((CPU_REVAMPED_NUMBER * CPU_REVAMPED_GRAPH_STEPS / CPU_REVAMPED_GRAPH_DIVISOR))
    set -- 201 202 203 204 205 206 207 210
    shift "${cpu_revamped_value_graph_step}"
    cpu_revamped_value_graph_bytes="${cpu_revamped_value_graph_bytes}\\0342\\0226\\0$1"
  done
  [ -n "${cpu_revamped_value_graph_bytes}" ] || return 0
  CPU_REVAMPED_OUT=$(printf '%b' "${cpu_revamped_value_graph_bytes}")
}

cpu_revamped_value() {
  case "$1" in
  percentage) cpu_revamped_value_shaped "${CPU_REVAMPED_S_percentage_format}" "${CPU_REVAMPED_S_percent}" ;;
  icon | fg_color | bg_color) cpu_revamped_value_tiered "$1" "${CPU_REVAMPED_S_percent}" ;;
  temp) cpu_revamped_value_temp ;;
  temp_icon | temp_fg_color | temp_bg_color) cpu_revamped_value_temp_style "${1#temp_}" ;;
  freq) cpu_revamped_value_freq ;;
  load) cpu_revamped_value_shaped "${CPU_REVAMPED_S_load_format}" "${CPU_REVAMPED_S_load}" ;;
  load5) cpu_revamped_value_shaped "${CPU_REVAMPED_S_load_format}" "${CPU_REVAMPED_S_load5}" ;;
  load15) cpu_revamped_value_shaped "${CPU_REVAMPED_S_load_format}" "${CPU_REVAMPED_S_load15}" ;;
  count) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_count}" ;;
  graph) cpu_revamped_value_graph ;;
  top_process) cpu_revamped_value_top ;;
  load_color) cpu_revamped_value_load_color ;;
  alert) cpu_revamped_value_alert ;;
  *) CPU_REVAMPED_OUT="${CPU_REVAMPED_S_governor}" ;;
  esac
}

cpu_revamped_own() {
  CPU_REVAMPED_NATURAL=0
  case "$1" in
  percentage) CPU_REVAMPED_LABEL="${CPU_REVAMPED_S_percentage_label}" CPU_REVAMPED_WIDTH="${CPU_REVAMPED_S_percentage_width}" CPU_REVAMPED_GLYPH='\0363\0260\0212\0232' CPU_REVAMPED_NATURAL=4 ;;
  temp) CPU_REVAMPED_LABEL="${CPU_REVAMPED_S_temp_label}" CPU_REVAMPED_WIDTH="${CPU_REVAMPED_S_temp_width}" CPU_REVAMPED_GLYPH='\0363\0260\0224\0217' CPU_REVAMPED_NATURAL=5 ;;
  freq) CPU_REVAMPED_LABEL="${CPU_REVAMPED_S_freq_label}" CPU_REVAMPED_WIDTH="${CPU_REVAMPED_S_freq_width}" CPU_REVAMPED_GLYPH='\0363\0260\0223\0205' CPU_REVAMPED_NATURAL=7 ;;
  load) CPU_REVAMPED_LABEL="${CPU_REVAMPED_S_load_label}" CPU_REVAMPED_WIDTH="${CPU_REVAMPED_S_load_width}" CPU_REVAMPED_GLYPH='\0363\0260\0227\0221' CPU_REVAMPED_NATURAL=5 ;;
  load5) CPU_REVAMPED_LABEL="${CPU_REVAMPED_S_load5_label}" CPU_REVAMPED_WIDTH="${CPU_REVAMPED_S_load5_width}" CPU_REVAMPED_GLYPH='\0363\0260\0227\0221' CPU_REVAMPED_NATURAL=5 ;;
  load15) CPU_REVAMPED_LABEL="${CPU_REVAMPED_S_load15_label}" CPU_REVAMPED_WIDTH="${CPU_REVAMPED_S_load15_width}" CPU_REVAMPED_GLYPH='\0363\0260\0227\0221' CPU_REVAMPED_NATURAL=5 ;;
  count) CPU_REVAMPED_LABEL="${CPU_REVAMPED_S_count_label}" CPU_REVAMPED_WIDTH="${CPU_REVAMPED_S_count_width}" CPU_REVAMPED_GLYPH='\0363\0260\0230\0232' CPU_REVAMPED_NATURAL=3 ;;
  graph) CPU_REVAMPED_LABEL="${CPU_REVAMPED_S_graph_label}" CPU_REVAMPED_WIDTH="${CPU_REVAMPED_S_graph_width}" CPU_REVAMPED_GLYPH='\0363\0260\0236\0261' ;;
  top_process) CPU_REVAMPED_LABEL="${CPU_REVAMPED_S_top_process_label}" CPU_REVAMPED_WIDTH="${CPU_REVAMPED_S_top_process_width}" CPU_REVAMPED_GLYPH='\0363\0260\0243\0206' ;;
  *) CPU_REVAMPED_LABEL="${CPU_REVAMPED_S_governor_label}" CPU_REVAMPED_WIDTH="${CPU_REVAMPED_S_governor_width}" CPU_REVAMPED_GLYPH='\0363\0260\0230\0256' ;;
  esac
}

cpu_revamped_pad() {
  if ! revamped_cache_is_number "${CPU_REVAMPED_WIDTH}"; then
    CPU_REVAMPED_WIDTH=0
    [ "${CPU_REVAMPED_S_fixed_width}" != on ] || CPU_REVAMPED_WIDTH="${CPU_REVAMPED_NATURAL}"
  fi
  [ "${CPU_REVAMPED_WIDTH}" -gt 0 ] || return 0
  revamped_publish_count "${CPU_REVAMPED_OUT}"
  [ "${revamped_publish_count_out}" -lt "${CPU_REVAMPED_WIDTH}" ] || return 0
  cpu_revamped_pad_gap=$(printf "%$((CPU_REVAMPED_WIDTH - revamped_publish_count_out))s" '')
  CPU_REVAMPED_OUT="${cpu_revamped_pad_gap}${CPU_REVAMPED_OUT}"
}

cpu_revamped_label() {
  [ -z "${CPU_REVAMPED_LABEL}" ] || return 0
  [ "${CPU_REVAMPED_S_icons}" = nerd ] || return 0
  CPU_REVAMPED_LABEL=$(printf '%b' "${CPU_REVAMPED_GLYPH}")
}

cpu_revamped_output() {
  cpu_revamped_value "$1"
  [ -n "${CPU_REVAMPED_OUT}" ] || return 0
  case " ${CPU_REVAMPED_LABELLED} " in
  *" $1 "*) cpu_revamped_own "$1" ;;
  *) return 0 ;;
  esac
  cpu_revamped_pad
  cpu_revamped_label
  [ -z "${CPU_REVAMPED_LABEL}" ] || CPU_REVAMPED_OUT="${CPU_REVAMPED_LABEL} ${CPU_REVAMPED_OUT}"
}

cpu_revamped_show() {
  cpu_revamped_output "$1"
  [ -z "${CPU_REVAMPED_OUT}" ] || printf '%s\n' "${CPU_REVAMPED_OUT}"
}

cpu_revamped_status() {
  cpu_revamped_load
  cpu_revamped_now
  cpu_revamped_limit
  CPU_REVAMPED_WANT="${CPU_REVAMPED_S_published} $1"
  if cpu_revamped_stale && ! cpu_revamped_locked && cpu_revamped_attended; then
    revamped_cache_refresh_if_stale percent "${CPU_REVAMPED_LIMIT}" cpu_revamped_refresh || :
  fi
  cpu_revamped_show "$1"
}

cpu_revamped_publish() {
  CPU_REVAMPED_WANT="${CPU_REVAMPED_S_published}"
  if cpu_revamped_attended; then
    cpu_revamped_refresh
    [ "${CPU_REVAMPED_STORED}" = 1 ] || return 0
  fi
  cpu_revamped_publish_rest="${CPU_REVAMPED_S_published}"
  while [ -n "${cpu_revamped_publish_rest}" ]; do
    cpu_revamped_publish_metric="${cpu_revamped_publish_rest%% *}"
    cpu_revamped_publish_rest="${cpu_revamped_publish_rest#"${cpu_revamped_publish_metric}"}"
    cpu_revamped_publish_rest="${cpu_revamped_publish_rest# }"
    [ -n "${cpu_revamped_publish_metric}" ] || continue
    cpu_revamped_output "${cpu_revamped_publish_metric}"
    revamped_publish_add "@cpu_revamped_out_${cpu_revamped_publish_metric}" "${CPU_REVAMPED_OUT}"
  done
  revamped_publish_commit || :
}

cpu_revamped_tick() {
  cpu_revamped_load
  cpu_revamped_publish
}

cpu_revamped_daemon() {
  revamped_ticker_run cpu_revamped cpu_revamped_tick "$$" "${CPU_REVAMPED_DEFAULT_INTERVAL}"
}

cpu_revamped_monitor() {
  if [ -n "${CPU_REVAMPED_S_popup_command}" ]; then
    CPU_REVAMPED_MONITOR="${CPU_REVAMPED_S_popup_command}"
  elif revamped_has_command btop; then
    CPU_REVAMPED_MONITOR=btop
  elif revamped_has_command htop; then
    CPU_REVAMPED_MONITOR=htop
  else
    CPU_REVAMPED_MONITOR=top
  fi
}

cpu_revamped_popup_check() {
  CPU_REVAMPED_POPUP_OK=0
  ! cpu_revamped_version_ge "${CPU_REVAMPED_TMUX}" "${CPU_REVAMPED_POPUP_SINCE}" || CPU_REVAMPED_POPUP_OK=1
}

cpu_revamped_popup() {
  cpu_revamped_load
  cpu_revamped_version
  cpu_revamped_popup_check
  if [ "${CPU_REVAMPED_POPUP_OK}" != 1 ]; then
    tmux display-message "cpu-revamped: tmux 3.2+ is required for the CPU detail popup" 2>/dev/null || :
    return 0
  fi
  cpu_revamped_monitor
  cpu_revamped_popup_program="${CPU_REVAMPED_MONITOR%% *}"
  if ! revamped_has_command "${cpu_revamped_popup_program}"; then
    cpu_revamped_doubled "${cpu_revamped_popup_program}"
    tmux display-message "cpu-revamped: ${CPU_REVAMPED_DOUBLED} is not installed" 2>/dev/null || :
    return 0
  fi
  tmux display-popup -E -w "${CPU_REVAMPED_S_popup_width}" -h "${CPU_REVAMPED_S_popup_height}" "${CPU_REVAMPED_MONITOR}" 2>/dev/null || :
}

cpu_revamped_plan_keys() {
  case "${CPU_REVAMPED_S_popup_key}: ${CPU_REVAMPED_KEYS} " in
  "${CPU_REVAMPED_DEFAULT_POPUP_KEY}:"*" ${CPU_REVAMPED_DEFAULT_POPUP_KEY} "*) CPU_REVAMPED_SKIPPED="${CPU_REVAMPED_SKIPPED}${CPU_REVAMPED_SKIPPED:+ }${CPU_REVAMPED_DEFAULT_POPUP_KEY}" ;;
  *) cpu_revamped_bind "${CPU_REVAMPED_S_popup_key}" "CPU details" run-shell "${CPU_REVAMPED_TOOL} popup" ;;
  esac
}

cpu_revamped_replaced() {
  printf '%s\n' "$1" | CPU_REVAMPED_PUT="${CPU_REVAMPED_JOB}" awk -v mode="${CPU_REVAMPED_S_render}" -v kinds="${CPU_REVAMPED_METRICS}" '
    BEGIN {
      command = ENVIRON["CPU_REVAMPED_PUT"]
      count = split(kinds, kind, " ")
    }
    {
      line = $0
      for (i = 1; i <= count; i++) {
        holder = "#{cpu_" kind[i] "}"
        target = (mode == "options") ? "#{E:@cpu_revamped_out_" kind[i] "}" : "#(" command " status " kind[i] ")"
        done = ""
        while ((at = index(line, holder)) > 0) {
          done = done substr(line, 1, at - 1) target
          line = substr(line, at + length(holder))
        }
        line = done line
      }
      print line
    }
  '
}

cpu_revamped_used() {
  printf '%s\n' "$1" | awk -v kinds="${CPU_REVAMPED_METRICS}" '
    BEGIN { count = split(kinds, kind, " ") }
    { text = text $0 " " }
    END {
      out = ""
      for (i = 1; i <= count; i++) {
        if (index(text, "#{cpu_" kind[i] "}") > 0 || index(text, "@cpu_revamped_out_" kind[i] "}") > 0 || index(text, " status " kind[i] ")") > 0) { out = out (out == "" ? "" : " ") kind[i] }
      }
      print out
    }
  '
}

cpu_revamped_plan_status() {
  cpu_revamped_plan_status_all=""
  for cpu_revamped_plan_status_option in status-left status-right; do
    cpu_revamped_plan_status_now=$(tmux show-option -gqv "${cpu_revamped_plan_status_option}" 2>/dev/null) || cpu_revamped_plan_status_now=""
    cpu_revamped_plan_status_all="${cpu_revamped_plan_status_all} ${cpu_revamped_plan_status_now}"
    case "${cpu_revamped_plan_status_now}" in
    *"#{cpu_"*"}"*) cpu_revamped_plan_status_new=$(cpu_revamped_replaced "${cpu_revamped_plan_status_now}") ;;
    *) continue ;;
    esac
    [ "${cpu_revamped_plan_status_new}" != "${cpu_revamped_plan_status_now}" ] || continue
    cpu_revamped_emit set-option -gq "${cpu_revamped_plan_status_option}" "${cpu_revamped_plan_status_new}"
  done
  cpu_revamped_plan_status_used=$(cpu_revamped_used "${cpu_revamped_plan_status_all}")
  [ "${cpu_revamped_plan_status_used}" = "${CPU_REVAMPED_S_published}" ] || cpu_revamped_emit set-option -gq @cpu_revamped_published "${cpu_revamped_plan_status_used}"
  CPU_REVAMPED_S_published="${cpu_revamped_plan_status_used}"
}

cpu_revamped_plan() {
  cpu_revamped_load
  cpu_revamped_version
  CPU_REVAMPED_NOTES=0
  ! cpu_revamped_version_ge "${CPU_REVAMPED_TMUX}" "${CPU_REVAMPED_NOTES_SINCE}" || CPU_REVAMPED_NOTES=1
  cpu_revamped_tools
  CPU_REVAMPED_KEYS=$(cpu_revamped_held)
  CPU_REVAMPED_PLAN="" CPU_REVAMPED_SKIPPED=""
  cpu_revamped_plan_keys
  cpu_revamped_plan_status
}

cpu_revamped_apply() {
  cpu_revamped_plan
  cpu_revamped_apply_status=0
  cpu_revamped_deliver || cpu_revamped_apply_status=1
  if [ "${CPU_REVAMPED_S_render}" = options ]; then
    revamped_ticker_start "${REVAMPED_LIB%/lib}/bin/cpu-revamped"
  else
    tmux set-option -gqu @cpu_revamped_ticker_pid 2>/dev/null || :
  fi
  return "${cpu_revamped_apply_status}"
}
