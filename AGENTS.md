# tmux-cpu-revamped

Guidance for anyone, human or agent, changing tmux-cpu-revamped. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything this plugin shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to tmux-cpu-revamped, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into [`FAMILY.md`](FAMILY.md) instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`cpu-revamped.tmux`](cpu-revamped.tmux) | The entry point TPM runs: it runs `bin/cpu-revamped apply` |
| [`bin/cpu-revamped`](bin/cpu-revamped) | The command: `apply`, `list`, `status`, `refresh`, `card`, `popup`, `daemon`, `doctor`, `version`, `help` and the menu. `apply`, `status`, `popup` and `daemon` run without loading the interface modules |
| [`lib/cpu.sh`](lib/cpu.sh) | Reading the settings and the stored sample, the readers for both systems, the figures, the placeholders with their labels and widths, the publisher's tick, the popup and the binding |
| [`lib/state.sh`](lib/state.sh) | Every global, including `CPU_REVAMPED_SETTINGS`, the table of setting names and defaults, `CPU_REVAMPED_LIVE`, the names of the options that hold the sample, and `CPU_REVAMPED_KINDS` |
| [`lib/core.sh`](lib/core.sh) | The version |
| [`lib/`](lib) | Every other file is the shared library, identical in every member |
| [`test/readers.bats`](test/readers.bats), [`test/cpu.bats`](test/cpu.bats), [`test/plan.bats`](test/plan.bats), [`test/commands.bats`](test/commands.bats) | The readers on both systems, every placeholder with its labels and widths, the binding with both render modes, the daemon and the popup, and every command, against a stand-in tmux from [`test/cpu_helpers.bash`](test/cpu_helpers.bash) that keeps options in a file, with stand-ins for `iostat`, `top`, `sysctl`, `ps`, `sensors`, `macmon`, `osx-cpu-temp` and `istats`, a `cat` that serves the files under `/proc` and the two scaling files, a `sleep` that returns at once, and fixture folders for the thermal sources |
| [`test/entrypoint.bats`](test/entrypoint.bats), [`test/keys.bats`](test/keys.bats) | The plugin on a private tmux server, with the popup key pressed through a second tmux attached to it, in both render modes; both share [`test/server_helpers.bash`](test/server_helpers.bash), whose stand-ins give the same figures on macOS and Linux |
| [`screens/`](screens) | The tapes and the recording's tmux config. `prepare.sh` copies the plugin to a neutral folder and writes stand-ins for `iostat`, `sysctl`, `macmon`, `osx-cpu-temp`, `ps` and `top` |
| [`examples/`](examples) | A status line to copy |

## Names

- Settings are the tmux options `@cpu_revamped_<setting>` listed in `CPU_REVAMPED_SETTINGS`, the long options with dashes, such as `--top-process-label`, and the environment variables `CPU_REVAMPED_<SETTING>`. `@cpu_revamped_graph_width` is both the number of samples the graph keeps and the width the graph is padded to.
- The stored sample is `@cpu_revamped_percent`, `_temp`, `_freq`, `_load`, `_load5`, `_load15`, `_count`, `_top_process`, `_governor` and `_history`, with `_percent_ts`, `_temp_ts`, `_freq_ts`, `_load_ts`, `_top_process_ts`, `_governor_ts`, `_percent_lock` and `_percent_lock_ts`. `apply` writes `@cpu_revamped_published`, the daemon `@cpu_revamped_out_<name>` and `@cpu_revamped_ticker_pid`. None of them is a setting.
- The placeholders are `#{cpu_percentage}`, `#{cpu_icon}`, `#{cpu_fg_color}`, `#{cpu_bg_color}`, `#{cpu_temp}`, `#{cpu_temp_icon}`, `#{cpu_temp_fg_color}`, `#{cpu_temp_bg_color}`, `#{cpu_freq}`, `#{cpu_load}`, `#{cpu_load5}`, `#{cpu_load15}`, `#{cpu_count}`, `#{cpu_graph}`, `#{cpu_top_process}`, `#{cpu_governor}`, `#{cpu_load_color}` and `#{cpu_alert}`; `status` names each one without the `cpu_`.
- The version constant is `CPU_REVAMPED_VERSION`.
- The command's own functions and the library's never share a name, because the command is sourced after the library and would replace it.

## Behaviour

- `apply` reads every setting and the stored sample with one `tmux display-message` call and one `env` read, reads the prefix table once, and sends the binding and the replaced status strings in one tmux call. When that call fails, it sends each command alone and `apply` exits 1.
- In `jobs` mode each placeholder in `status-left` or `status-right` becomes `#(<tool> status <name>)`, with the tool's path and every carried value quoted for a shell and every `#` and `%` doubled, since tmux reads the status line as a format and as a time format. In `options` mode it becomes `#{E:@cpu_revamped_out_<name>}`, `apply` starts the daemon, and a status refresh starts no process. A render mode other than `options` means `jobs`. A string already rewritten is not written again, and the names it uses stay in `@cpu_revamped_published`, so loading twice changes nothing.
- `status` makes one tmux read and one `date` call, and prints the stored sample at once. Only when the sample is older than `@cpu_revamped_interval`, no sample is under way, and a client is attached or `@cpu_revamped_throttle_when_detached` is not `1`, does it start one in the background through the shared cache module.
- A sample reads the load every time and the details only when due: the temperature, the clock, the load averages with the core count, the busiest process and the governor, each when a placeholder in `@cpu_revamped_published`, or the one `status` was asked for, uses it and its own time is older than `@cpu_revamped_detail_interval`. `card` reads them all. One `awk` turns the readings into every figure except the temperature, which the shell reads from the first source that answers, and everything is written in one tmux call.
- The daemon is the shared ticker: it claims `@cpu_revamped_ticker_pid`, samples and publishes every name in `@cpu_revamped_published` in one tmux call per tick, sleeps for the interval, and ends when another process holds the claim or the server is gone. While no client is attached and the throttle is on, a tick publishes the stored sample without reading the CPU. At the ticker's tick cap it starts itself again.
- `M-c` opens the popup of `@cpu_revamped_popup_width` by `@cpu_revamped_popup_height`, running `@cpu_revamped_popup_command`, else `btop`, else `htop`, else `top`. A command whose first word is not installed is named in a message, with each `#` doubled, and no popup opens. A tmux older than 3.2 gets a message that says so. `popup` returns 0 whatever the monitor returns.
- A key set to `off` binds nothing. Only the default key is skipped when someone else holds it, and `doctor` names it; a key the person names is bound whoever holds it.
- A setting `apply` got from the command line or the environment rides, as an option, on the popup key and on every status call; `CPU_REVAMPED_CARRIED` lists the ones that ride. The daemon inherits the environment of the `apply` that started it.

## Domain rules

- Linux reads `/proc/stat` twice, 0.3 seconds apart: the load is the share of the time that was not idle or iowait, rounded to a whole percent, and a read that does not move or goes backwards is 0. macOS reads `iostat -c 2 -w 1 -n 0` and takes a hundred less the idle column of its last row, else `top -l2 -n0` and a hundred less the idle share of its last `CPU usage` line. A source that is missing or unreadable gives a load of 0.
- The temperature is the first source that gives a number: the hottest CPU thermal zone, the hottest coretemp input, k10temp's Tctl or Tdie sensor, else its hottest sensor, then the first matching line of `sensors` on Linux; `macmon` on Apple Silicon, then `osx-cpu-temp`, then `istats` on a Mac. Sysfs values are millidegrees cut to whole degrees; the Mac tools round to the nearest degree, and a reading of zero is no reading.
- The clock is the first `cpu MHz` of `/proc/cpuinfo`, else `scaling_cur_freq` in kilohertz on Linux; the chip generation looked up in a table of 3200, 3400, 4000, 4200 and 4500 megahertz on Apple Silicon, where an unknown chip is 0; `hw.cpufrequency` on an Intel Mac. A clock of 0 prints nothing.
- The load averages are the first three fields of `/proc/loadavg` or of `vm.loadavg`. The core count is the number of `processor` lines of `/proc/cpuinfo` or `hw.ncpu`. The governor is `scaling_governor` of the first core and is empty on macOS.
- The busiest process is the row of `ps axo pcpu=,comm=` with the most CPU, stored as its whole percent and its name cut to the part after the last slash when it starts with one. The name comes from outside, so each `#` in it is doubled when a placeholder prints it; `card` prints it as read. A `ps` that lists only idle processes leaves it empty.
- Each sample joins `@cpu_revamped_history`, which keeps the newest `@cpu_revamped_graph_width` samples; zero or junk there means 20. The graph draws one of eight bars per sample at the sample times eight over 101, and takes a sample that is no number for 0.
- The tier of the load is high from `@cpu_revamped_high_thresh`, medium from `@cpu_revamped_medium_thresh`, else low, and the icon and the colours follow it, with the low tier printed while no sample is stored. The tier of the temperature follows `@cpu_revamped_temp_high_thresh` and `@cpu_revamped_temp_medium_thresh` in degrees Celsius. `#{cpu_load_color}` is the foreground style of the tier whose ratio the one minute load average per core reaches, 1.0 for high and 0.7 for medium, counting one core when the count is not a positive number. `#{cpu_alert}` prints `@cpu_revamped_alert_icon` while the load or the temperature is at its high threshold.
- The temperature is printed in Celsius, or in Fahrenheit rounded to the nearest degree when the unit is `F`; a unit that is neither keeps the Celsius value under its own name. The default format is `%s`, the degree sign and the unit.
- A label is printed only before a value. In the `nerd` set each labelled metric gets its glyph unless its own label is set; an empty tmux option means its default, so a label set to nothing keeps the glyph. The colour, icon and alert placeholders are never labelled or padded.
- A value is padded on the left to its own `_width`, else, with `@cpu_revamped_fixed_width` at `on`, to its natural width: 4 for the load, 5 for the temperature and the three load averages, 7 for the clock and 3 for the core count. Width counts characters, and a longer value is never cut.
- An argument that ends in `;` is sent as `\;`: tmux reads a bare trailing semicolon in an argument as a command separator. The command list keeps an empty argument as the marker in `CPU_REVAMPED_EMPTY`; only an empty line ends a command.

## Release

- `CPU_REVAMPED_VERSION` in [`lib/core.sh`](lib/core.sh) holds the version. Nobody edits it by hand.
- After a green `ci` run on `main`, [`release.yml`](.github/workflows/release.yml) runs semantic-release: a `feat` or `fix` since the last tag publishes a release, [`set-version.sh`](.github/scripts/set-version.sh) stamps the constant, and the notes go into [`CHANGELOG.md`](CHANGELOG.md).

## Gaps against FAMILY.md

As of 2026-11-19:

- `#{cpu_governor}` works on Linux only, from `scaling_governor`: macOS has no governor. No screen records it, because the screens are recorded on macOS.
- No `@cpu_revamped_notify` for throttling yet.
- A `#` in `@cpu_revamped_popup_command` reaches the popup's command as typed, where FAMILY.md has a popup's command carry none: the command is the person's own shell line, and rewriting its `#` would change what a quoted `#` means.
