# tmux-cpu-revamped

Guidance for anyone, human or agent, changing tmux-cpu-revamped. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything this plugin shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to tmux-cpu-revamped, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into [`FAMILY.md`](FAMILY.md) instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`cpu-revamped.tmux`](cpu-revamped.tmux) | The entry point TPM runs |
| [`src/cpu.sh`](src/cpu.sh) | The script the placeholders, keys and popups call |
| [`src/lib/cpu/`](src/lib/cpu) | This member's modules |
| [`src/lib/utils/constants.sh`](src/lib/utils/constants.sh) | This member's constants, including its version |
| [`src/lib/utils/`](src/lib/utils), [`src/lib/tmux/`](src/lib/tmux) | The shared library. Every file there except `constants.sh` is identical in every member |
| [`test/`](test) | The bats suite. `helpers.bash` and `tmux_helpers.bash` are identical in every member; this member's own mocks go in the `_local` files. [`test/entry/keys.bats`](test/entry/keys.bats) presses the popup key through a second tmux attached to a private server |

## Names

- Settings are tmux options named `@cpu_revamped_<setting>`.
- Placeholders include `#{cpu_percentage}`.
- Public functions carry `cpu_`; private ones start with `_`.
- The version constant is `CPU_REVAMPED_VERSION`.
- Its command-line tool, once it exists, is `cpu-revamped`.

## Behaviour

- Shows CPU load, temperature and frequency in the status line, without blocking the render.
- `M-c` opens the detail popup, running `@cpu_revamped_popup_command`, or the first of `btop`, `htop` and `top` that is installed. A command that is not installed is named in a message, never run in a popup that would close at once.
- By default each placeholder becomes a `#()` call that prints the cached value at once; a value older than `@cpu_revamped_interval` also starts one background refresh, guarded by a lock so parallel calls start no second one. With `@cpu_revamped_render` set to `options`, each placeholder becomes an option read such as `#{E:@cpu_revamped_out_percentage}`, and one background process per server writes every value in a single tmux call, then exits when the server stops or a config reload starts a newer one.

## Domain rules

- Load comes from two reads of `/proc/stat` 0.3 s apart on Linux and from `iostat`, then `top`, on macOS.
- Temperature comes from thermal zones, coretemp, k10temp, then `sensors` on Linux, `macmon` on Apple Silicon, and `osx-cpu-temp`, then `istats`, on Intel Macs.
- The busiest process name has every `#` doubled before it is cached.

## Release

- `CPU_REVAMPED_VERSION` in [`src/lib/utils/constants.sh`](src/lib/utils/constants.sh) holds the version. It must equal the newest versioned heading in [`CHANGELOG.md`](CHANGELOG.md) and the README's version badge, which the `version` job in `tests.yml` checks.
- A push to `main` whose version has no tag yet makes the `release` job in `tests.yml` tag `vX.Y.Z` and publish a GitHub release with that changelog section.
- Unreleased changes sit under `## [Unreleased]` in [`CHANGELOG.md`](CHANGELOG.md) until a release is cut.

## Gaps against FAMILY.md

As of 2026-11-17:

- Every script is bash, under `#!/usr/bin/env bash`, not POSIX `sh`, so it is untested under `dash`, `zsh` and BusyBox `sh`.
- The code lives in [`src/`](src) and [`src/lib/`](src/lib); there is no `bin/cpu-revamped`, `lib/state.sh` or `lib/core.sh`.
- No `cpu-revamped` command with `help`, `version` and `doctor` in the family's form, no man page, no completions and no `manifest.json`.
- No gum interface: no `lib/ui.sh`, `lib/table.awk`, themes or `test/bin/gum`.
- No `screens/`: no VHS recording of each feature, no on-screen caption of the keys each recording presses, and no recordings in the README.
- The README sections are not the family's order of Quick start, Usage, topic sections, Portability, Development and License.
- Coverage is kcov with a 95 percent floor on Linux, not bashcov at 100 percent merged from macOS and Linux.
- CI tests GNU, BSD and uutils tools in `tests.yml`, but not the six toolsets through `.github/scripts/toolset.sh`, and no shell matrix under `sh`, `dash`, `bash` and `zsh`.
- No golden transcripts, `call.sh`, `run-matrix.sh` or `linux-container.sh`.
- The version is written by hand and released by `tests.yml`; there is no semantic-release, `package.json`, `release.yml` with `recover`, `bot-merge.yml` or Renovate.
- CI is `tests.yml` and `security.yml`, not `ci.yml`, and no job starts with `step-security/harden-runner`.
- No `.editorconfig`, `.yamllint.yml` or shfmt; the Makefile has `help`, `test`, `test-unit`, `coverage`, `lint` and `clean`, not the family's targets.
- `#{cpu_governor}` works on Linux only, from `scaling_governor`.
- No `@cpu_revamped_notify` for throttling yet.
- `get_tmux_option` keeps a tmux option set to nothing as an empty value, where FAMILY.md has it mean the default; the ticker's own reader already takes the default.
