<div align="center">

# tmux-cpu-revamped

<strong>在 tmux 狀態列顯示 CPU 負載、溫度和頻率，絕不阻塞繪製。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; 繁體中文（香港）

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-cpu-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-cpu-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-cpu-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-cpu-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-cpu-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-cpu-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-cpu-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#快速開始"><strong>快速開始</strong></a> &nbsp;|&nbsp;
  <a href="#用法">用法</a> &nbsp;|&nbsp;
  <a href="#運作原理">運作原理</a> &nbsp;|&nbsp;
  <a href="#畫面">畫面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="cpu-revamped 按級別顏色顯示負載和溫度，開啟監察工具彈出視窗，並切換到 Nerd Font 標籤、圖表和 options 繪製模式" width="800">
</p>

```console
$ cpu-revamped refresh
Refreshed. 31% of the CPU is busy.
$ cpu-revamped status percentage
31%
```

**18** 個佔位符，**2** 種繪製模式，支援 macOS 和 Linux，需要 tmux **3.2** 或更新版本。

---

## 快速開始

### 前提條件

| 工具 | 版本 | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 或更新版本 | 家族的最低版本，彈出視窗也需要它 |
| btop, htop | 可選 | 彈出視窗開啟的監察工具；沒有時執行 `top` |
| gum | 可選 | `cpu-revamped` 的選單、表格和顏色；沒有它時所有指令輸出純文字 |

它在 Linux 和 macOS 上執行，BSD、GNU、uutils 或 BusyBox 工具均可。每個數值都來自系統自帶的來源：

| 數值 | Linux | macOS Intel | macOS Apple Silicon |
|:-----|:------|:------------|:--------------------|
| 負載 | `/proc/stat`，相隔 0.3 秒讀兩次 | `iostat`，其次 `top` | `iostat`，其次 `top` |
| 溫度 | thermal zone，其次 coretemp、k10temp、`sensors` | `osx-cpu-temp`，其次 `istats` | `macmon` |
| 頻率 | `/proc/cpuinfo`，其次 `scaling_cur_freq` | `sysctl hw.cpufrequency` | 按晶片世代查表得到的頻率 |
| 平均負載 | `/proc/loadavg` | `sysctl vm.loadavg` | `sysctl vm.loadavg` |
| 核心數 | `/proc/cpuinfo` | `sysctl hw.ncpu` | `sysctl hw.ncpu` |
| 調速器 | `scaling_governor` | 無 | 無 |
| 最忙的進程 | `ps` | `ps` | `ps` |

| 平台 | 溫度工具 |
|:-----|:---------|
| macOS Apple Silicon | `brew install macmon`，毋須 sudo 即可讀取感應器 |
| macOS Intel | `brew install osx-cpu-temp`，或 `gem install iStats` |
| Linux | 大部分機器不需要；使用 `sensors` 後備來源時安裝 `lm-sensors` |

缺少來源時，對應的佔位符為空，`cpu-revamped doctor` 會指出是哪一個。`osx-cpu-temp` 和 `istats` 在 Apple Silicon 上返回 `0.0`，這被視為沒有讀數。

### 安裝

使用 [TPM](https://github.com/tmux-plugins/tpm) 時，將插件加入 `~/.tmux.conf`，然後按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-cpu-revamped'
```

手動安裝時，複製儲存庫，並在 `~/.tmux.conf` 中執行入口腳本：

```bash
git clone https://github.com/tmux-revamped/tmux-cpu-revamped ~/.tmux/plugins/tmux-cpu-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-cpu-revamped/cpu-revamped.tmux
```

請在插件載入之前設定 `status-left` 或 `status-right`。插件只在載入時替換一次其中的佔位符。

在複製的目錄中執行 `make install`，亦會把 `cpu-revamped` 放入 `~/.local/bin`，並把它的 man 手冊和自動完成放在 `~/.local/share` 下。

### 驗證

```bash
~/.tmux/plugins/tmux-cpu-revamped/bin/cpu-revamped doctor
```

## 用法

本插件顯示 CPU 的忙碌程度，以及溫度、頻率、平均負載、核心數、最近負載的圖表、最忙的進程，在 Linux 上還有調速器。狀態列顯示 tmux 已經儲存的值，背景取樣負責更新它。

| 佔位符 | 輸出 |
|:-------|:-----|
| `#{cpu_percentage}` | CPU 負載，例如 `42%` |
| `#{cpu_icon}` | 負載的級別圖示 |
| `#{cpu_fg_color}` | 負載級別的前景樣式 |
| `#{cpu_bg_color}` | 負載級別的背景樣式 |
| `#{cpu_temp}` | 整數度的溫度，例如 `54°C` |
| `#{cpu_temp_icon}` | 溫度的級別圖示 |
| `#{cpu_temp_fg_color}` | 溫度級別的前景樣式 |
| `#{cpu_temp_bg_color}` | 溫度級別的背景樣式 |
| `#{cpu_freq}` | 以兆赫為單位的頻率，例如 `4000MHz` |
| `#{cpu_load}` | 一分鐘平均負載，例如 `1.23` |
| `#{cpu_load5}` | 五分鐘平均負載 |
| `#{cpu_load15}` | 十五分鐘平均負載 |
| `#{cpu_count}` | 邏輯 CPU 數 |
| `#{cpu_graph}` | 最近負載取樣的迷你圖，例如 `▁▂▄▆█` |
| `#{cpu_top_process}` | 佔用 CPU 最多的進程，例如 `node 42%` |
| `#{cpu_governor}` | Linux 的頻率調速器，例如 `performance`；在 macOS 上為空 |
| `#{cpu_load_color}` | 按每核一分鐘平均負載判斷的負載級別前景樣式 |
| `#{cpu_alert}` | 負載或溫度達到其高閾值時為 `@cpu_revamped_alert_icon`，否則為空 |

在狀態列中放入佔位符：

```tmux
set -g @cpu_revamped_low_fg_color '#[fg=green]'
set -g @cpu_revamped_medium_fg_color '#[fg=yellow]'
set -g @cpu_revamped_high_fg_color '#[fg=red]'

set -g status-right '#{cpu_fg_color}#{cpu_icon} #{cpu_percentage}#[default] #{cpu_temp} '
```

同一個例子，加上幾個選項，在 [examples/status-right.tmux.conf](examples/status-right.tmux.conf) 中。

### 標籤和闊度

`@cpu_revamped_<metric>_label` 在某個指標的值非空時，在它前面列印一個圖示或詞。`@cpu_revamped_icons` 設為 `nerd` 時，下面每個指標前都有 Nerd Font 字形標籤。指標自己的標籤優先於這組字形，設為空的標籤表示預設值，所以字形保留。預設的 `ascii` 不加標籤。

| 指標 | `nerd` 字形 |
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

`@cpu_revamped_fixed_width` 設為 `on` 時，每個數值在左側補齊到其自然闊度：負載 4 個字元，溫度和平均負載 5 個字元，頻率 7 個字元，核心數 3 個字元，所以由 `9%` 變成 `42%` 不會令這一行的其餘部分移位。`@cpu_revamped_<metric>_width` 設定某個指標的闊度，並優先於固定闊度。過長的值不會被截斷。

### 繪製模式

預設情況下，每個佔位符變成一個 `#()` 呼叫，tmux 在狀態列重繪時重新執行它。把 `@cpu_revamped_render` 設為 `options` 後，每個佔位符變成對選項的讀取，例如 `#{E:@cpu_revamped_out_percentage}`。每個伺服器隨後有一個背景進程每隔 `@cpu_revamped_interval` 秒取樣一次，並用一次 tmux 呼叫寫入所有數值，所以它們一起變化。

```tmux
set -g @cpu_revamped_render 'options'
set -g @cpu_revamped_fixed_width 'on'
```

### 級別顏色

級別樣式預設為空，所以在你設定之前，`#{cpu_fg_color}`、`#{cpu_bg_color}`、`#{cpu_temp_fg_color}`、`#{cpu_temp_bg_color}` 和 `#{cpu_load_color}` 甚麼也不輸出。下面的配色把 low 對應為綠色，medium 為黃色，high 為紅色：

| 主題 | 低 | 中 | 高 |
|:-----|:---|:---|:---|
| Catppuccin Mocha | `#a6e3a1` | `#f9e2af` | `#f38ba8` |
| Dracula | `#50fa7b` | `#f1fa8c` | `#ff5555` |
| Nord | `#a3be8c` | `#ebcb8b` | `#bf616a` |
| Gruvbox Dark | `#b8bb26` | `#fabd2f` | `#fb4934` |
| Tokyo Night | `#9ece6a` | `#e0af68` | `#f7768e` |
| Solarized Dark | `#859900` | `#b58900` | `#dc322f` |

每個值寫成一個樣式，例如 `set -g @cpu_revamped_low_fg_color '#[fg=#a6e3a1]'`。溫度級別用同樣的樣式，寫在 `@cpu_revamped_temp_<tier>_fg_color` 下。

| 指令 | 作用 |
|:-----|:-----|
| `cpu-revamped apply` | 綁定彈出視窗按鍵並立即填充佔位符；tmux 載入插件時由入口腳本執行它 |
| `cpu-revamped list` | 列印 `apply` 會送出的每條指令，不作任何更改；`--json` 列印一個物件 |
| `cpu-revamped status NAME` | 列印一個佔位符，例如 `percentage`、`temp` 或 `graph`；狀態列執行它 |
| `cpu-revamped refresh` | 立即取樣 CPU，並說明它有多忙 |
| `cpu-revamped card` | 立即讀取所有內容，每個數值列印一行 |
| `cpu-revamped popup` | 在 tmux 彈出視窗中開啟 CPU 監察工具：彈出視窗指令，否則 btop，否則 htop，否則 top；彈出視窗按鍵執行它 |
| `cpu-revamped daemon` | 在每個週期發佈佔位符，供 `options` 繪製模式使用；`apply` 會啟動它 |
| `cpu-revamped doctor` | 每個依賴一行：每個數值的來源工具或檔案、彈出視窗開啟的監察工具，以及被放過的按鍵 |
| `cpu-revamped version` | 版本，然後是 tmux 版本 |
| `cpu-revamped help` | 說明頁；`man cpu-revamped` 記錄同樣的指令和設定 |
| `cpu-revamped` | 在終端機中顯示選單 |

## 設定

每個選項也是帶連字號的指令選項，例如 `--interval 2`，以及環境變數，例如 `CPU_REVAMPED_INTERVAL`；指令列優先於環境變數，環境變數優先於 tmux 選項。空的 tmux 選項表示預設值。`doctor` 會指出持有插件不認識的值的設定。傳給 `apply` 的選項會帶到彈出視窗按鍵和每一次狀態呼叫中。

### 取樣

| 選項 | 預設值 | 含義 |
|:-----|:-------|:-----|
| `@cpu_revamped_interval` | `5` | 負載取樣保持新鮮的秒數 |
| `@cpu_revamped_detail_interval` | `60` | 溫度、頻率、平均負載、核心數、最忙的進程和調速器保持新鮮的秒數 |
| `@cpu_revamped_throttle_when_detached` | `0` | `1` 表示沒有客戶端連接時停止取樣；狀態列保留最後一次取樣 |
| `@cpu_revamped_render` | `jobs` | `options` 讀取已發佈的選項，而不是執行 `#()` 呼叫；其他任何值都表示 `jobs` |
| `@cpu_revamped_graph_width` | `20` | `#{cpu_graph}` 保留的取樣數 |

### 級別和警報

| 選項 | 預設值 | 含義 |
|:-----|:-------|:-----|
| `@cpu_revamped_medium_thresh` | `30` | 級別變為 medium 的負載百分比 |
| `@cpu_revamped_high_thresh` | `80` | 級別變為 high 的負載百分比，也是 `#{cpu_alert}` 出現的百分比 |
| `@cpu_revamped_low_icon` | `▰▱▱` | low 負載級別的圖示 |
| `@cpu_revamped_medium_icon` | `▰▰▱` | medium 負載級別的圖示 |
| `@cpu_revamped_high_icon` | `▰▰▰` | high 負載級別的圖示 |
| `@cpu_revamped_low_fg_color` | 空 | low 負載級別的前景樣式，例如 `#[fg=green]` |
| `@cpu_revamped_medium_fg_color` | 空 | medium 負載級別的前景樣式 |
| `@cpu_revamped_high_fg_color` | 空 | high 負載級別的前景樣式 |
| `@cpu_revamped_low_bg_color` | 空 | low 負載級別的背景樣式 |
| `@cpu_revamped_medium_bg_color` | 空 | medium 負載級別的背景樣式 |
| `@cpu_revamped_high_bg_color` | 空 | high 負載級別的背景樣式 |
| `@cpu_revamped_temp_medium_thresh` | `65` | 溫度級別變為 medium 的攝氏度數 |
| `@cpu_revamped_temp_high_thresh` | `80` | 溫度級別變為 high 的攝氏度數，也是 `#{cpu_alert}` 出現的度數 |
| `@cpu_revamped_temp_low_icon` | 空 | low 溫度級別的圖示 |
| `@cpu_revamped_temp_medium_icon` | 空 | medium 溫度級別的圖示 |
| `@cpu_revamped_temp_high_icon` | 空 | high 溫度級別的圖示 |
| `@cpu_revamped_temp_low_fg_color` | 空 | low 溫度級別的前景樣式 |
| `@cpu_revamped_temp_medium_fg_color` | 空 | medium 溫度級別的前景樣式 |
| `@cpu_revamped_temp_high_fg_color` | 空 | high 溫度級別的前景樣式 |
| `@cpu_revamped_temp_low_bg_color` | 空 | low 溫度級別的背景樣式 |
| `@cpu_revamped_temp_medium_bg_color` | 空 | medium 溫度級別的背景樣式 |
| `@cpu_revamped_temp_high_bg_color` | 空 | high 溫度級別的背景樣式 |
| `@cpu_revamped_load_medium_ratio` | `0.7` | `#{cpu_load_color}` 變為 medium 的每核平均負載 |
| `@cpu_revamped_load_high_ratio` | `1.0` | `#{cpu_load_color}` 變為 high 的每核平均負載 |
| `@cpu_revamped_alert_icon` | `!` | `#{cpu_alert}` 列印的內容 |

### 格式和標籤

| 選項 | 預設值 | 含義 |
|:-----|:-------|:-----|
| `@cpu_revamped_temp_unit` | `C` | `C` 或 `F` |
| `@cpu_revamped_percentage_format` | `%s%%` | 負載的 printf 格式 |
| `@cpu_revamped_temp_format` | `%s°C` | 溫度的 printf 格式；單位跟隨 `@cpu_revamped_temp_unit` |
| `@cpu_revamped_freq_format` | `%sMHz` | 頻率的 printf 格式 |
| `@cpu_revamped_load_format` | `%s` | 三個平均負載的 printf 格式 |
| `@cpu_revamped_icons` | `ascii` | `nerd` 為每個值加上 Nerd Font 字形標籤 |
| `@cpu_revamped_<metric>_label` | 空 | 在某個值前面列印的文字，僅當該值非空時 |
| `@cpu_revamped_fixed_width` | `off` | `on` 把每個數值補齊到自然闊度，使 `9%` 變成 `42%` 時狀態列不會移位 |
| `@cpu_revamped_<metric>_width` | 空 | 把某個值補齊到這麼多個字元；過長的值不會被截斷 |

可以帶標籤和闊度的指標是 `percentage`、`temp`、`freq`、`load`、`load5`、`load15`、`count`、`graph`、`top_process` 和 `governor`。

### 彈出視窗

| 選項 | 預設值 | 含義 |
|:-----|:-------|:-----|
| `@cpu_revamped_popup_key` | `M-c` | 開啟詳情彈出視窗的前綴鍵；`off` 表示不綁定 |
| `@cpu_revamped_popup_command` | 依次為 btop、htop、top | 彈出視窗執行的指令，可帶參數；未安裝的指令會在訊息中點名 |
| `@cpu_revamped_popup_width` | `80%` | 彈出視窗闊度 |
| `@cpu_revamped_popup_height` | `80%` | 彈出視窗高度 |

### 內部狀態

插件自己寫入這些選項，請勿設定它們。

| 選項 | 儲存的內容 |
|:-----|:-----------|
| `@cpu_revamped_published` | 狀態列使用的指標，在載入時記錄，使 options 模式只寫入這些 |
| `@cpu_revamped_history` | `#{cpu_graph}` 背後的最近負載取樣 |
| `@cpu_revamped_out_<metric>` | options 模式下每個指標的繪製結果 |
| `@cpu_revamped_ticker_pid` | options 模式背景進程的進程號 |
| `@cpu_revamped_percent` 和其他數值、`_ts`、`_lock` | 儲存的取樣、每次讀取的時間和更新鎖 |

## 按鍵綁定

| 按鍵 | 動作 | 預設 |
|:-----|:-----|:-----|
| `prefix + M-c` | 在彈出視窗中開啟 CPU 監察工具：你指定的指令，否則 btop，否則 htop，否則 top | 已綁定 |

`@cpu_revamped_popup_key` 可指定另一個按鍵，`off` 表示不綁定。預設按鍵已被其他綁定佔用時會被放過，`cpu-revamped doctor` 會說明。

<a id="運作原理"></a>

## 運作原理

tmux 載入插件時，[`cpu-revamped.tmux`](cpu-revamped.tmux) 執行一次。它把 `status-left` 和 `status-right` 用到的指標記錄在 `@cpu_revamped_published` 中，然後把每個佔位符替換為對 [`bin/cpu-revamped`](bin/cpu-revamped) 的呼叫；在 `options` 模式下則替換為選項讀取，並啟動背景進程。

在預設模式下，每個 `#()` 呼叫立即返回已儲存的取樣。取樣比間隔舊時，呼叫會在背景啟動更新並加鎖，所以同一時間只有一個更新在執行。在 Linux 上，負載是相隔 0.3 秒讀取兩次 `/proc/stat` 得到的忙碌比例，iowait 算作閒置。在 macOS 上，負載是 100 減去 `iostat` 的閒置比例，缺少 `iostat` 時改用 `top`。一個 `awk` 把讀數變成所有數值，一次 tmux 呼叫把它們儲存。溫度、頻率、平均負載、最忙的進程和調速器的讀取成本較高，所以只為狀態列用到的佔位符、每隔 `@cpu_revamped_detail_interval` 秒讀取一次。

溫度來自第一個有回應的來源：在 Linux 上依次是 thermal zone、coretemp、k10temp 和 `sensors`；在 Apple Silicon 上是 `macmon`，在 Mac 上之後是 `osx-cpu-temp` 和 `istats`。最忙進程的名稱來自 `ps`，任何用戶都能控制它，所以其中的每個 `#` 在到達狀態列之前都會加倍。讀取、取樣和格式化位於 [`lib/cpu.sh`](lib/cpu.sh)，設定表位於 [`lib/state.sh`](lib/state.sh)。

<a id="畫面"></a>

## 畫面

<details>
<summary>每個畫面都在真實的 tmux 中用 <code>make screens</code> 錄製，狀態列上顯示每個按鍵</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="cpu-revamped: 帶級別圖示和顏色的負載、溫度、頻率、平均負載和警報"><br><sub>帶級別圖示和顏色的負載、溫度、頻率、平均負載和警報, 來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/popup.png" alt="cpu-revamped: prefix M-c 在彈出視窗中開啟 CPU 監察工具"><br><sub><code>prefix M-c</code> 在彈出視窗中開啟 CPU 監察工具, 來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/icons.png" alt="cpu-revamped: @cpu_revamped_icons 設為 nerd 時，每個指標前都有字形標籤"><br><sub><code>@cpu_revamped_icons</code> 設為 <code>nerd</code> 時，每個指標前都有字形標籤, 來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/graph.png" alt="cpu-revamped: 圖表、負載和最忙的進程"><br><sub>圖表、負載和最忙的進程, 來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="cpu-revamped: 在 options 繪製模式下，每個佔位符讀取一個 tmux 選項"><br><sub>在 <code>options</code> 繪製模式下，每個佔位符讀取一個 tmux 選項, 來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/card.png" alt="cpu-revamped: card 列印每個數值"><br><sub><code>card</code> 列印每個數值, 來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/temp.png" alt="cpu-revamped: 帶級別圖示和顏色的溫度，以及警報"><br><sub>帶級別圖示和顏色的溫度，以及警報, 來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/unit.png" alt="cpu-revamped: @cpu_revamped_temp_unit 設為 F"><br><sub><code>@cpu_revamped_temp_unit</code> 設為 <code>F</code>, 來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/load.png" alt="cpu-revamped: 三個平均負載、核心數和負載顏色"><br><sub>三個平均負載、核心數和負載顏色, 來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/load-format.png" alt="cpu-revamped: @cpu_revamped_load_format 決定平均負載的格式"><br><sub><code>@cpu_revamped_load_format</code> 決定平均負載的格式, 來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/ratios.png" alt="cpu-revamped: @cpu_revamped_load_medium_ratio 和 @cpu_revamped_load_high_ratio 移動負載顏色的分界"><br><sub><code>@cpu_revamped_load_medium_ratio</code> 和 <code>@cpu_revamped_load_high_ratio</code> 移動負載顏色的分界, 來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/clock.png" alt="cpu-revamped: 頻率、調速器和最忙的進程"><br><sub>頻率、調速器和最忙的進程, 來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/freq-format.png" alt="cpu-revamped: @cpu_revamped_freq_format 決定頻率的格式"><br><sub><code>@cpu_revamped_freq_format</code> 決定頻率的格式, 來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/format.png" alt="cpu-revamped: @cpu_revamped_percentage_format 決定負載百分比的格式"><br><sub><code>@cpu_revamped_percentage_format</code> 決定負載百分比的格式, 來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/fixed.png" alt="cpu-revamped: @cpu_revamped_fixed_width 把每個數值補齊到其自然闊度"><br><sub><code>@cpu_revamped_fixed_width</code> 把每個數值補齊到其自然闊度, 來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/width.png" alt="cpu-revamped: @cpu_revamped_count_width 把一個指標補齊到指定闊度"><br><sub><code>@cpu_revamped_count_width</code> 把一個指標補齊到指定闊度, 來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/labels.png" alt="cpu-revamped: 某個指標前面的自訂標籤"><br><sub>某個指標前面的自訂標籤, 來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/tiers.png" alt="cpu-revamped: @cpu_revamped_medium_thresh 和 @cpu_revamped_high_thresh 移動級別的分界"><br><sub><code>@cpu_revamped_medium_thresh</code> 和 <code>@cpu_revamped_high_thresh</code> 移動級別的分界, 來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/graph-width.png" alt="cpu-revamped: @cpu_revamped_graph_width 決定圖表保留多少個取樣"><br><sub><code>@cpu_revamped_graph_width</code> 決定圖表保留多少個取樣, 來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/popup-key.png" alt="cpu-revamped: @cpu_revamped_popup_key 為彈出視窗指定另一個按鍵"><br><sub><code>@cpu_revamped_popup_key</code> 為彈出視窗指定另一個按鍵, 來自 <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/popup-command.png" alt="cpu-revamped: @cpu_revamped_popup_command 指定彈出視窗執行的指令及其大小"><br><sub><code>@cpu_revamped_popup_command</code> 指定彈出視窗執行的指令及其大小, 來自 <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/status-command.png" alt="cpu-revamped: status percentage 和 status graph 各列印一個佔位符"><br><sub><code>status percentage</code> 和 <code>status graph</code> 各列印一個佔位符, 來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/refresh.png" alt="cpu-revamped: refresh 立即取樣 CPU"><br><sub><code>refresh</code> 立即取樣 CPU, 來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="cpu-revamped: list 列印每個綁定"><br><sub><code>list</code> 列印每個綁定, 來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/json.png" alt="cpu-revamped: list --json 把同一份計劃列印成一個物件"><br><sub><code>list --json</code> 把同一份計劃列印成一個物件, 來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="cpu-revamped: doctor"><br><sub><code>doctor</code>, 來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu.png" alt="cpu-revamped: 選單"><br><sub>選單, 來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/menu-card.png" alt="cpu-revamped: 從選單開啟的卡片"><br><sub>從選單開啟的卡片, 來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/accent.png" alt="cpu-revamped: 來自 CPU_REVAMPED_ACCENT 的強調色"><br><sub>來自 <code>CPU_REVAMPED_ACCENT</code> 的強調色, 來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="cpu-revamped: 沒有 gum 的選單"><br><sub>沒有 gum 的選單, 來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="cpu-revamped: 從選單執行的 doctor，沒有 gum"><br><sub>從選單執行的 <code>doctor</code>，沒有 gum, 來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-card.png" alt="cpu-revamped: 沒有 gum 的 card"><br><sub>沒有 gum 的 <code>card</code>, 來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/version.png" alt="cpu-revamped: 版本"><br><sub>版本, 來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/error.png" alt="cpu-revamped: 未知指令"><br><sub>未知指令, 來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="cpu-revamped: 六種主題下的標題"><br><sub>六種主題下的標題, 來自 <code>themes.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="cpu-revamped: 說明頁"><br><sub>說明頁, 來自 <code>help.tape</code></sub></td>
</tr>
</table>

錄製時執行的是真實的插件和 tmux。`iostat`、`sysctl`、`macmon`、`osx-cpu-temp`、`ps` 和 `top` 由小腳本代替，所以畫面上的數值來自這些腳本。錄製在 macOS 上進行，它沒有調速器，所以 `#{cpu_governor}` 在那裏甚麼也不顯示。

</details>

## 可攜性

插件是 POSIX `sh`。CI 在下列每一行上執行全部測試。

| Shell | 狀態 |
|:------|:-------|
| `dash`、macOS 上的 `/bin/sh` | 支援 |
| `bash` 3.2 和 5.x、系統內建的 `zsh` 和 Homebrew 的 `zsh` | 支援 |

| 系統 | 狀態 |
|:-------|:-------|
| macOS | Apple Silicon 和 Intel 上的 Tahoe，使用內建的工具、Homebrew 的 GNU 工具和 Homebrew 的 uutils |
| Linux | x86_64 和 arm64 上的 Ubuntu 26.04，使用 GNU coreutils、uutils 和 BusyBox |

## 開發

| 指令 | 執行內容 |
|:--------|:-------------|
| `make fmt` | 對每個腳本執行 shfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint 和 actionlint，零警告 |
| `make test` | 在系統 `sh` 下執行 bats 測試 |
| `make test-all` | 在每個已安裝的 shell 下執行測試，macOS 上包括 bash 和 zsh 的兩種版本 |
| `make test-linux` | 在 Ubuntu 容器中執行測試 |
| `make coverage` | 在這部 Mac 和 Ubuntu 容器中執行 bashcov，合併後以 100% 為門檻 |
| `make screens` | 以 VHS 在 tmux 中從真實插件錄製上述畫面，在 macOS 上執行 |
| `make install` | 把指令、man 手冊和自動完成安裝到 `PREFIX` 下 |

在 macOS 上，執行 `brew bundle` 會根據 [`Brewfile`](Brewfile) 安裝這些目標用到的所有工具。

提交遵循 Conventional Commits 格式，直接進入 `main`。`main` 上的 `ci` 通過後，`release.yml` 會執行 semantic-release：自上一個標籤以來的每個 `feat` 或 `fix` 都會發佈新版本，更新版本常數，並把說明寫入 [`CHANGELOG.md`](CHANGELOG.md)。

## 授權

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

這個插件是 tmux-revamped 插件家族的一員。每個成員都帶有 [`FAMILY.md`](FAMILY.md) 中相同的約定和相同的共用程式庫，並且設計為一起安裝：沒有成員佔用另一個成員佔用的按鍵或 tmux 選項。

在一個成員中發現的缺陷，要在全部成員中排查後才算修正完成。

| 成員 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 編輯並儲存 tmux 設定後，它會自動重新載入，毋須按鍵，也毋須指令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 狀態列顯示電池狀態，從不阻塞狀態列繪製 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 狀態列顯示每部已連接的藍牙裝置及其電量，不阻塞繪製 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | **本插件**，在 tmux 狀態列顯示 CPU 負載、溫度及頻率，從不阻塞繪製 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 狀態列顯示磁碟用量，從不阻塞狀態列繪製 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 從畫面上揀選 URL、路徑、雜湊值或任何其他字詞，並輸入到游標位置，全部以純 shell 實現 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在彈出視窗的 fzf 選擇器中切換、關閉、重新命名或建立 tmux 工作階段、視窗和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 狀態列顯示當前窗格的 git 分支、改動和託管平台數目，而不會阻塞顯示 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 狀態列顯示 NVIDIA、AMD、Intel 及 Apple GPU 的負載、溫度、時脈、功耗及記憶體 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 狀態列顯示目前的 Kubernetes 上下文及命名空間，毋須 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在彈出視窗或新視窗中啟動任何 TUI 應用程式，從目前窗格的目錄開始，每個應用程式可設定一個按鍵 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 將任何窗格儲存到檔案：即時記錄、完整捲動緩衝區或一次性截圖 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 狀態列顯示正在播放的歌曲，從不阻塞狀態列的繪製 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 狀態列顯示網絡傳輸量，從不阻塞繪製 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和視窗管理按鍵，配合 tmux 版本，與 vim 相容，每個 prefix 按鍵都可停用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 儲存 tmux 的所有工作階段、視窗及窗格，按計時器自動儲存，並在重新開機後全部還原 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起點：共用程式庫、bats 測試框架和 CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 狀態列中的番茄鐘計時器，所有狀態都儲存在 tmux 選項中，不使用暫存檔 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 狀態列顯示記憶體、交換空間及記憶體壓力，在背景取樣，繪製從不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用滑鼠在 tmux 狀態列上拖動視窗標籤來移動該視窗 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 將滑鼠滾輪交給能自行捲動的應用程式，其他情況下進入 tmux 複製模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和終端機區分的合理預設設定，不會改動你自己設定的選項 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平鋪視窗管理：八種版面，包括 BSP dwindle 和 spiral，並支援復原版面 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 狀態列中的本地時鐘和世界時鐘，按一天中的時段著色，並提供倒數和夏令時間提示 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在背景從 wttr.in 取得天氣並顯示在狀態列，狀態列毋須等待 |

<!-- family:end -->
