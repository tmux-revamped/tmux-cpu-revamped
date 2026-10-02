# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Metric labels. `@cpu_revamped_<metric>_label` prints an icon or word before a
  value only when the value is not empty, and `@cpu_revamped_icons` set to
  `nerd` labels every metric from a Nerd Font set. The default adds no labels.

### Fixed

- A comma-decimal locale such as pt_BR broke the Fahrenheit conversion and
  the iStats temperature parse, which read `45.6` as 45 or printed a comma.
  The arithmetic now runs under the C locale.

## [1.3.0] - 2026-06-29

### Added

- History sparkline `#{cpu_graph}` driven by a bounded ring buffer kept in a
  tmux user-option, so load trends show as `▁▂▄▆█` with no temp file.
- Top CPU process `#{cpu_top_process}`, sampled in the worker, answers what is
  eating the CPU right now.
- CPU governor `#{cpu_governor}` on Linux, confirming powersave vs performance.
- Five and fifteen minute load averages `#{cpu_load5}` and `#{cpu_load15}`
  alongside the existing one-minute value.
- Core-relative load color `#{cpu_load_color}`, so the same absolute load reads
  green on a many-core box and red on a small one.
- Alert glyph `#{cpu_alert}` that appears when load or temperature crosses its
  high threshold.
- Detail popup bound to `prefix + C`, opening btop through a mockable tmux seam,
  gated on tmux 3.2 with a message fallback on older versions.
- `doctor` subcommand that reports the platform, popup support, the temperature
  source, and which optional tools are installed.
- Optional worker throttle `@cpu_revamped_throttle_when_detached`, which stops
  resampling when no client is attached.

## [1.2.0] - 2026-06-23

### Added

- AMD Ryzen CPU temperature now reads directly from the `k10temp` hwmon sensor,
  preferring the Tctl die reading, so the temperature shows up even when
  `lm-sensors` is not installed.

### Changed

- Reviewed the upstream `tmux-plugins/tmux-cpu` open issues and pull requests.
  Confirmed the time formatting uses no GNU-only `date` flags (PR #97), and
  widened the temperature path to cover Ryzen without `sensors` (PR #81).

## [1.1.0] - 2026-06-20

### Added

- CPU frequency placeholder `#{cpu_freq}` with a per-chip clock table on Apple
  Silicon, `sysctl` on Intel macOS, and `/proc/cpuinfo` or scaling on Linux.
- Load-average placeholder `#{cpu_load}` and CPU-count placeholder `#{cpu_count}`.
- macOS CPU temperature via `istats` as a fallback to `osx-cpu-temp`.
- Richer Linux temperature: typed thermal zones, coretemp hwmon, and more
  `sensors` labels (Tdie, k10temp, CPU Temperature).

## [1.0.0] - 2026-06-19

### Added

- CPU load placeholders: `#{cpu_percentage}`, `#{cpu_icon}`, `#{cpu_fg_color}`,
  `#{cpu_bg_color}`.
- CPU temperature placeholders: `#{cpu_temp}`, `#{cpu_temp_icon}`,
  `#{cpu_temp_fg_color}`, `#{cpu_temp_bg_color}`.
- Non-blocking design: load is sampled in a background worker and read from a
  tmux user-option, so the status render never waits and no temp files are used.
- macOS load via `top`, Linux load via a `/proc/stat` delta.
- Temperature via `osx-cpu-temp` on macOS and `sensors` or a thermal zone on
  Linux, rendering empty when no sensor is present.
- Configurable thresholds, icons, colors, format strings, and Celsius or
  Fahrenheit units.
