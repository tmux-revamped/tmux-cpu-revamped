# Changelog

# [3.1.0](https://github.com/tmux-revamped/tmux-cpu-revamped/compare/v3.0.0...v3.1.0) (2026-11-20)


### Features

* add per-core bars, throttling and arrows ([2bfa589](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/2bfa589f6e47c17e7c91544699dc008066925a1d))

# [3.0.0](https://github.com/tmux-revamped/tmux-cpu-revamped/compare/v2.0.0...v3.0.0) (2026-11-19)


* feat!: rewrite the plugin in POSIX sh ([d8be22d](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/d8be22ddbe689c9c06701bd690d1fde523844078))


### BREAKING CHANGES

* the script moved from src/cpu.sh to
bin/cpu-revamped. A placeholder is printed by "cpu-revamped status
NAME", where it was "cpu.sh NAME", and "cpu.sh bind" and "cpu.sh
start" are now "cpu-revamped apply". bash is no longer required. A
tmux option set to nothing now means its default, where a label, the
alert icon or a format set to nothing used to stay empty. The
environment knobs CPU_SAMPLE_INTERVAL, TICKER_MAX_TICKS, CACHE_SYNC
and PLUGIN_LOG_* are gone. On the command line a load ratio that is
not a number, a temperature unit other than C or F, or a throttle
other than 0 or 1 is refused; the same value in a tmux option still
works and doctor names it.

# [2.0.0](https://github.com/tmux-revamped/tmux-cpu-revamped/compare/v1.3.0...v2.0.0) (2026-11-18)


* feat!: one default key per plugin, allocated family wide ([8ba0b41](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/8ba0b41b788591c4f25b55c2a808f48af894c932))


### Bug Fixes

* **ci:** read the first released version, not Unreleased ([6b25595](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/6b25595f3b1be1080e2973d82347430d5d57d1e8))
* **cpu:** escape the top process name for tmux ([18c5ab0](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/18c5ab0d6ac25cdb2a0527b9e25379912b3c15ac))
* **cpu:** keep the full top process name ([ad058e4](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/ad058e46fa94029bf658a7ef3982d60a27cd0cb7))
* **cpu:** quote the plugin path in tmux commands ([8014b18](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/8014b182fb2475920aa435f8de568153f529f77e))
* **cpu:** report macmon in the doctor ([accf048](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/accf048a81c2428219e537713f3538687fe19754))
* **cpu:** run decimal awk under the C locale ([e3c8fa9](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/e3c8fa96bd333a7888b1ce69efb1a6235cf51ac4))
* **cpu:** stop an orphan ticker in jobs mode ([9f9c828](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/9f9c828ff0b7e879714799f37e796bd95630abaf))
* double percent signs in published values ([45e9099](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/45e90998060a34330d1a97cf651c3da894c2f4b9))
* **family:** fail when git cannot read a mode ([63a5dcc](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/63a5dcc6dae2369a5c1fe3becb136fcb5ec7aa21))
* **family:** honor only active exceptions ([b23a5da](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/b23a5da01be3ca11739b66ba167a455770055315))
* **family:** keep a member exception on propagate ([6d4dd82](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/6d4dd8207e7f3ae92d386ec2597f20691b67a094))
* **family:** read html taglines in gen-readme ([0c001e5](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/0c001e5992a79c5050b54caaa467e8d60c1bcc32))
* **family:** reject unquoted replacements ([20ac5cf](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/20ac5cf5d37c23bfa2dbbe2001ca7fa8da969a77))
* **family:** require executable entry points ([c6a22ec](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/c6a22ecc7387982ea2fc9107c8155483c9d2036e))
* keep published metrics on a second entry run ([e8432e2](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/e8432e2cd05e3f67cbaf60c3de3818891debc48a))
* let off unbind the popup key ([c352947](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/c3529470b694debee63dd679db2ecad618c83ada))
* open the detail popup without btop ([434a39c](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/434a39c11344a1045b5bb28a9166b6ee17df07b5))
* parse temperatures under the C locale ([b62e380](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/b62e380cefeba6660b44449b42801dfbf2e50b63))
* quote the coverage path and share one Makefile ([db6da0b](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/db6da0ba1d1d6745f8fc2cf320e7437a90d0df09))
* rank the busiest process under the C locale ([b28e46a](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/b28e46a930de331923d8c7a31898befcfd810971))
* **ticker:** detach the daemon from caller stdin ([c051bfa](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/c051bfab3532a911682b703b8a2bf640e53cf7fa))


### Documentation

* add the settings and value rules ([149ef6e](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/149ef6eed744a8b5b3aad9e64802a12de498126b))


### Features

* add a shared desktop notifier ([aa7fc3b](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/aa7fc3b3076cbb8f683054030bff71efebe21324))
* add an options render mode and fixed widths ([5507c9b](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/5507c9b8489c2a19773dc4eb964db0609a492872))
* **family:** accept bot updates in the audit ([ec1631c](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/ec1631c8d4b29aa69d4e0256bd90e2191419b78e))
* **family:** adopt the family contract ([5c6e472](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/5c6e472a495c25886688b0cadd31980a9d6ecaff))
* **family:** measure key clashes against a live server ([24e14ec](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/24e14ecdc997e95c5b70672340e07fe97368415b))
* **family:** one shared core and one pipeline ([c6428ea](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/c6428ea047f1085040548efb49a1754ec69f9ee8))
* label each metric with an icon ([901fa74](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/901fa74692e0217cd40ad202b4aa6fcb640892a2))
* read Apple Silicon CPU temperature ([dc210ee](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/dc210ee98d881a1895570b5b41c5b2dca37ba009))


### Performance Improvements

* cut the cost of each options-mode tick ([106a022](https://github.com/tmux-revamped/tmux-cpu-revamped/commit/106a022b7c85653fdd80283d9652ab31d7a2257f))


### BREAKING CHANGES

* decided on its own, apart from the alias rule, which
is about names.
* every default key moved. family/docs/migration.md maps the old
keys to the new ones and shows how to restore any of them.

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
