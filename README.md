<div align="center">

# tmux-cpu-revamped

<strong>CPU load, temperature, and frequency in your tmux status bar, without ever blocking the render.</strong>

English &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-cpu-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-cpu-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-cpu-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-cpu-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-cpu-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-cpu-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-cpu-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>Quick start</strong></a> &nbsp;|&nbsp;
  <a href="#usage">Usage</a> &nbsp;|&nbsp;
  <a href="#how-it-works">How it works</a> &nbsp;|&nbsp;
  <a href="#screens">Screens</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="cpu-revamped showing the load coloured by tier with the temperature, opening the monitor popup, switching to Nerd Font labels, the graph and the options render mode" width="800">
</p>

```console
$ cpu-revamped refresh
Refreshed. 31% of the CPU is busy.
$ cpu-revamped status percentage
31%
```

**22** placeholders, **2** render modes, macOS and Linux, tmux **3.2** or later.

---

## Quick start

### Prerequisites

| Tool | Version | Used for |
|:-----|:--------|:---------|
| tmux | 3.2 or later | the family floor, and the popup |
| btop, htop | optional | the monitor the popup opens; without them it runs `top` |
| gum | optional | the menu, tables and colours of `cpu-revamped`; without it every command prints plain text |

It runs on Linux and macOS with BSD, GNU, uutils or BusyBox tools. Each figure comes from something the OS ships:

| Figure | Linux | macOS Intel | macOS Apple Silicon |
|:-------|:------|:------------|:--------------------|
| Load | `/proc/stat`, two reads 0.3 s apart | `iostat`, then `top` | `iostat`, then `top` |
| Temperature | thermal zones, then coretemp, then k10temp, then `sensors` | `osx-cpu-temp`, then `istats` | `macmon` |
| Clock | `/proc/cpuinfo`, then `scaling_cur_freq` | `sysctl hw.cpufrequency` | a table of the chip's clock by generation |
| Load averages | `/proc/loadavg` | `sysctl vm.loadavg` | `sysctl vm.loadavg` |
| Core count | `/proc/cpuinfo` | `sysctl hw.ncpu` | `sysctl hw.ncpu` |
| Governor | `scaling_governor` | none | none |
| Busiest process | `ps` | `ps` | `ps` |
| Per-core load | `cpuN` lines of `/proc/stat`, kept as counters | `osascript -l JavaScript` calling `host_processor_info`, then `macmon` | the same |
| Throttling | `thermal_throttle/*_throttle_count` in sysfs | `pmset -g therm` | `pmset -g therm` |

| Platform | Temperature helper |
|:---------|:-------------------|
| macOS Apple Silicon | `brew install macmon`, which reads the sensors without sudo |
| macOS Intel | `brew install osx-cpu-temp`, or `gem install iStats` |
| Linux | none on most machines; `lm-sensors` for the `sensors` fallback |

A missing source leaves its placeholder empty, and `cpu-revamped doctor` names it. `osx-cpu-temp` and `istats` return `0.0` on Apple Silicon, which counts as no reading.

### Install

With [TPM](https://github.com/tmux-plugins/tpm), add the plugin to `~/.tmux.conf` and press `prefix + I`:

```tmux
set -g @plugin 'tmux-revamped/tmux-cpu-revamped'
```

To install by hand, clone the repository and run the entrypoint from `~/.tmux.conf`:

```bash
git clone https://github.com/tmux-revamped/tmux-cpu-revamped ~/.tmux/plugins/tmux-cpu-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-cpu-revamped/cpu-revamped.tmux
```

Set `status-left` or `status-right` before the plugin loads. The plugin replaces the placeholders it finds there once, at load time.

`make install` in the clone also puts `cpu-revamped` in `~/.local/bin`, with its man page and completions under `~/.local/share`.

### Verify

```bash
~/.tmux/plugins/tmux-cpu-revamped/bin/cpu-revamped doctor
```

## Usage

The plugin shows how busy the CPU is, with its temperature, clock, load averages, core count, a graph of the recent load, the busiest process and, on Linux, the governor. The status line prints a value tmux already holds, and a background sample refreshes it.

| Placeholder | Output |
|:------------|:-------|
| `#{cpu_percentage}` | CPU load, for example `42%` |
| `#{cpu_icon}` | Tier icon for the load |
| `#{cpu_fg_color}` | Foreground style for the load tier |
| `#{cpu_bg_color}` | Background style for the load tier |
| `#{cpu_temp}` | Temperature in whole degrees, for example `54°C` |
| `#{cpu_temp_icon}` | Tier icon for the temperature |
| `#{cpu_temp_fg_color}` | Foreground style for the temperature tier |
| `#{cpu_temp_bg_color}` | Background style for the temperature tier |
| `#{cpu_freq}` | Clock in megahertz, for example `4000MHz` |
| `#{cpu_load}` | One minute load average, for example `1.23` |
| `#{cpu_load5}` | Five minute load average |
| `#{cpu_load15}` | Fifteen minute load average |
| `#{cpu_count}` | Logical CPUs |
| `#{cpu_graph}` | Sparkline of recent load samples, for example `▁▂▄▆█` |
| `#{cpu_top_process}` | The process using the most CPU, for example `node 42%` |
| `#{cpu_governor}` | The Linux frequency governor, for example `performance`; empty on macOS |
| `#{cpu_load_color}` | Foreground style of the load tier judged by the one minute load average per core |
| `#{cpu_alert}` | `@cpu_revamped_alert_icon` while the load or the temperature is at its high threshold, empty otherwise |
| `#{cpu_cores}` | One bar per core, for example `▂▄▇█`; empty until a second sample |
| `#{cpu_sep_left}` | The left powerline arrow in the colour of the load tier |
| `#{cpu_sep_right}` | The right powerline arrow in the colour of the load tier |
| `#{cpu_throttle}` | `@cpu_revamped_throttle_icon` while the CPU is held back, empty otherwise |

Put placeholders in the status line:

```tmux
set -g @cpu_revamped_low_fg_color '#[fg=green]'
set -g @cpu_revamped_medium_fg_color '#[fg=yellow]'
set -g @cpu_revamped_high_fg_color '#[fg=red]'

set -g status-right '#{cpu_fg_color}#{cpu_icon} #{cpu_percentage}#[default] #{cpu_temp} '
```

The same example, with a few more options, is in [examples/status-right.tmux.conf](examples/status-right.tmux.conf).

### Labels and widths

`@cpu_revamped_<metric>_label` prints an icon or word before one metric, only when its value is not empty. `@cpu_revamped_icons` set to `nerd` labels every metric below with a Nerd Font glyph. A metric's own label wins over the set, and a label set to nothing means the default, so the glyph stays. The default, `ascii`, adds no labels.

| Metric | `nerd` glyph |
|:-------|:-------------|
| `percentage` | U+F029A |
| `temp` | U+F050F |
| `freq` | U+F04C5 |
| `load` | U+F05D1 |
| `load5` | U+F05D1 |
| `load15` | U+F05D1 |
| `count` | U+F061A |
| `graph` | U+F07B1 |
| `top_process` | U+F08C6 |
| `governor` | U+F062E |
| `cores` | U+F0EE0 |

`@cpu_revamped_fixed_width` set to `on` pads each figure on the left to its natural width, four characters for the load, five for the temperature and the load averages, seven for the clock and three for the core count, so a change from `9%` to `42%` does not shift the rest of the line. `@cpu_revamped_<metric>_width` sets one metric's width and wins over the fixed width. A longer value is never cut.

### Per-core bars, separators and throttling

`#{cpu_cores}` prints one bar per core, drawn like `#{cpu_graph}`, each bar the share of that core's time spent busy since the previous sample. The first sample has no earlier counters and prints nothing, and two samples in the same second keep the previous bars. Linux keeps the counters of the `cpuN` lines of `/proc/stat` in an option. macOS reads `host_processor_info` through JXA, run by `osascript`, and falls back to `macmon`; a Mac with neither shows no bars, and `cpu-revamped doctor` says so.

`#{cpu_sep_left}` and `#{cpu_sep_right}` print the powerline arrows `@cpu_revamped_sep_left` and `@cpu_revamped_sep_right`. Each arrow takes the background of the load tier as its foreground, over `@cpu_revamped_sep_bg`, so it follows the segment's colour as the tier changes. A tier with no background style prints the arrow unstyled.

```tmux
set -g @cpu_revamped_low_bg_color '#[bg=#313244]'
set -g @cpu_revamped_high_bg_color '#[bg=#585b70]'
set -g status-right '#{cpu_sep_left}#{cpu_bg_color}#{cpu_percentage} #{cpu_cores}#[default]#{cpu_sep_right}'
```

`#{cpu_throttle}` prints `@cpu_revamped_throttle_icon` while the CPU is held back. `@cpu_revamped_notify` set to `1` sends one desktop notification when throttling starts, and the next only after it ended. Notifications need `#{cpu_throttle}` in the status line, because only a placeholder in use makes the plugin read the throttling state, which it does every `@cpu_revamped_detail_interval` seconds.

An icon, a label or a text set to `off` prints nothing: the tier icons, `@cpu_revamped_alert_icon`, `@cpu_revamped_throttle_icon`, both separators and every `@cpu_revamped_<metric>_label`. An empty option means its default, so `off` is the one way to hide them.

### Render mode

By default each placeholder becomes a `#()` call, which tmux reruns on status redraws. With `@cpu_revamped_render` set to `options`, each placeholder becomes an option read such as `#{E:@cpu_revamped_out_percentage}`. One background process per server then samples every `@cpu_revamped_interval` seconds and writes all values in one tmux call, so they change together.

```tmux
set -g @cpu_revamped_render 'options'
set -g @cpu_revamped_fixed_width 'on'
```

### Tier colors

The tier styles are empty by default, so `#{cpu_fg_color}`, `#{cpu_bg_color}`, `#{cpu_temp_fg_color}`, `#{cpu_temp_bg_color}` and `#{cpu_load_color}` print nothing until you set them. These palettes map low to green, medium to yellow and high to red:

| Theme | Low | Medium | High |
|:------|:----|:-------|:-----|
| Catppuccin Mocha | `#a6e3a1` | `#f9e2af` | `#f38ba8` |
| Dracula | `#50fa7b` | `#f1fa8c` | `#ff5555` |
| Nord | `#a3be8c` | `#ebcb8b` | `#bf616a` |
| Gruvbox Dark | `#b8bb26` | `#fabd2f` | `#fb4934` |
| Tokyo Night | `#9ece6a` | `#e0af68` | `#f7768e` |
| Solarized Dark | `#859900` | `#b58900` | `#dc322f` |

Each value goes in a style, such as `set -g @cpu_revamped_low_fg_color '#[fg=#a6e3a1]'`. The temperature tiers take the same styles under `@cpu_revamped_temp_<tier>_fg_color`.

| Command | What it does |
|:--------|:-------------|
| `cpu-revamped apply` | Binds the popup key and fills the placeholders now; the entry point runs it when tmux loads the plugin |
| `cpu-revamped list` | Prints every command `apply` would send and changes nothing; `--json` prints one object |
| `cpu-revamped status NAME` | Prints one placeholder, such as `percentage`, `temp` or `graph`; the status line runs it |
| `cpu-revamped refresh` | Samples the CPU now and says how much of it is busy |
| `cpu-revamped card` | Reads everything now and prints one row per figure |
| `cpu-revamped popup` | Opens a CPU monitor in a tmux popup: the popup command, else btop, else htop, else top; the popup key runs it |
| `cpu-revamped daemon` | Publishes the placeholders on every tick, for the `options` render mode; `apply` starts it |
| `cpu-revamped doctor` | One row per dependency: each tool or file a figure comes from, the monitor the popup opens, and any key left alone |
| `cpu-revamped version` | The version, then the tmux version |
| `cpu-revamped help` | The help page; `man cpu-revamped` documents the same commands and settings |
| `cpu-revamped` | On a terminal, a menu |

## Configuration

Every option is also a command option with dashes, such as `--interval 2`, and an environment variable, such as `CPU_REVAMPED_INTERVAL`; the command line wins over the environment, and the environment over the tmux option. An empty tmux option means its default. `doctor` names any setting that holds a value the plugin does not know. One given to `apply` rides on the popup key and on every status call.

### Sampling

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@cpu_revamped_interval` | `5` | Seconds a sample of the load stays fresh |
| `@cpu_revamped_detail_interval` | `60` | Seconds the temperature, the clock, the load averages, the core count, the busiest process and the governor stay fresh |
| `@cpu_revamped_throttle_when_detached` | `0` | `1` stops sampling while no client is attached; the status line keeps the last sample |
| `@cpu_revamped_render` | `jobs` | `options` reads published options instead of running `#()` calls; any other value means `jobs` |
| `@cpu_revamped_graph_width` | `20` | Samples kept for `#{cpu_graph}` |

### Tiers and alerts

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@cpu_revamped_medium_thresh` | `30` | Load percent at which the tier becomes medium |
| `@cpu_revamped_high_thresh` | `80` | Load percent at which the tier becomes high, and at which `#{cpu_alert}` prints |
| `@cpu_revamped_low_icon` | `▰▱▱` | Icon for the low load tier |
| `@cpu_revamped_medium_icon` | `▰▰▱` | Icon for the medium load tier |
| `@cpu_revamped_high_icon` | `▰▰▰` | Icon for the high load tier |
| `@cpu_revamped_low_fg_color` | empty | Foreground style for the low load tier, such as `#[fg=green]` |
| `@cpu_revamped_medium_fg_color` | empty | Foreground style for the medium load tier |
| `@cpu_revamped_high_fg_color` | empty | Foreground style for the high load tier |
| `@cpu_revamped_low_bg_color` | empty | Background style for the low load tier |
| `@cpu_revamped_medium_bg_color` | empty | Background style for the medium load tier |
| `@cpu_revamped_high_bg_color` | empty | Background style for the high load tier |
| `@cpu_revamped_temp_medium_thresh` | `65` | Degrees Celsius at which the temperature tier becomes medium |
| `@cpu_revamped_temp_high_thresh` | `80` | Degrees Celsius at which the temperature tier becomes high, and at which `#{cpu_alert}` prints |
| `@cpu_revamped_temp_low_icon` | empty | Icon for the low temperature tier |
| `@cpu_revamped_temp_medium_icon` | empty | Icon for the medium temperature tier |
| `@cpu_revamped_temp_high_icon` | empty | Icon for the high temperature tier |
| `@cpu_revamped_temp_low_fg_color` | empty | Foreground style for the low temperature tier |
| `@cpu_revamped_temp_medium_fg_color` | empty | Foreground style for the medium temperature tier |
| `@cpu_revamped_temp_high_fg_color` | empty | Foreground style for the high temperature tier |
| `@cpu_revamped_temp_low_bg_color` | empty | Background style for the low temperature tier |
| `@cpu_revamped_temp_medium_bg_color` | empty | Background style for the medium temperature tier |
| `@cpu_revamped_temp_high_bg_color` | empty | Background style for the high temperature tier |
| `@cpu_revamped_load_medium_ratio` | `0.7` | Load average per core at which `#{cpu_load_color}` becomes medium |
| `@cpu_revamped_load_high_ratio` | `1.0` | Load average per core at which `#{cpu_load_color}` becomes high |
| `@cpu_revamped_alert_icon` | `!` | What `#{cpu_alert}` prints |

### Powerline and throttling

| Option | Default | Meaning |
|:--------|:--------|:--------|
| `@cpu_revamped_sep_left` | U+E0B2 | What `#{cpu_sep_left}` prints; `off` prints nothing |
| `@cpu_revamped_sep_right` | U+E0B0 | What `#{cpu_sep_right}` prints; `off` prints nothing |
| `@cpu_revamped_sep_bg` | `default` | Background colour behind both arrows |
| `@cpu_revamped_throttle_icon` | `throttled` | What `#{cpu_throttle}` prints while the CPU is held back; `off` prints nothing |
| `@cpu_revamped_notify` | `0` | `1` sends a desktop notification when throttling starts, once per episode |

### Formats and labels

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@cpu_revamped_temp_unit` | `C` | `C` or `F` |
| `@cpu_revamped_percentage_format` | `%s%%` | printf format for the load |
| `@cpu_revamped_temp_format` | `%s°C` | printf format for the temperature; the unit follows `@cpu_revamped_temp_unit` |
| `@cpu_revamped_freq_format` | `%sMHz` | printf format for the clock |
| `@cpu_revamped_load_format` | `%s` | printf format for the three load averages |
| `@cpu_revamped_icons` | `ascii` | `nerd` labels every value with a Nerd Font glyph |
| `@cpu_revamped_<metric>_label` | empty | Text printed before one value, only when the value is not empty |
| `@cpu_revamped_fixed_width` | `off` | `on` pads each figure to its natural width, so a change from `9%` to `42%` does not shift the status line |
| `@cpu_revamped_<metric>_width` | empty | Pad one value to this many characters. A longer value is never cut |

A metric that takes a label and a width is `percentage`, `temp`, `freq`, `load`, `load5`, `load15`, `count`, `graph`, `cores`, `top_process` or `governor`.

### Popup

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@cpu_revamped_popup_key` | `M-c` | Prefix key that opens the detail popup. `off` binds nothing |
| `@cpu_revamped_popup_command` | btop, then htop, then top | What the popup runs, with its arguments; one that is not installed is named in a message |
| `@cpu_revamped_popup_width` | `80%` | Popup width |
| `@cpu_revamped_popup_height` | `80%` | Popup height |

### Internal state

The plugin writes these options itself. Do not set them.

| Option | Holds |
|:-------|:------|
| `@cpu_revamped_published` | The metrics the status line uses, recorded at load so options mode writes only those |
| `@cpu_revamped_history` | The recent load samples behind `#{cpu_graph}` |
| `@cpu_revamped_cores`, `_cores_stat`, `_throttle`, `_throttle_count`, `_notified` | The per-core shares and counters, the throttling flag and its counts, and whether the current episode was notified |
| `@cpu_revamped_out_<metric>` | The rendered value of each metric in options mode |
| `@cpu_revamped_ticker_pid` | The process id of the options-mode background process |
| `@cpu_revamped_percent` and the other figures, `_ts`, `_lock` | The stored sample, the time of each reading and the refresh lock |

## Key bindings

| Key | Action | Default |
|:----|:-------|:--------|
| `prefix + M-c` | Opens a CPU monitor in a popup: your command, else btop, else htop, else top | Bound |

`@cpu_revamped_popup_key` names another key, and `off` binds none. The default key is left alone when something else already holds it, and `cpu-revamped doctor` says so.

<a id="how-it-works"></a>

## How it works

[`cpu-revamped.tmux`](cpu-revamped.tmux) runs once when tmux loads the plugin. It records which metrics `status-left` and `status-right` use in `@cpu_revamped_published`, then replaces each placeholder with a call to [`bin/cpu-revamped`](bin/cpu-revamped) or, in `options` mode, with an option read and starts the background process.

In the default mode, each `#()` call returns the stored sample at once. When the sample is older than its interval, the call starts a refresh in the background and takes a lock, so only one refresh runs at a time. On Linux the load is the busy share of two reads of `/proc/stat` taken 0.3 seconds apart, iowait counted as idle. On macOS it is a hundred less the idle share of `iostat`, or of `top` when `iostat` is missing. One `awk` turns the readings into every figure, and one tmux call stores them. The temperature, the clock, the load averages, the busiest process and the governor cost more reads, so each runs only for a placeholder the status line uses, every `@cpu_revamped_detail_interval` seconds.

The temperature comes from the first source that answers: thermal zones, coretemp, k10temp and `sensors` on Linux; `macmon` on Apple Silicon, then `osx-cpu-temp` and `istats` on a Mac. The name of the busiest process comes from `ps`, which any user controls, so every `#` in it is doubled before it reaches the status line. The readers, the sampling and the formatting live in [`lib/cpu.sh`](lib/cpu.sh), and the settings table in [`lib/state.sh`](lib/state.sh).

<a id="screens"></a>

## Screens

<details>
<summary>Every screen, recorded inside a real tmux with <code>make screens</code>, with each key on the status line</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="cpu-revamped: The load with its tier icon and colour, the temperature, the clock, the load average and the alert"><br><sub>The load with its tier icon and colour, the temperature, the clock, the load average and the alert, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/popup.png" alt="cpu-revamped: prefix M-c opens a CPU monitor in a popup"><br><sub><code>prefix M-c</code> opens a CPU monitor in a popup, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/icons.png" alt="cpu-revamped: @cpu_revamped_icons set to nerd labels every metric with a glyph"><br><sub><code>@cpu_revamped_icons</code> set to <code>nerd</code> labels every metric with a glyph, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/graph.png" alt="cpu-revamped: The graph, the load and the busiest process"><br><sub>The graph, the load and the busiest process, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="cpu-revamped: In the options render mode each placeholder reads a tmux option"><br><sub>In the <code>options</code> render mode each placeholder reads a tmux option, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/card.png" alt="cpu-revamped: card prints every figure"><br><sub><code>card</code> prints every figure, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/temp.png" alt="cpu-revamped: The temperature with its tier icon and colour, and the alert"><br><sub>The temperature with its tier icon and colour, and the alert, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/unit.png" alt="cpu-revamped: @cpu_revamped_temp_unit set to F"><br><sub><code>@cpu_revamped_temp_unit</code> set to <code>F</code>, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/load.png" alt="cpu-revamped: The three load averages, the core count and the load colour"><br><sub>The three load averages, the core count and the load colour, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/load-format.png" alt="cpu-revamped: @cpu_revamped_load_format shapes the load averages"><br><sub><code>@cpu_revamped_load_format</code> shapes the load averages, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/ratios.png" alt="cpu-revamped: @cpu_revamped_load_medium_ratio and @cpu_revamped_load_high_ratio move the load colour"><br><sub><code>@cpu_revamped_load_medium_ratio</code> and <code>@cpu_revamped_load_high_ratio</code> move the load colour, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/clock.png" alt="cpu-revamped: The clock, the governor and the busiest process"><br><sub>The clock, the governor and the busiest process, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/freq-format.png" alt="cpu-revamped: @cpu_revamped_freq_format shapes the clock"><br><sub><code>@cpu_revamped_freq_format</code> shapes the clock, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/format.png" alt="cpu-revamped: @cpu_revamped_percentage_format shapes the load percent"><br><sub><code>@cpu_revamped_percentage_format</code> shapes the load percent, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/fixed.png" alt="cpu-revamped: @cpu_revamped_fixed_width pads each figure to its natural width"><br><sub><code>@cpu_revamped_fixed_width</code> pads each figure to its natural width, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/width.png" alt="cpu-revamped: @cpu_revamped_count_width pads one metric to its own width"><br><sub><code>@cpu_revamped_count_width</code> pads one metric to its own width, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/labels.png" alt="cpu-revamped: A label of its own before one metric"><br><sub>A label of its own before one metric, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/tiers.png" alt="cpu-revamped: @cpu_revamped_medium_thresh and @cpu_revamped_high_thresh move the tiers"><br><sub><code>@cpu_revamped_medium_thresh</code> and <code>@cpu_revamped_high_thresh</code> move the tiers, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/graph-width.png" alt="cpu-revamped: @cpu_revamped_graph_width sets how many samples the graph keeps"><br><sub><code>@cpu_revamped_graph_width</code> sets how many samples the graph keeps, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/popup-key.png" alt="cpu-revamped: @cpu_revamped_popup_key names another key for the popup"><br><sub><code>@cpu_revamped_popup_key</code> names another key for the popup, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/popup-command.png" alt="cpu-revamped: @cpu_revamped_popup_command names what the popup runs, and its size"><br><sub><code>@cpu_revamped_popup_command</code> names what the popup runs, and its size, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/status-command.png" alt="cpu-revamped: status percentage and status graph print one placeholder each"><br><sub><code>status percentage</code> and <code>status graph</code> print one placeholder each, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/refresh.png" alt="cpu-revamped: refresh samples the CPU now"><br><sub><code>refresh</code> samples the CPU now, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="cpu-revamped: list prints every binding"><br><sub><code>list</code> prints every binding, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/json.png" alt="cpu-revamped: list --json prints the same plan as one object"><br><sub><code>list --json</code> prints the same plan as one object, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="cpu-revamped: doctor"><br><sub><code>doctor</code>, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu.png" alt="cpu-revamped: The menu"><br><sub>The menu, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/menu-card.png" alt="cpu-revamped: The card from the menu"><br><sub>The card from the menu, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/accent.png" alt="cpu-revamped: An accent from CPU_REVAMPED_ACCENT"><br><sub>An accent from <code>CPU_REVAMPED_ACCENT</code>, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="cpu-revamped: The menu without gum"><br><sub>The menu without gum, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="cpu-revamped: doctor from the menu, without gum"><br><sub><code>doctor</code> from the menu, without gum, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-card.png" alt="cpu-revamped: card without gum"><br><sub><code>card</code> without gum, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/version.png" alt="cpu-revamped: The version"><br><sub>The version, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/error.png" alt="cpu-revamped: An unknown command"><br><sub>An unknown command, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="cpu-revamped: The header in six themes"><br><sub>The header in six themes, from <code>themes.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="cpu-revamped: The help page"><br><sub>The help page, from <code>help.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/cores.png" alt="cpu-revamped: #{cpu_cores} draws one bar per core"><br><sub><code>#{cpu_cores}</code> draws one bar per core, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/separators.png" alt="cpu-revamped: #{cpu_sep_left} and #{cpu_sep_right} take the colour of the load tier"><br><sub><code>#{cpu_sep_left}</code> and <code>#{cpu_sep_right}</code> take the colour of the load tier, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/throttle.png" alt="cpu-revamped: #{cpu_throttle} shows while the CPU is held back"><br><sub><code>#{cpu_throttle}</code> shows while the CPU is held back, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/off.png" alt="cpu-revamped: A label, an icon or a text set to off prints nothing"><br><sub>A label, an icon or a text set to <code>off</code> prints nothing, from <code>features.tape</code></sub></td>
</tr>
</table>

The recordings run the real plugin and tmux. Small scripts stand in for `iostat`, `sysctl`, `macmon`, `osx-cpu-temp`, `pmset`, `osascript`, `ps` and `top`, so the figures on screen are theirs. The recordings run on macOS, which has no governor, so `#{cpu_governor}` shows nothing there.

</details>

## Portability

The plugin is POSIX `sh`. CI runs every suite on each row below.

| Shell | Status |
|:------|:-------|
| `dash`, `/bin/sh` on macOS | Supported |
| `bash` 3.2 and 5.x, the system's `zsh` and Homebrew's | Supported |

| System | Status |
|:-------|:-------|
| macOS | Tahoe on Apple Silicon and Intel, with the tools it ships, Homebrew's GNU tools and Homebrew's uutils |
| Linux | Ubuntu 26.04 on x86_64 and arm64, with GNU coreutils, uutils and BusyBox |

## Development

| Command | What it runs |
|:--------|:-------------|
| `make fmt` | shfmt `-i 2` on every script |
| `make lint` | shfmt, ShellCheck, mandoc, yamllint and actionlint, at zero findings |
| `make test` | The bats suites under the system `sh` |
| `make test-all` | The suites under every installed shell, both builds of bash and zsh on macOS |
| `make test-linux` | The suites in an Ubuntu container |
| `make coverage` | bashcov on this Mac and in the Ubuntu container, merged and gated at 100 percent |
| `make screens` | The screens above, recorded from the real plugin inside tmux with VHS, on macOS |
| `make install` | The command, its man page and completions under `PREFIX` |

On macOS, `brew bundle` installs every tool these targets call, from the [`Brewfile`](Brewfile).

Commits follow the conventional commit format and go straight to `main`. After a green `ci` run on `main`, `release.yml` runs semantic-release: every `feat` or `fix` since the last tag publishes a release, stamps the version constant and adds the notes to [`CHANGELOG.md`](CHANGELOG.md).

## License

[MIT](LICENSE), copyright Gustavo Franco.

<!-- family:begin -->

## The tmux-revamped family

This plugin is one member of the tmux-revamped family. Every member carries the same contract in [`FAMILY.md`](FAMILY.md) and the same shared library, and they are built to be installed together: no member claims a key or a tmux option that another member claims.

A defect found in one member is hunted across all of them before the fix is called done.

| Member | What it does |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | Edit your tmux config, save, and watch it reload itself, no key, no command |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | Battery status for your tmux status bar, without ever blocking the status render |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | Every connected Bluetooth device and its battery in your tmux status bar, without blocking the render |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | **this plugin**, CPU load, temperature, and frequency in your tmux status bar, without ever blocking the render |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | Disk usage for your tmux status bar, without ever blocking the status render |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | Pick a URL, path, hash or any other token off the screen with fzf and type it at the cursor, in pure shell |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | Switch to, kill, rename or create tmux sessions, windows and panes from fzf pickers in a popup |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | Show the active pane's git branch, changes and provider counts in the tmux status bar without blocking it |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | GPU load, temperature, clock, power and memory in the tmux status bar, from NVIDIA, AMD, Intel and Apple GPUs |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | Current Kubernetes context and namespace in the tmux status bar, parsed from kubeconfig without kubectl |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Open any terminal app in a tmux popup, window or split from one menu, starting at the project root |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Pane and window management bindings for tmux, version aware, vim friendly, every prefix key can be disabled |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | Save every tmux session, window and pane, auto-save on a timer, and restore it all after a reboot |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | The starting point for a tmux-revamped plugin: shared library, bats harness and CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in the tmux status bar that keeps all of its state in tmux options, with no temp files |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM, swap and memory pressure in the tmux status bar, sampled in the background so the render never waits |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | Drag a window tab along the tmux status bar with the mouse to move that window |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Send the mouse wheel to apps that scroll themselves and into tmux copy-mode everywhere else |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults, gated by tmux version and terminal, that leave the options you set alone |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | Tiling window management for tmux: eight layouts including BSP dwindle and spiral, with layout undo |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local and world clocks for the tmux status bar, colored by time of day, with countdowns and a DST warning |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather for the tmux status bar from wttr.in, fetched in the background so the status line never waits |

<!-- family:end -->
