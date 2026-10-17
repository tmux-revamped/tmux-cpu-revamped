<div align="center">

# tmux-cpu-revamped

<strong>CPU load, temperature, and frequency in your tmux status bar, without ever blocking the render.</strong>

English &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-cpu-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-cpu-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.3.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">What it does</a> &nbsp;|&nbsp;
  <a href="#requirements">Requirements</a> &nbsp;|&nbsp;
  <a href="#installation">Installation</a> &nbsp;|&nbsp;
  <a href="#usage">Usage</a> &nbsp;|&nbsp;
  <a href="#configuration">Configuration</a> &nbsp;|&nbsp;
  <a href="#key-bindings">Key bindings</a> &nbsp;|&nbsp;
  <a href="#how-it-works">How it works</a>
</p>

</div>

**18** placeholders. **2** render modes. **7** temperature sources across Linux and macOS. CI runs the suite on **10** Linux and macOS toolchain combinations.

---

## What it does

The plugin replaces `#{cpu_*}` placeholders in `status-left` and `status-right` with CPU load, temperature, clock, load averages, core count, a load history, the busiest process and the Linux governor. Every placeholder reads a value cached in a tmux option. Sampling runs in the background, so the status line never waits for it. Nothing is written to disk.

It also opens a detail popup running `btop` on `prefix + M-c`.

## Requirements

| Tool | Version | Needed for |
|:-----|:--------|:-----------|
| tmux | 3.2 or later | `display-popup` for the detail popup |
| bash | 3.2 or later | every script, including macOS `/bin/bash` |
| `btop` | any | optional, the default popup command |
| a temperature helper | any | optional, see the table below |

| Value | Linux, x86_64 and arm64 | macOS Intel | macOS Apple Silicon |
|:------|:------------------------|:------------|:--------------------|
| Load | `/proc/stat`, two reads 0.3 s apart | `iostat`, then `top` | `iostat`, then `top` |
| Temperature | thermal zones, then coretemp, then k10temp, then `sensors` | `osx-cpu-temp`, then `istats` | `macmon` |
| Clock | `/proc/cpuinfo`, then `scaling_cur_freq` | `sysctl hw.cpufrequency` | a per-chip maximum clock table |
| Load averages and core count | `/proc/loadavg`, `/proc/cpuinfo` | `sysctl` | `sysctl` |
| Governor | `scaling_governor` | none | none |

| Platform | Temperature helper |
|:---------|:-------------------|
| macOS Apple Silicon | `brew install macmon`, which reads the sensors without sudo |
| macOS Intel | `brew install osx-cpu-temp`, or `gem install iStats` |
| Linux | none on most machines; `lm-sensors` for the `sensors` fallback |

A value the host has no source for renders empty. `osx-cpu-temp` and `istats` return `0.0` on Apple Silicon, which the plugin treats as no reading. Run `src/cpu.sh doctor` to see what this host provides.

## Installation

### With TPM

Add the plugin and a placeholder to `~/.tmux.conf`, then press `prefix + I`:

```tmux
set -g @plugin 'tmux-revamped/tmux-cpu-revamped'
set -g status-right '#{cpu_icon} #{cpu_percentage} #{cpu_temp}'
```

### Manual

```bash
git clone https://github.com/tmux-revamped/tmux-cpu-revamped ~/.tmux/plugins/tmux-cpu-revamped
```

Then add this line to `~/.tmux.conf`, after the lines that set `status-left` and `status-right`, and reload tmux:

```tmux
run-shell ~/.tmux/plugins/tmux-cpu-revamped/cpu-revamped.tmux
```

## Usage

Put placeholders in `status-left` or `status-right`. The plugin replaces them when it loads. [`examples/status-right.tmux.conf`](examples/status-right.tmux.conf) has a complete example.

```tmux
set -g status-right '#{cpu_graph} #{cpu_load_color}#{cpu_icon} #{cpu_percentage}#[default] #{cpu_temp} #{cpu_alert}'
```

| Placeholder | Output |
|:------------|:-------|
| `#{cpu_percentage}` | CPU load, for example `42%` |
| `#{cpu_icon}` | the icon of the current load tier |
| `#{cpu_fg_color}`, `#{cpu_bg_color}` | the colors of the current load tier |
| `#{cpu_temp}` | temperature in whole degrees, for example `54°C` |
| `#{cpu_temp_icon}` | the icon of the current temperature tier |
| `#{cpu_temp_fg_color}`, `#{cpu_temp_bg_color}` | the colors of the current temperature tier |
| `#{cpu_freq}` | clock, for example `4000MHz` |
| `#{cpu_load}`, `#{cpu_load5}`, `#{cpu_load15}` | the 1, 5 and 15 minute load averages, for example `1.23` |
| `#{cpu_count}` | logical CPUs |
| `#{cpu_graph}` | recent load readings, for example `▁▂▄▆█` |
| `#{cpu_top_process}` | the busiest process, for example `node 42%` |
| `#{cpu_governor}` | the Linux frequency governor, for example `performance` |
| `#{cpu_load_color}` | the load tier foreground color, judged by the 1 minute load per core |
| `#{cpu_alert}` | `@cpu_revamped_alert_icon` when load or temperature reaches its high threshold, empty otherwise |

## Configuration

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@cpu_revamped_interval` | `5` | seconds the load reading stays fresh |
| `@cpu_revamped_detail_interval` | `60` | seconds the temperature, clock, load averages, core count, busiest process and governor stay fresh |
| `@cpu_revamped_render` | empty | `options` turns on options render mode, see [How it works](#how-it-works) |
| `@cpu_revamped_throttle_when_detached` | `0` | `1` stops sampling while no client is attached |
| `@cpu_revamped_percentage_format` | `%s%%` | printf format for the load |
| `@cpu_revamped_medium_thresh`, `@cpu_revamped_high_thresh` | `30`, `80` | load percent where the medium and high tiers start |
| `@cpu_revamped_low_icon` | `▰▱▱` | icon for the low load tier |
| `@cpu_revamped_medium_icon` | `▰▰▱` | icon for the medium load tier |
| `@cpu_revamped_high_icon` | `▰▰▰` | icon for the high load tier |
| `@cpu_revamped_{low,medium,high}_{fg,bg}_color` | empty | colors per load tier |
| `@cpu_revamped_temp_unit` | `C` | `C` or `F` |
| `@cpu_revamped_temp_format` | `%s°C` | printf format for the temperature; the unit follows `@cpu_revamped_temp_unit` |
| `@cpu_revamped_temp_medium_thresh`, `@cpu_revamped_temp_high_thresh` | `65`, `80` | degrees Celsius where the medium and high temperature tiers start |
| `@cpu_revamped_temp_low_icon` | empty | icon for the low temperature tier |
| `@cpu_revamped_temp_medium_icon` | empty | icon for the medium temperature tier |
| `@cpu_revamped_temp_high_icon` | empty | icon for the high temperature tier |
| `@cpu_revamped_temp_{low,medium,high}_{fg,bg}_color` | empty | colors per temperature tier |
| `@cpu_revamped_freq_format` | `%sMHz` | format for the clock |
| `@cpu_revamped_load_format` | `%s` | format for the load averages |
| `@cpu_revamped_graph_width` | `20` | readings kept for `#{cpu_graph}` |
| `@cpu_revamped_load_medium_ratio`, `@cpu_revamped_load_high_ratio` | `0.7`, `1.0` | load per core where `#{cpu_load_color}` turns medium and high |
| `@cpu_revamped_alert_icon` | `!` | glyph for `#{cpu_alert}` |
| `@cpu_revamped_icons` | `ascii` | `nerd` labels every metric with a Nerd Font glyph |
| `@cpu_revamped_<metric>_label` | empty | text printed before one metric's value when the value is not empty; `''` removes the `nerd` label |
| `@cpu_revamped_fixed_width` | `off` | `on` pads each value on the left to its widest form |
| `@cpu_revamped_<metric>_width` | empty | pad width for one metric, which wins over the fixed width |
| `@cpu_revamped_popup_key` | `M-c` | prefix key for the detail popup; `off` binds nothing |
| `@cpu_revamped_popup_command` | `btop` | command run in the popup |
| `@cpu_revamped_popup_width`, `@cpu_revamped_popup_height` | `80%`, `80%` | popup size |

Labels apply to `percentage`, `temp`, `freq`, `load`, `load5`, `load15`, `count`, `graph`, `top_process` and `governor`. A longer value is never cut by a width.

### Theme colors

The color options are empty by default, so the plugin adds no color until you set one. Each block below colors the low, medium and high tiers green, yellow and red:

<details>
<summary>Catppuccin Mocha</summary>

```tmux
set -g @cpu_revamped_low_fg_color '#[fg=#a6e3a1]'
set -g @cpu_revamped_medium_fg_color '#[fg=#f9e2af]'
set -g @cpu_revamped_high_fg_color '#[fg=#f38ba8]'
set -g @cpu_revamped_temp_low_fg_color '#[fg=#a6e3a1]'
set -g @cpu_revamped_temp_medium_fg_color '#[fg=#f9e2af]'
set -g @cpu_revamped_temp_high_fg_color '#[fg=#f38ba8]'
```

</details>

<details>
<summary>Dracula</summary>

```tmux
set -g @cpu_revamped_low_fg_color '#[fg=#50fa7b]'
set -g @cpu_revamped_medium_fg_color '#[fg=#f1fa8c]'
set -g @cpu_revamped_high_fg_color '#[fg=#ff5555]'
set -g @cpu_revamped_temp_low_fg_color '#[fg=#50fa7b]'
set -g @cpu_revamped_temp_medium_fg_color '#[fg=#f1fa8c]'
set -g @cpu_revamped_temp_high_fg_color '#[fg=#ff5555]'
```

</details>

<details>
<summary>Nord</summary>

```tmux
set -g @cpu_revamped_low_fg_color '#[fg=#a3be8c]'
set -g @cpu_revamped_medium_fg_color '#[fg=#ebcb8b]'
set -g @cpu_revamped_high_fg_color '#[fg=#bf616a]'
set -g @cpu_revamped_temp_low_fg_color '#[fg=#a3be8c]'
set -g @cpu_revamped_temp_medium_fg_color '#[fg=#ebcb8b]'
set -g @cpu_revamped_temp_high_fg_color '#[fg=#bf616a]'
```

</details>

<details>
<summary>Gruvbox Dark</summary>

```tmux
set -g @cpu_revamped_low_fg_color '#[fg=#b8bb26]'
set -g @cpu_revamped_medium_fg_color '#[fg=#fabd2f]'
set -g @cpu_revamped_high_fg_color '#[fg=#fb4934]'
set -g @cpu_revamped_temp_low_fg_color '#[fg=#b8bb26]'
set -g @cpu_revamped_temp_medium_fg_color '#[fg=#fabd2f]'
set -g @cpu_revamped_temp_high_fg_color '#[fg=#fb4934]'
```

</details>

<details>
<summary>Tokyo Night</summary>

```tmux
set -g @cpu_revamped_low_fg_color '#[fg=#9ece6a]'
set -g @cpu_revamped_medium_fg_color '#[fg=#e0af68]'
set -g @cpu_revamped_high_fg_color '#[fg=#f7768e]'
set -g @cpu_revamped_temp_low_fg_color '#[fg=#9ece6a]'
set -g @cpu_revamped_temp_medium_fg_color '#[fg=#e0af68]'
set -g @cpu_revamped_temp_high_fg_color '#[fg=#f7768e]'
```

</details>

<details>
<summary>Solarized Dark</summary>

```tmux
set -g @cpu_revamped_low_fg_color '#[fg=#859900]'
set -g @cpu_revamped_medium_fg_color '#[fg=#b58900]'
set -g @cpu_revamped_high_fg_color '#[fg=#dc322f]'
set -g @cpu_revamped_temp_low_fg_color '#[fg=#859900]'
set -g @cpu_revamped_temp_medium_fg_color '#[fg=#b58900]'
set -g @cpu_revamped_temp_high_fg_color '#[fg=#dc322f]'
```

</details>

### Internal state

The plugin writes these options itself. Do not set them.

| Option | Holds |
|:-------|:------|
| `@cpu_revamped_published` | the metrics found in `status-left` and `status-right` at load, which options mode publishes |
| `@cpu_revamped_out_<metric>` | the published value of each metric in options mode |
| `@cpu_revamped_ticker_pid` | pid of the options-mode background process |
| `@cpu_revamped_option_names` | the options the background process reads in one call per tick |
| `@cpu_revamped_history` | recent load readings for `#{cpu_graph}` |
| `@cpu_revamped_{percent,temp,freq,load,load5,load15,count,top_process,governor}` | cached readings, each with a `_ts` timestamp, and `_lock` on `percent` |

## Key bindings

| Key | Action | Option |
|:----|:-------|:-------|
| `prefix + M-c` | open a popup running `@cpu_revamped_popup_command` | `@cpu_revamped_popup_key` |

On tmux older than 3.2 the key shows a message instead of a popup.

## How it works

In the default jobs mode, each placeholder becomes a `#()` call to [`src/cpu.sh`](src/cpu.sh). The call prints the cached value at once. When the cached load is older than `@cpu_revamped_interval`, it also starts one background refresh, guarded by a lock so parallel calls do not start a second one.

tmux runs every `#()` call on every status redraw. With several plugins on one bar that can be about once a second. Options mode removes those calls:

```tmux
set -g @cpu_revamped_render 'options'
set -g @cpu_revamped_fixed_width 'on'
```

Each placeholder then becomes an option read such as `#{E:@cpu_revamped_out_percentage}`. One background process per server samples the CPU every `@cpu_revamped_interval` seconds and writes every value the status line uses in a single tmux call, followed by one redraw. The process exits when the server stops or a config reload starts its replacement. Switching back to jobs mode releases it.

The busiest process name has every `#` doubled before it is cached, so a process named like a tmux format renders as text.

## Development

| Command | What it runs |
|:--------|:-------------|
| `make test` | the bats suite under [`test/`](test) |
| `make lint` | shellcheck on every shell file |
| `make coverage` | kcov line coverage on Linux, failing below 95% |

## License

[MIT](LICENSE), copyright Gustavo Franco.

<!-- family:begin -->

## The tmux-revamped family

This plugin is one member of the tmux-revamped family. Every member carries the
same contract in [`FAMILY.md`](FAMILY.md), the same tooling under `family/`, and
the same shared library, all held byte-identical by a checksum manifest. They are
built to be installed together: no member claims a key or a tmux option that
another member claims.

A defect found in one member is hunted across all of them before the fix is
called done. That obligation is written into the contract rather than left to
memory, and `family/bin/sweep` is how it is discharged.

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
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Launch any TUI app in a popup or a window, scoped to the current pane's directory, with one configurable bindi |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Pane and window management bindings for tmux, version aware, vim friendly, every prefix key can be disabled |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | Save every tmux session, window and pane, auto-save on a timer, and restore it all after a reboot |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | The starting point for a tmux-revamped plugin: shared library, bats harness, CI and family tooling |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in the tmux status bar that keeps all of its state in tmux options, with no temp files |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM, swap and memory pressure in the tmux status bar, sampled in the background so the render never waits |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | Drag a window tab along the tmux status bar with the mouse to move that window |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Send the mouse wheel to apps that scroll themselves and into tmux copy-mode everywhere else |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults, gated by tmux version and terminal, that leave the options you set alone |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | Tiling window management for tmux: eight layouts including BSP dwindle and spiral, with layout undo |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local and world clocks for the tmux status bar, colored by time of day, with countdowns and a DST warning |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather for the tmux status bar from wttr.in, fetched in the background so the status line never waits |

### Checking an installation

With every member on disk, one command reports any conflict between them:

```sh
family/bin/doctor --live
```

It reads each member and the running tmux server, and reports duplicate keys,
duplicate status placeholders, options outside the naming grammar, and any
member whose contract version has fallen behind.

<!-- family:end -->
