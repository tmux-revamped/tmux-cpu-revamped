<div align="center">

# tmux-cpu-revamped

<strong>在 tmux 狀態列顯示 CPU 負載、溫度及頻率，從不阻塞繪製。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; 繁體中文（香港）

[![Tests](https://github.com/tmux-revamped/tmux-cpu-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-cpu-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.3.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">功能</a> &nbsp;|&nbsp;
  <a href="#requirements">系統要求</a> &nbsp;|&nbsp;
  <a href="#installation">安裝</a> &nbsp;|&nbsp;
  <a href="#usage">用法</a> &nbsp;|&nbsp;
  <a href="#configuration">設定</a> &nbsp;|&nbsp;
  <a href="#key-bindings">快捷鍵</a> &nbsp;|&nbsp;
  <a href="#how-it-works">運作原理</a>
</p>

</div>

**18** 個佔位符。**2** 種繪製模式。Linux 及 macOS 上共 **7** 個溫度資料來源。CI 在 **10** 種 Linux 及 macOS 工具鏈組合上執行測試。

---

<a id="what-it-does"></a>

## 功能

插件把 `status-left` 及 `status-right` 中的 `#{cpu_*}` 佔位符替換為 CPU 負載、溫度、時脈、平均負載、核心數目、負載記錄、最繁忙的進程及 Linux 調頻策略。每個佔位符讀取快取在 tmux 選項中的值。取樣在背景進行，狀態列從不等待。不會寫入任何內容到磁碟。

它亦會以 `prefix + M-c` 開啟執行 `btop` 的詳情彈出視窗。

<a id="requirements"></a>

## 系統要求

| 工具 | 版本 | 用途 |
|:-----|:--------|:-----------|
| tmux | 3.2 或以上 | 詳情彈出視窗所用的 `display-popup` |
| bash | 3.2 或以上 | 所有腳本，包括 macOS 的 `/bin/bash` |
| `btop` | 任何 | 可選，彈出視窗的預設指令 |
| 溫度輔助工具 | 任何 | 可選，見下表 |

| 數值 | Linux，x86_64 及 arm64 | macOS Intel | macOS Apple Silicon |
|:------|:------------------------|:------------|:--------------------|
| 負載 | `/proc/stat`，相隔 0.3 秒讀取兩次 | `iostat`，其次 `top` | `iostat`，其次 `top` |
| 溫度 | 溫度區域，其次 coretemp，其次 k10temp，其次 `sensors` | `osx-cpu-temp`，其次 `istats` | `macmon` |
| 時脈 | `/proc/cpuinfo`，其次 `scaling_cur_freq` | `sysctl hw.cpufrequency` | 按晶片列出的最高時脈表 |
| 平均負載及核心數目 | `/proc/loadavg`、`/proc/cpuinfo` | `sysctl` | `sysctl` |
| 調頻策略 | `scaling_governor` | 沒有 | 沒有 |

| 平台 | 溫度輔助工具 |
|:---------|:-------------------|
| macOS Apple Silicon | `brew install macmon`，毋須 sudo 即可讀取感應器 |
| macOS Intel | `brew install osx-cpu-temp`，或 `gem install iStats` |
| Linux | 大部分機器不需要；`sensors` 後備方案需要 `lm-sensors` |

主機沒有資料來源的數值會顯示為空。`osx-cpu-temp` 及 `istats` 在 Apple Silicon 上傳回 `0.0`，插件會當作沒有讀數。執行 `src/cpu.sh doctor` 可查看本機提供了甚麼。

<a id="installation"></a>

## 安裝

### 使用 TPM

把插件及佔位符加入 `~/.tmux.conf`，然後按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-cpu-revamped'
set -g status-right '#{cpu_icon} #{cpu_percentage} #{cpu_temp}'
```

### 手動安裝

```bash
git clone https://github.com/tmux-revamped/tmux-cpu-revamped ~/.tmux/plugins/tmux-cpu-revamped
```

然後把這一行加到 `~/.tmux.conf` 中設定 `status-left` 及 `status-right` 的行之後，並重新載入 tmux：

```tmux
run-shell ~/.tmux/plugins/tmux-cpu-revamped/cpu-revamped.tmux
```

<a id="usage"></a>

## 用法

在 `status-left` 或 `status-right` 中寫入佔位符，插件載入時會替換它們。完整範例見 [`examples/status-right.tmux.conf`](examples/status-right.tmux.conf)。

```tmux
set -g status-right '#{cpu_graph} #{cpu_load_color}#{cpu_icon} #{cpu_percentage}#[default] #{cpu_temp} #{cpu_alert}'
```

| 佔位符 | 輸出 |
|:------------|:-------|
| `#{cpu_percentage}` | CPU 負載，例如 `42%` |
| `#{cpu_icon}` | 目前負載級別的圖示 |
| `#{cpu_fg_color}`、`#{cpu_bg_color}` | 目前負載級別的顏色 |
| `#{cpu_temp}` | 整數溫度，例如 `54°C` |
| `#{cpu_temp_icon}` | 目前溫度級別的圖示 |
| `#{cpu_temp_fg_color}`、`#{cpu_temp_bg_color}` | 目前溫度級別的顏色 |
| `#{cpu_freq}` | 時脈，例如 `4000MHz` |
| `#{cpu_load}`、`#{cpu_load5}`、`#{cpu_load15}` | 1、5、15 分鐘平均負載，例如 `1.23` |
| `#{cpu_count}` | 邏輯 CPU 數目 |
| `#{cpu_graph}` | 最近的負載讀數，例如 `▁▂▄▆█` |
| `#{cpu_top_process}` | 最繁忙的進程，例如 `node 42%` |
| `#{cpu_governor}` | Linux 調頻策略，例如 `performance` |
| `#{cpu_load_color}` | 按每核心 1 分鐘平均負載判斷的負載級別前景色 |
| `#{cpu_alert}` | 負載或溫度達到高門檻時為 `@cpu_revamped_alert_icon`，否則為空 |

<a id="configuration"></a>

## 設定

| 選項 | 預設值 | 意思 |
|:-------|:--------|:--------|
| `@cpu_revamped_interval` | `5` | 負載讀數保持有效的秒數 |
| `@cpu_revamped_detail_interval` | `60` | 溫度、時脈、平均負載、核心數目、最繁忙進程及調頻策略保持有效的秒數 |
| `@cpu_revamped_render` | 空 | `options` 開啟選項繪製模式，見[運作原理](#how-it-works) |
| `@cpu_revamped_throttle_when_detached` | `0` | `1` 在沒有用戶端連接時停止取樣 |
| `@cpu_revamped_percentage_format` | `%s%%` | 負載的 printf 格式 |
| `@cpu_revamped_medium_thresh`、`@cpu_revamped_high_thresh` | `30`、`80` | 中級及高級開始的負載百分比 |
| `@cpu_revamped_low_icon` | `▰▱▱` | 低負載級別的圖示 |
| `@cpu_revamped_medium_icon` | `▰▰▱` | 中負載級別的圖示 |
| `@cpu_revamped_high_icon` | `▰▰▰` | 高負載級別的圖示 |
| `@cpu_revamped_{low,medium,high}_{fg,bg}_color` | 空 | 每個負載級別的顏色 |
| `@cpu_revamped_temp_unit` | `C` | `C` 或 `F` |
| `@cpu_revamped_temp_format` | `%s°C` | 溫度的 printf 格式；單位跟隨 `@cpu_revamped_temp_unit` |
| `@cpu_revamped_temp_medium_thresh`、`@cpu_revamped_temp_high_thresh` | `65`、`80` | 溫度中級及高級開始的攝氏度數 |
| `@cpu_revamped_temp_low_icon` | 空 | 低溫級別的圖示 |
| `@cpu_revamped_temp_medium_icon` | 空 | 中溫級別的圖示 |
| `@cpu_revamped_temp_high_icon` | 空 | 高溫級別的圖示 |
| `@cpu_revamped_temp_{low,medium,high}_{fg,bg}_color` | 空 | 每個溫度級別的顏色 |
| `@cpu_revamped_freq_format` | `%sMHz` | 時脈的格式 |
| `@cpu_revamped_load_format` | `%s` | 平均負載的格式 |
| `@cpu_revamped_graph_width` | `20` | `#{cpu_graph}` 保留的讀數數目 |
| `@cpu_revamped_load_medium_ratio`、`@cpu_revamped_load_high_ratio` | `0.7`、`1.0` | `#{cpu_load_color}` 轉為中級及高級的每核心負載 |
| `@cpu_revamped_alert_icon` | `!` | `#{cpu_alert}` 的符號 |
| `@cpu_revamped_icons` | `ascii` | `nerd` 為每個指標加上 Nerd Font 字符標籤 |
| `@cpu_revamped_<metric>_label` | 空 | 值不為空時顯示在某個指標前的文字；`''` 移除 `nerd` 標籤 |
| `@cpu_revamped_fixed_width` | `off` | `on` 在左邊填充每個值至其最大寬度 |
| `@cpu_revamped_<metric>_width` | 空 | 某個指標的填充寬度，優先於固定寬度 |
| `@cpu_revamped_popup_key` | `M-c` | 詳情彈出視窗的 prefix 按鍵 |
| `@cpu_revamped_popup_command` | `btop` | 彈出視窗中執行的指令 |
| `@cpu_revamped_popup_width`、`@cpu_revamped_popup_height` | `80%`、`80%` | 彈出視窗大小 |

標籤適用於 `percentage`、`temp`、`freq`、`load`、`load5`、`load15`、`count`、`graph`、`top_process` 及 `governor`。寬度設定不會截短較長的值。

### 主題配色

顏色選項預設為空，因此設定之前插件不會加上顏色。以下每個配色把低、中、高三級分別設為綠色、黃色及紅色：

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

### 內部狀態

以下選項由插件自行寫入，請勿設定。

| 選項 | 內容 |
|:-------|:------|
| `@cpu_revamped_published` | 載入時在 `status-left` 及 `status-right` 中找到的指標，即選項模式要發佈的指標 |
| `@cpu_revamped_out_<metric>` | 選項模式中每個指標發佈的值 |
| `@cpu_revamped_ticker_pid` | 選項模式背景進程的 pid |
| `@cpu_revamped_option_names` | 背景進程每個週期以一次呼叫讀取的選項 |
| `@cpu_revamped_history` | `#{cpu_graph}` 所用的最近負載讀數 |
| `@cpu_revamped_{percent,temp,freq,load,load5,load15,count,top_process,governor}` | 快取的讀數，各附一個 `_ts` 時間戳記，`percent` 另有 `_lock` |

<a id="key-bindings"></a>

## 快捷鍵

| 按鍵 | 操作 | 選項 |
|:----|:-------|:-------|
| `prefix + M-c` | 開啟執行 `@cpu_revamped_popup_command` 的彈出視窗 | `@cpu_revamped_popup_key` |

在低於 3.2 的 tmux 上，該按鍵會顯示一則訊息，而不是彈出視窗。

<a id="how-it-works"></a>

## 運作原理

在預設的工作模式中，每個佔位符都會變成呼叫 [`src/cpu.sh`](src/cpu.sh) 的 `#()`。呼叫會立即輸出快取的值。當快取的負載比 `@cpu_revamped_interval` 舊時，它亦會啟動一次背景更新；更新受鎖保護，並行的呼叫不會再啟動第二次。

tmux 每次重繪狀態列都會執行所有 `#()`。一條狀態列上有多個插件時，大約每秒一次。選項模式取消了這些呼叫：

```tmux
set -g @cpu_revamped_render 'options'
set -g @cpu_revamped_fixed_width 'on'
```

此時每個佔位符會變成類似 `#{E:@cpu_revamped_out_percentage}` 的選項讀取。每個伺服器有一個背景進程，每 `@cpu_revamped_interval` 秒取樣一次 CPU，以一次 tmux 呼叫寫入狀態列用到的所有值，然後只重繪一次。伺服器停止，或重新載入設定啟動了接替的進程時，它便會結束。切回工作模式亦會釋放它。

最繁忙進程的名稱在快取前會把每個 `#` 加倍，因此名稱像 tmux 格式的進程亦只會顯示為文字。

<a id="development"></a>

## 開發

| 指令 | 執行內容 |
|:--------|:-------------|
| `make test` | [`test/`](test) 下的 bats 測試 |
| `make lint` | 對所有 shell 檔案執行 shellcheck |
| `make coverage` | 在 Linux 上以 kcov 計算行覆蓋率，低於 95% 時失敗 |

<a id="license"></a>

## 授權

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

這個插件是 tmux-revamped 插件家族的一員。每個成員都帶有 [`FAMILY.md`](FAMILY.md) 中相同的約定、`family/` 下相同的工具及相同的共用程式庫，並由校驗和清單保持逐位元組一致。它們以一同安裝為設計前提：任何成員都不會佔用其他成員已佔用的按鍵或 tmux 選項。

在一個成員中發現的缺陷，要在所有成員中排查之後，修正才算完成。這項責任寫在約定之中，而不是靠記憶，並透過 `family/bin/sweep` 履行。

| 成員 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 編輯並儲存 tmux 設定後自動重新載入，毋須按鍵，也毋須指令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 狀態列顯示電池狀態，從不阻塞狀態列繪製 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 狀態列顯示每部已連接的藍牙裝置及其電量，不阻塞繪製 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | **本插件**，在 tmux 狀態列顯示 CPU 負載、溫度及頻率，從不阻塞繪製 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 狀態列顯示磁碟用量，從不阻塞狀態列繪製 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 以 fzf 從螢幕上揀選 URL、路徑、雜湊或其他片段，並在游標處輸入，純 shell 實作 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在彈出視窗的 fzf 選擇器中切換、關閉、重新命名或新增 tmux 工作階段、視窗及窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 狀態列顯示目前窗格的 git 分支、改動及託管平台計數，不阻塞狀態列 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 狀態列顯示 NVIDIA、AMD、Intel 及 Apple GPU 的負載、溫度、時脈、功耗及記憶體 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 不借助 kubectl，從 kubeconfig 解析目前的 Kubernetes 環境及命名空間，顯示在 tmux 狀態列 |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在彈出視窗或視窗中啟動任何 TUI 應用程式，工作目錄為目前窗格的目錄，按鍵可設定 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 把任何窗格儲存到檔案：即時記錄、完整回捲記錄或單次截圖 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 狀態列顯示正在播放的曲目，從不阻塞狀態列繪製 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 狀態列顯示網絡吞吐量，從不阻塞繪製 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的標準窗格及視窗管理快捷鍵，按版本調整，貼合 vim 習慣，全部可設定 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 儲存所有 tmux 工作階段、視窗及窗格，定時自動儲存，並在重新開機後全部還原 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起點：共用程式庫、bats 測試框架、CI 及家族工具 |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | 顯示在 tmux 狀態列的番茄鐘，所有狀態都儲存在 tmux 選項中，不使用暫存檔 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 狀態列顯示記憶體、交換空間及記憶體壓力，在背景取樣，繪製從不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 以滑鼠沿 tmux 狀態列拖動視窗標籤，以移動該視窗 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 把滑鼠滾輪交給能自行捲動的應用程式，其他情況下進入 tmux 複製模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本及終端機啟用的合理預設設定，不改動你自行設定的選項 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平鋪視窗管理：8 種版面，包括 BSP 的 dwindle 及 spiral，並支援還原版面 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 在 tmux 狀態列顯示本地時鐘及世界時鐘，按時段著色，附倒數及夏令時間提示 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在 tmux 狀態列顯示來自 wttr.in 的天氣，在背景擷取，狀態列從不等待 |

### 檢查安裝

所有成員都在磁碟上時，一個指令即可報告它們之間的衝突：

```sh
family/bin/doctor --live
```

它讀取每個成員及正在運行的 tmux 伺服器，報告重複的按鍵、重複的狀態列佔位符、不符合命名規則的選項，以及約定版本落後的成員。

<!-- family:end -->
