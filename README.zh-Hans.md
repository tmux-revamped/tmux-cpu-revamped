<div align="center">

# tmux-cpu-revamped

<strong>在 tmux 状态栏显示 CPU 负载、温度和频率，绝不阻塞渲染。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; 简体中文 &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-cpu-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-cpu-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-cpu-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-cpu-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-cpu-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-cpu-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-cpu-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#快速开始"><strong>快速开始</strong></a> &nbsp;|&nbsp;
  <a href="#用法">用法</a> &nbsp;|&nbsp;
  <a href="#工作原理">工作原理</a> &nbsp;|&nbsp;
  <a href="#界面">界面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="cpu-revamped 按档位颜色显示负载和温度，打开监视器弹窗，并切换到 Nerd Font 标签、图表和 options 渲染模式" width="800">
</p>

```console
$ cpu-revamped refresh
Refreshed. 31% of the CPU is busy.
$ cpu-revamped status percentage
31%
```

**22** 个占位符，**2** 种渲染模式，支持 macOS 和 Linux，需要 tmux **3.2** 或更高版本。

---

## 快速开始

### 前提条件

| 工具 | 版本 | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 或更高 | 家族的最低版本，弹窗也需要它 |
| btop, htop | 可选 | 弹窗打开的监视器；没有时运行 `top` |
| gum | 可选 | `cpu-revamped` 的菜单、表格和颜色；没有它时所有命令输出纯文本 |

它在 Linux 和 macOS 上运行，BSD、GNU、uutils 或 BusyBox 工具均可。每个数值都来自系统自带的来源：

| 数值 | Linux | macOS Intel | macOS Apple Silicon |
|:-----|:------|:------------|:--------------------|
| 负载 | `/proc/stat`，间隔 0.3 秒读两次 | `iostat`，其次 `top` | `iostat`，其次 `top` |
| 温度 | thermal zone，其次 coretemp、k10temp、`sensors` | `osx-cpu-temp`，其次 `istats` | `macmon` |
| 频率 | `/proc/cpuinfo`，其次 `scaling_cur_freq` | `sysctl hw.cpufrequency` | 按芯片世代查表得到的频率 |
| 平均负载 | `/proc/loadavg` | `sysctl vm.loadavg` | `sysctl vm.loadavg` |
| 核心数 | `/proc/cpuinfo` | `sysctl hw.ncpu` | `sysctl hw.ncpu` |
| 调速器 | `scaling_governor` | 无 | 无 |
| 最忙的进程 | `ps` | `ps` | `ps` |
| 每核负载 | `/proc/stat` 的 `cpuN` 行，以计数器保存 | `osascript -l JavaScript` 调用 `host_processor_info`，然后是 `macmon` | `osascript -l JavaScript` 调用 `host_processor_info`，然后是 `macmon` |
| 降频 | sysfs 中的 `thermal_throttle/*_throttle_count` | `pmset -g therm` | `pmset -g therm` |

| 平台 | 温度工具 |
|:-----|:---------|
| macOS Apple Silicon | `brew install macmon`，无需 sudo 即可读取传感器 |
| macOS Intel | `brew install osx-cpu-temp`，或 `gem install iStats` |
| Linux | 大多数机器不需要；使用 `sensors` 备用来源时安装 `lm-sensors` |

缺少来源时，对应的占位符为空，`cpu-revamped doctor` 会指出是哪一个。`osx-cpu-temp` 和 `istats` 在 Apple Silicon 上返回 `0.0`，这被视为没有读数。

### 安装

使用 [TPM](https://github.com/tmux-plugins/tpm) 时，把插件加入 `~/.tmux.conf`，然后按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-cpu-revamped'
```

手动安装时，克隆仓库，并在 `~/.tmux.conf` 中运行入口脚本：

```bash
git clone https://github.com/tmux-revamped/tmux-cpu-revamped ~/.tmux/plugins/tmux-cpu-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-cpu-revamped/cpu-revamped.tmux
```

请在插件加载之前设置 `status-left` 或 `status-right`。插件只在加载时替换一次其中的占位符。

在克隆的目录中运行 `make install`，还会把 `cpu-revamped` 放进 `~/.local/bin`，把它的 man 手册和补全放在 `~/.local/share` 下。

### 验证

```bash
~/.tmux/plugins/tmux-cpu-revamped/bin/cpu-revamped doctor
```

## 用法

本插件显示 CPU 的忙碌程度，以及温度、频率、平均负载、核心数、最近负载的图表、最忙的进程，在 Linux 上还有调速器。状态栏显示 tmux 已经保存的值，后台采样负责更新它。

| 占位符 | 输出 |
|:-------|:-----|
| `#{cpu_percentage}` | CPU 负载，例如 `42%` |
| `#{cpu_icon}` | 负载的档位图标 |
| `#{cpu_fg_color}` | 负载档位的前景样式 |
| `#{cpu_bg_color}` | 负载档位的背景样式 |
| `#{cpu_temp}` | 整数度的温度，例如 `54°C` |
| `#{cpu_temp_icon}` | 温度的档位图标 |
| `#{cpu_temp_fg_color}` | 温度档位的前景样式 |
| `#{cpu_temp_bg_color}` | 温度档位的背景样式 |
| `#{cpu_freq}` | 以兆赫为单位的频率，例如 `4000MHz` |
| `#{cpu_load}` | 一分钟平均负载，例如 `1.23` |
| `#{cpu_load5}` | 五分钟平均负载 |
| `#{cpu_load15}` | 十五分钟平均负载 |
| `#{cpu_count}` | 逻辑 CPU 数 |
| `#{cpu_graph}` | 最近负载采样的迷你图，例如 `▁▂▄▆█` |
| `#{cpu_top_process}` | 占用 CPU 最多的进程，例如 `node 42%` |
| `#{cpu_governor}` | Linux 的频率调速器，例如 `performance`；在 macOS 上为空 |
| `#{cpu_load_color}` | 按每核一分钟平均负载判断的负载档位前景样式 |
| `#{cpu_alert}` | 负载或温度达到其高阈值时为 `@cpu_revamped_alert_icon`，否则为空 |
| `#{cpu_cores}` | 每个核心一根柱形，例如 `▂▄▇█`；第二次采样前为空 |
| `#{cpu_sep_left}` | 用负载档位颜色绘制的左向 powerline 箭头 |
| `#{cpu_sep_right}` | 用负载档位颜色绘制的右向 powerline 箭头 |
| `#{cpu_throttle}` | CPU 被压制期间为 `@cpu_revamped_throttle_icon`，否则为空 |

在状态栏中放入占位符：

```tmux
set -g @cpu_revamped_low_fg_color '#[fg=green]'
set -g @cpu_revamped_medium_fg_color '#[fg=yellow]'
set -g @cpu_revamped_high_fg_color '#[fg=red]'

set -g status-right '#{cpu_fg_color}#{cpu_icon} #{cpu_percentage}#[default] #{cpu_temp} '
```

同一个例子，加上几个选项，在 [examples/status-right.tmux.conf](examples/status-right.tmux.conf) 中。

### 标签和宽度

`@cpu_revamped_<metric>_label` 在某个指标的值非空时，在它前面打印一个图标或词。`@cpu_revamped_icons` 设为 `nerd` 时，下面每个指标前都有 Nerd Font 字形标签。指标自己的标签优先于这组字形，设为空的标签表示默认值，所以字形保留。默认的 `ascii` 不加标签。

| 指标 | `nerd` 字形 |
|:-----|:------------|
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

`@cpu_revamped_fixed_width` 设为 `on` 时，每个数值在左侧补齐到其自然宽度：负载 4 个字符，温度和平均负载 5 个字符，频率 7 个字符，核心数 3 个字符，所以从 `9%` 变成 `42%` 不会让这一行的其余部分移位。`@cpu_revamped_<metric>_width` 设置某个指标的宽度，并优先于固定宽度。过长的值不会被截断。

### 每核柱形、分隔符和降频

`#{cpu_cores}` 按 `#{cpu_graph}` 的画法为每个核心显示一根柱形，每根柱形是该核心自上一次采样以来处于忙碌的时间比例。第一次采样没有更早的计数器，什么也不显示；同一秒内的两次采样保留上一次的柱形。Linux 把 `/proc/stat` 中 `cpuN` 行的计数器保存在一个选项里。macOS 通过 `osascript` 运行的 JXA 读取 `host_processor_info`，读不到时改用 `macmon`；两者都没有的 Mac 不显示柱形，`cpu-revamped doctor` 会指出这一点。

`#{cpu_sep_left}` 和 `#{cpu_sep_right}` 显示 `@cpu_revamped_sep_left` 和 `@cpu_revamped_sep_right` 这两个 powerline 箭头。每个箭头以负载档位的背景色作前景色，叠在 `@cpu_revamped_sep_bg` 之上，所以档位变化时箭头会跟随该段的颜色。没有背景样式的档位，箭头不带样式。

```tmux
set -g @cpu_revamped_low_bg_color '#[bg=#313244]'
set -g @cpu_revamped_high_bg_color '#[bg=#585b70]'
set -g status-right '#{cpu_sep_left}#{cpu_bg_color}#{cpu_percentage} #{cpu_cores}#[default]#{cpu_sep_right}'
```

`#{cpu_throttle}` 在 CPU 被压制期间显示 `@cpu_revamped_throttle_icon`。把 `@cpu_revamped_notify` 设为 `1`，降频开始时发送一次桌面通知，下一次要等降频结束之后。通知需要状态栏里有 `#{cpu_throttle}`，因为只有被使用的占位符才会让插件读取降频状态，读取间隔是 `@cpu_revamped_detail_interval` 秒。

图标、标签或文本设为 `off` 时什么也不显示：各档位图标、`@cpu_revamped_alert_icon`、`@cpu_revamped_throttle_icon`、两个分隔符和每个 `@cpu_revamped_<metric>_label`。空选项表示默认值，所以隐藏它们只能用 `off`。

### 渲染模式

默认情况下，每个占位符变成一个 `#()` 调用，tmux 在状态栏重绘时重新运行它。把 `@cpu_revamped_render` 设为 `options` 后，每个占位符变成对选项的读取，例如 `#{E:@cpu_revamped_out_percentage}`。每个服务器随后有一个后台进程每隔 `@cpu_revamped_interval` 秒采样一次，并用一次 tmux 调用写入所有数值，所以它们一起变化。

```tmux
set -g @cpu_revamped_render 'options'
set -g @cpu_revamped_fixed_width 'on'
```

### 档位颜色

档位样式默认为空，所以在你设置之前，`#{cpu_fg_color}`、`#{cpu_bg_color}`、`#{cpu_temp_fg_color}`、`#{cpu_temp_bg_color}` 和 `#{cpu_load_color}` 什么也不输出。下面的配色把 low 映射为绿色，medium 为黄色，high 为红色：

| 主题 | 低 | 中 | 高 |
|:-----|:---|:---|:---|
| Catppuccin Mocha | `#a6e3a1` | `#f9e2af` | `#f38ba8` |
| Dracula | `#50fa7b` | `#f1fa8c` | `#ff5555` |
| Nord | `#a3be8c` | `#ebcb8b` | `#bf616a` |
| Gruvbox Dark | `#b8bb26` | `#fabd2f` | `#fb4934` |
| Tokyo Night | `#9ece6a` | `#e0af68` | `#f7768e` |
| Solarized Dark | `#859900` | `#b58900` | `#dc322f` |

每个值写成一个样式，例如 `set -g @cpu_revamped_low_fg_color '#[fg=#a6e3a1]'`。温度档位用同样的样式，写在 `@cpu_revamped_temp_<tier>_fg_color` 下。

| 命令 | 作用 |
|:-----|:-----|
| `cpu-revamped apply` | 绑定弹窗按键并立即填充占位符；tmux 加载插件时由入口脚本运行它 |
| `cpu-revamped list` | 打印 `apply` 会发送的每条命令，不做任何更改；`--json` 打印一个对象 |
| `cpu-revamped status NAME` | 打印一个占位符，例如 `percentage`、`temp` 或 `graph`；状态栏运行它 |
| `cpu-revamped refresh` | 立即采样 CPU，并说明它有多忙 |
| `cpu-revamped card` | 立即读取所有内容，每个数值打印一行 |
| `cpu-revamped popup` | 在 tmux 弹窗中打开 CPU 监视器：弹窗命令，否则 btop，否则 htop，否则 top；弹窗按键运行它 |
| `cpu-revamped daemon` | 在每个周期发布占位符，供 `options` 渲染模式使用；`apply` 会启动它 |
| `cpu-revamped doctor` | 每个依赖一行：每个数值的来源工具或文件、弹窗打开的监视器，以及被放过的按键 |
| `cpu-revamped version` | 版本，然后是 tmux 版本 |
| `cpu-revamped help` | 帮助页；`man cpu-revamped` 记录同样的命令和设置 |
| `cpu-revamped` | 在终端中显示菜单 |

## 配置

每个选项也是带连字符的命令选项，例如 `--interval 2`，以及环境变量，例如 `CPU_REVAMPED_INTERVAL`；命令行优先于环境变量，环境变量优先于 tmux 选项。空的 tmux 选项表示默认值。`doctor` 会指出持有插件不认识的值的设置。传给 `apply` 的选项会带到弹窗按键和每一次状态调用中。

### 采样

| 选项 | 默认值 | 含义 |
|:-----|:-------|:-----|
| `@cpu_revamped_interval` | `5` | 负载采样保持新鲜的秒数 |
| `@cpu_revamped_detail_interval` | `60` | 温度、频率、平均负载、核心数、最忙的进程和调速器保持新鲜的秒数 |
| `@cpu_revamped_throttle_when_detached` | `0` | `1` 表示没有客户端连接时停止采样；状态栏保留最后一次采样 |
| `@cpu_revamped_render` | `jobs` | `options` 读取已发布的选项，而不是运行 `#()` 调用；其他任何值都表示 `jobs` |
| `@cpu_revamped_graph_width` | `20` | `#{cpu_graph}` 保留的采样数 |

### 档位和警报

| 选项 | 默认值 | 含义 |
|:-----|:-------|:-----|
| `@cpu_revamped_medium_thresh` | `30` | 档位变为 medium 的负载百分比 |
| `@cpu_revamped_high_thresh` | `80` | 档位变为 high 的负载百分比，也是 `#{cpu_alert}` 出现的百分比 |
| `@cpu_revamped_low_icon` | `▰▱▱` | low 负载档位的图标 |
| `@cpu_revamped_medium_icon` | `▰▰▱` | medium 负载档位的图标 |
| `@cpu_revamped_high_icon` | `▰▰▰` | high 负载档位的图标 |
| `@cpu_revamped_low_fg_color` | 空 | low 负载档位的前景样式，例如 `#[fg=green]` |
| `@cpu_revamped_medium_fg_color` | 空 | medium 负载档位的前景样式 |
| `@cpu_revamped_high_fg_color` | 空 | high 负载档位的前景样式 |
| `@cpu_revamped_low_bg_color` | 空 | low 负载档位的背景样式 |
| `@cpu_revamped_medium_bg_color` | 空 | medium 负载档位的背景样式 |
| `@cpu_revamped_high_bg_color` | 空 | high 负载档位的背景样式 |
| `@cpu_revamped_temp_medium_thresh` | `65` | 温度档位变为 medium 的摄氏度数 |
| `@cpu_revamped_temp_high_thresh` | `80` | 温度档位变为 high 的摄氏度数，也是 `#{cpu_alert}` 出现的度数 |
| `@cpu_revamped_temp_low_icon` | 空 | low 温度档位的图标 |
| `@cpu_revamped_temp_medium_icon` | 空 | medium 温度档位的图标 |
| `@cpu_revamped_temp_high_icon` | 空 | high 温度档位的图标 |
| `@cpu_revamped_temp_low_fg_color` | 空 | low 温度档位的前景样式 |
| `@cpu_revamped_temp_medium_fg_color` | 空 | medium 温度档位的前景样式 |
| `@cpu_revamped_temp_high_fg_color` | 空 | high 温度档位的前景样式 |
| `@cpu_revamped_temp_low_bg_color` | 空 | low 温度档位的背景样式 |
| `@cpu_revamped_temp_medium_bg_color` | 空 | medium 温度档位的背景样式 |
| `@cpu_revamped_temp_high_bg_color` | 空 | high 温度档位的背景样式 |
| `@cpu_revamped_load_medium_ratio` | `0.7` | `#{cpu_load_color}` 变为 medium 的每核平均负载 |
| `@cpu_revamped_load_high_ratio` | `1.0` | `#{cpu_load_color}` 变为 high 的每核平均负载 |
| `@cpu_revamped_alert_icon` | `!` | `#{cpu_alert}` 打印的内容 |

### Powerline 和降频

| 选项 | 默认值 | 含义 |
|:--------|:--------|:--------|
| `@cpu_revamped_sep_left` | U+E0B2 | `#{cpu_sep_left}` 显示的内容；`off` 什么也不显示 |
| `@cpu_revamped_sep_right` | U+E0B0 | `#{cpu_sep_right}` 显示的内容；`off` 什么也不显示 |
| `@cpu_revamped_sep_bg` | `default` | 两个箭头后面的背景色 |
| `@cpu_revamped_throttle_icon` | `throttled` | CPU 被压制期间 `#{cpu_throttle}` 显示的内容；`off` 什么也不显示 |
| `@cpu_revamped_notify` | `0` | `1` 在降频开始时发送桌面通知，每段降频一次 |

### 格式和标签

| 选项 | 默认值 | 含义 |
|:-----|:-------|:-----|
| `@cpu_revamped_temp_unit` | `C` | `C` 或 `F` |
| `@cpu_revamped_percentage_format` | `%s%%` | 负载的 printf 格式 |
| `@cpu_revamped_temp_format` | `%s°C` | 温度的 printf 格式；单位跟随 `@cpu_revamped_temp_unit` |
| `@cpu_revamped_freq_format` | `%sMHz` | 频率的 printf 格式 |
| `@cpu_revamped_load_format` | `%s` | 三个平均负载的 printf 格式 |
| `@cpu_revamped_icons` | `ascii` | `nerd` 为每个值加上 Nerd Font 字形标签 |
| `@cpu_revamped_<metric>_label` | 空 | 在某个值前面打印的文字，仅当该值非空时 |
| `@cpu_revamped_fixed_width` | `off` | `on` 把每个数值补齐到自然宽度，使 `9%` 变成 `42%` 时状态栏不会移位 |
| `@cpu_revamped_<metric>_width` | 空 | 把某个值补齐到这么多个字符；过长的值不会被截断 |

可以带标签和宽度的指标是 `percentage`、`temp`、`freq`、`load`、`load5`、`load15`、`count`、`graph`、`cores`、`top_process` 和 `governor`。

### 弹窗

| 选项 | 默认值 | 含义 |
|:-----|:-------|:-----|
| `@cpu_revamped_popup_key` | `M-c` | 打开详情弹窗的前缀键；`off` 表示不绑定 |
| `@cpu_revamped_popup_command` | 依次为 btop、htop、top | 弹窗运行的命令，可带参数；未安装的命令会在消息中点名 |
| `@cpu_revamped_popup_width` | `80%` | 弹窗宽度 |
| `@cpu_revamped_popup_height` | `80%` | 弹窗高度 |

### 内部状态

插件自己写入这些选项，不要设置它们。

| 选项 | 保存的内容 |
|:-----|:-----------|
| `@cpu_revamped_published` | 状态栏使用的指标，在加载时记录，使 options 模式只写入这些 |
| `@cpu_revamped_history` | `#{cpu_graph}` 背后的最近负载采样 |
| `@cpu_revamped_cores`、`_cores_stat`、`_throttle`、`_throttle_count`、`_notified` | 每核比例和计数器、降频标志及其计数，以及当前这段降频是否已通知 |
| `@cpu_revamped_out_<metric>` | options 模式下每个指标的渲染结果 |
| `@cpu_revamped_ticker_pid` | options 模式后台进程的进程号 |
| `@cpu_revamped_percent` 和其他数值、`_ts`、`_lock` | 保存的采样、每次读取的时间和刷新锁 |

## 按键绑定

| 按键 | 动作 | 默认 |
|:-----|:-----|:-----|
| `prefix + M-c` | 在弹窗中打开 CPU 监视器：你指定的命令，否则 btop，否则 htop，否则 top | 已绑定 |

`@cpu_revamped_popup_key` 可指定另一个按键，`off` 表示不绑定。默认按键已被其他绑定占用时会被放过，`cpu-revamped doctor` 会说明。

<a id="工作原理"></a>

## 运作原理

tmux 加载插件时，[`cpu-revamped.tmux`](cpu-revamped.tmux) 运行一次。它把 `status-left` 和 `status-right` 用到的指标记录在 `@cpu_revamped_published` 中，然后把每个占位符替换为对 [`bin/cpu-revamped`](bin/cpu-revamped) 的调用；在 `options` 模式下则替换为选项读取，并启动后台进程。

在默认模式下，每个 `#()` 调用立即返回已保存的采样。采样比间隔旧时，调用会在后台启动刷新并加锁，所以同一时间只有一个刷新在运行。在 Linux 上，负载是间隔 0.3 秒读取两次 `/proc/stat` 得到的忙碌比例，iowait 算作空闲。在 macOS 上，负载是 100 减去 `iostat` 的空闲比例，缺少 `iostat` 时改用 `top`。一个 `awk` 把读数变成所有数值，一次 tmux 调用把它们保存。温度、频率、平均负载、最忙的进程和调速器的读取代价更高，所以只为状态栏用到的占位符、每隔 `@cpu_revamped_detail_interval` 秒读取一次。

温度来自第一个有回应的来源：在 Linux 上依次是 thermal zone、coretemp、k10temp 和 `sensors`；在 Apple Silicon 上是 `macmon`，在 Mac 上之后是 `osx-cpu-temp` 和 `istats`。最忙进程的名称来自 `ps`，任何用户都能控制它，所以其中的每个 `#` 在到达状态栏之前都会加倍。读取、采样和格式化位于 [`lib/cpu.sh`](lib/cpu.sh)，设置表位于 [`lib/state.sh`](lib/state.sh)。

<a id="界面"></a>

## 界面

<details>
<summary>每个界面都在真实的 tmux 中用 <code>make screens</code> 录制，状态栏上显示每个按键</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="cpu-revamped: 带档位图标和颜色的负载、温度、频率、平均负载和警报"><br><sub>带档位图标和颜色的负载、温度、频率、平均负载和警报, 来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/popup.png" alt="cpu-revamped: prefix M-c 在弹窗中打开 CPU 监视器"><br><sub><code>prefix M-c</code> 在弹窗中打开 CPU 监视器, 来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/icons.png" alt="cpu-revamped: @cpu_revamped_icons 设为 nerd 时，每个指标前都有字形标签"><br><sub><code>@cpu_revamped_icons</code> 设为 <code>nerd</code> 时，每个指标前都有字形标签, 来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/graph.png" alt="cpu-revamped: 图表、负载和最忙的进程"><br><sub>图表、负载和最忙的进程, 来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="cpu-revamped: 在 options 渲染模式下，每个占位符读取一个 tmux 选项"><br><sub>在 <code>options</code> 渲染模式下，每个占位符读取一个 tmux 选项, 来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/card.png" alt="cpu-revamped: card 打印每个数值"><br><sub><code>card</code> 打印每个数值, 来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/temp.png" alt="cpu-revamped: 带档位图标和颜色的温度，以及警报"><br><sub>带档位图标和颜色的温度，以及警报, 来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/unit.png" alt="cpu-revamped: @cpu_revamped_temp_unit 设为 F"><br><sub><code>@cpu_revamped_temp_unit</code> 设为 <code>F</code>, 来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/load.png" alt="cpu-revamped: 三个平均负载、核心数和负载颜色"><br><sub>三个平均负载、核心数和负载颜色, 来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/load-format.png" alt="cpu-revamped: @cpu_revamped_load_format 决定平均负载的格式"><br><sub><code>@cpu_revamped_load_format</code> 决定平均负载的格式, 来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/ratios.png" alt="cpu-revamped: @cpu_revamped_load_medium_ratio 和 @cpu_revamped_load_high_ratio 移动负载颜色的分界"><br><sub><code>@cpu_revamped_load_medium_ratio</code> 和 <code>@cpu_revamped_load_high_ratio</code> 移动负载颜色的分界, 来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/clock.png" alt="cpu-revamped: 频率、调速器和最忙的进程"><br><sub>频率、调速器和最忙的进程, 来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/freq-format.png" alt="cpu-revamped: @cpu_revamped_freq_format 决定频率的格式"><br><sub><code>@cpu_revamped_freq_format</code> 决定频率的格式, 来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/format.png" alt="cpu-revamped: @cpu_revamped_percentage_format 决定负载百分比的格式"><br><sub><code>@cpu_revamped_percentage_format</code> 决定负载百分比的格式, 来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/fixed.png" alt="cpu-revamped: @cpu_revamped_fixed_width 把每个数值补齐到其自然宽度"><br><sub><code>@cpu_revamped_fixed_width</code> 把每个数值补齐到其自然宽度, 来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/width.png" alt="cpu-revamped: @cpu_revamped_count_width 把一个指标补齐到指定宽度"><br><sub><code>@cpu_revamped_count_width</code> 把一个指标补齐到指定宽度, 来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/labels.png" alt="cpu-revamped: 某个指标前面的自定义标签"><br><sub>某个指标前面的自定义标签, 来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/tiers.png" alt="cpu-revamped: @cpu_revamped_medium_thresh 和 @cpu_revamped_high_thresh 移动档位的分界"><br><sub><code>@cpu_revamped_medium_thresh</code> 和 <code>@cpu_revamped_high_thresh</code> 移动档位的分界, 来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/graph-width.png" alt="cpu-revamped: @cpu_revamped_graph_width 决定图表保留多少个采样"><br><sub><code>@cpu_revamped_graph_width</code> 决定图表保留多少个采样, 来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/popup-key.png" alt="cpu-revamped: @cpu_revamped_popup_key 为弹窗指定另一个按键"><br><sub><code>@cpu_revamped_popup_key</code> 为弹窗指定另一个按键, 来自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/popup-command.png" alt="cpu-revamped: @cpu_revamped_popup_command 指定弹窗运行的命令及其大小"><br><sub><code>@cpu_revamped_popup_command</code> 指定弹窗运行的命令及其大小, 来自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/status-command.png" alt="cpu-revamped: status percentage 和 status graph 各打印一个占位符"><br><sub><code>status percentage</code> 和 <code>status graph</code> 各打印一个占位符, 来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/refresh.png" alt="cpu-revamped: refresh 立即采样 CPU"><br><sub><code>refresh</code> 立即采样 CPU, 来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="cpu-revamped: list 打印每个绑定"><br><sub><code>list</code> 打印每个绑定, 来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/json.png" alt="cpu-revamped: list --json 把同一份计划打印成一个对象"><br><sub><code>list --json</code> 把同一份计划打印成一个对象, 来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="cpu-revamped: doctor"><br><sub><code>doctor</code>, 来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu.png" alt="cpu-revamped: 菜单"><br><sub>菜单, 来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/menu-card.png" alt="cpu-revamped: 从菜单打开的卡片"><br><sub>从菜单打开的卡片, 来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/accent.png" alt="cpu-revamped: 来自 CPU_REVAMPED_ACCENT 的强调色"><br><sub>来自 <code>CPU_REVAMPED_ACCENT</code> 的强调色, 来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="cpu-revamped: 没有 gum 的菜单"><br><sub>没有 gum 的菜单, 来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="cpu-revamped: 从菜单运行的 doctor，没有 gum"><br><sub>从菜单运行的 <code>doctor</code>，没有 gum, 来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-card.png" alt="cpu-revamped: 没有 gum 的 card"><br><sub>没有 gum 的 <code>card</code>, 来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/version.png" alt="cpu-revamped: 版本"><br><sub>版本, 来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/error.png" alt="cpu-revamped: 未知命令"><br><sub>未知命令, 来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="cpu-revamped: 六种主题下的标题"><br><sub>六种主题下的标题, 来自 <code>themes.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="cpu-revamped: 帮助页"><br><sub>帮助页, 来自 <code>help.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/cores.png" alt="cpu-revamped: #{cpu_cores} 为每个核心画一根柱形"><br><sub><code>#{cpu_cores}</code> 为每个核心画一根柱形, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/separators.png" alt="cpu-revamped: #{cpu_sep_left} 和 #{cpu_sep_right} 取负载档位的颜色"><br><sub><code>#{cpu_sep_left}</code> 和 <code>#{cpu_sep_right}</code> 取负载档位的颜色, from <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/throttle.png" alt="cpu-revamped: CPU 被压制期间显示 #{cpu_throttle}"><br><sub>CPU 被压制期间显示 <code>#{cpu_throttle}</code>, from <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/off.png" alt="cpu-revamped: 图标、标签或文本设为 off 时什么也不显示"><br><sub>图标、标签或文本设为 <code>off</code> 时什么也不显示, from <code>features.tape</code></sub></td>
</tr>
</table>

录制运行的是真实的插件和 tmux。`iostat`、`sysctl`、`macmon`、`osx-cpu-temp`、`pmset`、`osascript`、`ps` 和 `top` 由小脚本代替，所以画面上的数值来自这些脚本。录制在 macOS 上进行，它没有调速器，所以 `#{cpu_governor}` 在那里什么也不显示。

</details>

## 可移植性

插件是 POSIX `sh`。CI 在下面每一行上运行全部测试。

| Shell | 状态 |
|:------|:-------|
| `dash`、macOS 上的 `/bin/sh` | 支持 |
| `bash` 3.2 和 5.x、系统自带的 `zsh` 和 Homebrew 的 `zsh` | 支持 |

| 系统 | 状态 |
|:-------|:-------|
| macOS | Apple Silicon 和 Intel 上的 Tahoe，使用系统自带的工具、Homebrew 的 GNU 工具和 Homebrew 的 uutils |
| Linux | x86_64 和 arm64 上的 Ubuntu 26.04，使用 GNU coreutils、uutils 和 BusyBox |

## 开发

| 命令 | 运行内容 |
|:--------|:-------------|
| `make fmt` | 对每个脚本运行 shfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint 和 actionlint，零告警 |
| `make test` | 在系统 `sh` 下运行 bats 测试 |
| `make test-all` | 在每个已安装的 shell 下运行测试，macOS 上包括 bash 和 zsh 的两种构建 |
| `make test-linux` | 在 Ubuntu 容器中运行测试 |
| `make coverage` | 在这台 Mac 和 Ubuntu 容器中运行 bashcov，合并后以 100% 为门槛 |
| `make screens` | 用 VHS 在 tmux 中从真实插件录制上面的界面，在 macOS 上运行 |
| `make install` | 把命令、man 手册和补全安装到 `PREFIX` 下 |

在 macOS 上，运行 `brew bundle` 会根据 [`Brewfile`](Brewfile) 安装这些目标用到的所有工具。

提交遵循 Conventional Commits 格式，直接进入 `main`。`main` 上的 `ci` 通过后，`release.yml` 运行 semantic-release：自上一个标签以来的每个 `feat` 或 `fix` 都会发布新版本，更新版本常量，并把说明写进 [`CHANGELOG.md`](CHANGELOG.md)。

## 许可证

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

这个插件是 tmux-revamped 插件家族的一员。每个成员都带有 [`FAMILY.md`](FAMILY.md) 中相同的约定和相同的共享库，并且设计为一起安装：没有成员占用另一个成员占用的按键或 tmux 选项。

在一个成员中发现的缺陷，要在全部成员中排查之后才算修复完成。

| 成员 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 编辑并保存 tmux 配置后，它会自动重新加载，无需按键，也无需命令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 状态栏显示电池状态，从不阻塞状态栏渲染 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 状态栏显示每个已连接的蓝牙设备及其电量，不阻塞渲染 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | **本插件**，在 tmux 状态栏显示 CPU 负载、温度和频率，从不阻塞渲染 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 状态栏显示磁盘用量，从不阻塞状态栏渲染 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 从屏幕上挑选 URL、路径、哈希或任意其他词元，并输入到光标处，全部用纯 shell 实现 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在弹出窗口中的 fzf 选择器里切换、关闭、重命名或创建 tmux 会话、窗口和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 状态栏中显示活动窗格的 git 分支、改动和托管平台计数，且不阻塞渲染 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 状态栏中显示 NVIDIA、AMD、Intel 和 Apple GPU 的负载、温度、频率、功耗和显存 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 状态栏中显示当前的 Kubernetes 上下文和命名空间，不依赖 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在弹出窗口或新窗口中启动任意 TUI 应用，从当前窗格的目录开始，每个应用可配置一个按键 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 将任意窗格保存到文件：实时日志、完整回滚缓冲区或一次性截图 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 状态栏显示正在播放的曲目，从不阻塞状态栏渲染 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 状态栏显示网络吞吐量，从不阻塞渲染 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和窗口管理按键，适配 tmux 版本，兼容 vim，每个 prefix 按键都可禁用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 保存 tmux 的所有会话、窗口和窗格，按定时器自动保存，并在重启后全部恢复 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起点：共享库、bats 测试框架和 CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 状态栏中的番茄钟计时器，所有状态都保存在 tmux 选项中，不使用临时文件 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 状态栏显示内存、交换空间和内存压力，在后台采样，渲染从不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用鼠标在 tmux 状态栏上拖动窗口标签来移动该窗口 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 将鼠标滚轮交给能自行滚动的应用，其他情况下进入 tmux 复制模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和终端区分的合理默认设置，不改动你自己设置的选项 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平铺窗口管理：八种布局，包括 BSP dwindle 和 spiral，并支持撤销布局 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 状态栏中的本地时钟和世界时钟，按一天中的时段着色，并提供倒计时和夏令时提醒 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在后台从 wttr.in 获取天气并显示在状态栏，状态栏无需等待 |

<!-- family:end -->
