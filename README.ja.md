<div align="center">

# tmux-cpu-revamped

<strong>CPUの負荷、温度、周波数をtmuxのステータスバーに表示し、描画を一切止めません。</strong>

[English](README.md) &nbsp;|&nbsp; 日本語 &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-cpu-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-cpu-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-cpu-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-cpu-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-cpu-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-cpu-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-cpu-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#クイックスタート"><strong>クイックスタート</strong></a> &nbsp;|&nbsp;
  <a href="#使い方">使い方</a> &nbsp;|&nbsp;
  <a href="#仕組み">仕組み</a> &nbsp;|&nbsp;
  <a href="#画面">画面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="段階ごとの色で負荷と温度を表示し、モニターのポップアップを開き、Nerd Font のラベル、グラフ、options 描画モードに切り替える cpu-revamped" width="800">
</p>

```console
$ cpu-revamped refresh
Refreshed. 31% of the CPU is busy.
$ cpu-revamped status percentage
31%
```

プレースホルダー **18** 個、描画モード **2** つ、macOS と Linux、tmux **3.2** 以降。

---

## クイックスタート

### 前提条件

| ツール | バージョン | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 以降 | ファミリー共通の最低バージョン。ポップアップにも必要です |
| btop, htop | 任意 | ポップアップが開くモニター。なければ `top` を実行します |
| gum | 任意 | `cpu-revamped` のメニュー、表、色。なくてもすべてのコマンドがプレーンテキストで動きます |

Linux と macOS で、BSD、GNU、uutils、BusyBox のいずれのツールでも動作します。各値は OS に付属するものから取得します。

| 値 | Linux | macOS Intel | macOS Apple Silicon |
|:---|:------|:------------|:--------------------|
| 負荷 | `/proc/stat` を 0.3 秒おいて 2 回読みます | `iostat`、なければ `top` | `iostat`、なければ `top` |
| 温度 | thermal zone、coretemp、k10temp、`sensors` の順です | `osx-cpu-temp`、なければ `istats` | `macmon` |
| クロック | `/proc/cpuinfo`、なければ `scaling_cur_freq` | `sysctl hw.cpufrequency` | チップの世代ごとのクロックの表 |
| ロードアベレージ | `/proc/loadavg` | `sysctl vm.loadavg` | `sysctl vm.loadavg` |
| コア数 | `/proc/cpuinfo` | `sysctl hw.ncpu` | `sysctl hw.ncpu` |
| ガバナー | `scaling_governor` | なし | なし |
| 最も忙しいプロセス | `ps` | `ps` | `ps` |

| プラットフォーム | 温度の取得ツール |
|:-----------------|:-----------------|
| macOS Apple Silicon | `brew install macmon`。sudo なしでセンサーを読みます |
| macOS Intel | `brew install osx-cpu-temp`、または `gem install iStats` |
| Linux | ほとんどの環境では不要です。`sensors` を使う場合は `lm-sensors` を入れます |

取得元がない場合、そのプレースホルダーは空になり、`cpu-revamped doctor` がその名前を表示します。`osx-cpu-temp` と `istats` は Apple Silicon で `0.0` を返しますが、これは値なしとして扱います。

### インストール

[TPM](https://github.com/tmux-plugins/tpm) を使う場合は、`~/.tmux.conf` にプラグインを追加して `prefix + I` を押します。

```tmux
set -g @plugin 'tmux-revamped/tmux-cpu-revamped'
```

手動でインストールする場合は、リポジトリをクローンし、`~/.tmux.conf` からエントリポイントを実行します。

```bash
git clone https://github.com/tmux-revamped/tmux-cpu-revamped ~/.tmux/plugins/tmux-cpu-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-cpu-revamped/cpu-revamped.tmux
```

`status-left` または `status-right` はプラグインを読み込む前に設定してください。プラグインは読み込み時に 1 回だけ、そこにあるプレースホルダーを置き換えます。

クローンで `make install` を実行すると、`cpu-revamped` が `~/.local/bin` に、manページと補完が `~/.local/share` の下に入ります。

### 確認

```bash
~/.tmux/plugins/tmux-cpu-revamped/bin/cpu-revamped doctor
```

## 使い方

このプラグインは、CPU の負荷を、温度、クロック、ロードアベレージ、コア数、最近の負荷のグラフ、最も忙しいプロセス、Linux ではガバナーとともに表示します。ステータスラインは tmux がすでに持っている値を表示し、バックグラウンドの計測がそれを更新します。

| プレースホルダー | 出力 |
|:-----------------|:-----|
| `#{cpu_percentage}` | CPU の負荷で、たとえば`42%`です |
| `#{cpu_icon}` | 負荷の段階を示すアイコンです |
| `#{cpu_fg_color}` | 負荷の段階に応じた前景のスタイルです |
| `#{cpu_bg_color}` | 負荷の段階に応じた背景のスタイルです |
| `#{cpu_temp}` | 整数の度数での温度で、たとえば`54°C`です |
| `#{cpu_temp_icon}` | 温度の段階を示すアイコンです |
| `#{cpu_temp_fg_color}` | 温度の段階に応じた前景のスタイルです |
| `#{cpu_temp_bg_color}` | 温度の段階に応じた背景のスタイルです |
| `#{cpu_freq}` | メガヘルツでのクロックで、たとえば`4000MHz`です |
| `#{cpu_load}` | 1 分間のロードアベレージで、たとえば`1.23`です |
| `#{cpu_load5}` | 5 分間のロードアベレージです |
| `#{cpu_load15}` | 15 分間のロードアベレージです |
| `#{cpu_count}` | 論理 CPU の数です |
| `#{cpu_graph}` | 最近の負荷のスパークラインで、たとえば`▁▂▄▆█`です |
| `#{cpu_top_process}` | CPU を最も使っているプロセスで、たとえば`node 42%`です |
| `#{cpu_governor}` | Linux の周波数ガバナーで、たとえば`performance`です。macOS では空です |
| `#{cpu_load_color}` | 1 分間のロードアベレージをコアあたりで判定した、負荷の段階の前景のスタイルです |
| `#{cpu_alert}` | 負荷または温度が高いしきい値に達している間は`@cpu_revamped_alert_icon`、それ以外は空です |

ステータスラインにプレースホルダーを置きます。

```tmux
set -g @cpu_revamped_low_fg_color '#[fg=green]'
set -g @cpu_revamped_medium_fg_color '#[fg=yellow]'
set -g @cpu_revamped_high_fg_color '#[fg=red]'

set -g status-right '#{cpu_fg_color}#{cpu_icon} #{cpu_percentage}#[default] #{cpu_temp} '
```

オプションをいくつか足した同じ例が [examples/status-right.tmux.conf](examples/status-right.tmux.conf) にあります。

### ラベルと幅

`@cpu_revamped_<metric>_label` は、値が空でないときだけ、1 つの指標の前にアイコンや語を表示します。`@cpu_revamped_icons` を `nerd` にすると、下の各指標に Nerd Font の記号のラベルが付きます。指標ごとのラベルはこのセットより優先され、空にしたラベルは既定値を意味するので記号は残ります。既定の `ascii` はラベルを付けません。

| 指標 | `nerd` のグリフ |
|:-----|:----------------|
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

`@cpu_revamped_fixed_width` を `on` にすると、各値を本来の幅、つまり負荷は 4 文字、温度とロードアベレージは 5 文字、クロックは 7 文字、コア数は 3 文字になるよう左から揃えるので、`9%` が `42%` に変わっても行の残りがずれません。`@cpu_revamped_<metric>_width` は 1 つの指標の幅を決め、固定幅より優先されます。長い値は切り詰めません。

### 描画モード

既定では、各プレースホルダーは `#()` の呼び出しになり、tmux はステータスの再描画のたびにそれを再実行します。`@cpu_revamped_render` を `options` にすると、各プレースホルダーは `#{E:@cpu_revamped_out_percentage}` のようなオプションの読み取りになります。サーバーごとに 1 つのバックグラウンドプロセスが `@cpu_revamped_interval` 秒ごとに計測し、すべての値を 1 回の tmux 呼び出しで書き込むため、値はそろって変わります。

```tmux
set -g @cpu_revamped_render 'options'
set -g @cpu_revamped_fixed_width 'on'
```

### 段階ごとの色

段階のスタイルは既定では空なので、設定するまで `#{cpu_fg_color}`、`#{cpu_bg_color}`、`#{cpu_temp_fg_color}`、`#{cpu_temp_bg_color}`、`#{cpu_load_color}` は何も出力しません。以下の配色は、low を緑、medium を黄、high を赤に対応させています。

| テーマ | 少 | 中 | 多 |
|:-------|:---|:---|:---|
| Catppuccin Mocha | `#a6e3a1` | `#f9e2af` | `#f38ba8` |
| Dracula | `#50fa7b` | `#f1fa8c` | `#ff5555` |
| Nord | `#a3be8c` | `#ebcb8b` | `#bf616a` |
| Gruvbox Dark | `#b8bb26` | `#fabd2f` | `#fb4934` |
| Tokyo Night | `#9ece6a` | `#e0af68` | `#f7768e` |
| Solarized Dark | `#859900` | `#b58900` | `#dc322f` |

各値は `set -g @cpu_revamped_low_fg_color '#[fg=#a6e3a1]'` のようにスタイルとして指定します。温度の段階は `@cpu_revamped_temp_<tier>_fg_color` に同じスタイルを指定します。

| コマンド | 動作 |
|:--------|:-------------|
| `cpu-revamped apply` | ポップアップのキーを割り当て、プレースホルダーを今すぐ置き換えます。プラグインの読み込み時にエントリーポイントが実行します |
| `cpu-revamped list` | `apply` が送るコマンドをすべて表示し、何も変更しません。`--json` で 1 つのオブジェクトを出力します |
| `cpu-revamped status NAME` | プレースホルダーを 1 つ出力します。`percentage`、`temp`、`graph` などで、ステータスラインが実行します |
| `cpu-revamped refresh` | CPU を今すぐ計測し、どれだけ使われているかを表示します |
| `cpu-revamped card` | すべてを今すぐ読み取り、値ごとに 1 行で表示します |
| `cpu-revamped popup` | CPU のモニターを tmux のポップアップで開きます。ポップアップのコマンド、なければ btop、htop、top の順です。ポップアップのキーが実行します |
| `cpu-revamped daemon` | `options` 描画モードのために、ティックごとにプレースホルダーを公開します。`apply` が起動します |
| `cpu-revamped doctor` | 依存関係ごとに 1 行。各値の取得元となるツールやファイル、ポップアップが開くモニター、触れなかったキーも含みます |
| `cpu-revamped version` | バージョンと tmux のバージョン |
| `cpu-revamped help` | ヘルプ。`man cpu-revamped` にも同じコマンドと設定があります |
| `cpu-revamped` | 端末ではメニュー |

## 設定

どのオプションも、ダッシュ区切りのコマンドオプション（例 `--interval 2`）と環境変数（例 `CPU_REVAMPED_INTERVAL`）で指定できます。優先順位はコマンドライン、環境変数、tmux オプションの順です。空の tmux オプションは既定値を意味します。`doctor` は、プラグインが認識できない値を持つ設定の名前を表示します。`apply` に渡したものは、ポップアップのキーとすべてのステータスの呼び出しに引き継がれます。

### 計測

| オプション | 既定値 | 意味 |
|:-----------|:-------|:-----|
| `@cpu_revamped_interval` | `5` | 負荷の計測値が新しいとみなされる秒数です |
| `@cpu_revamped_detail_interval` | `60` | 温度、クロック、ロードアベレージ、コア数、最も忙しいプロセス、ガバナーが新しいとみなされる秒数です |
| `@cpu_revamped_throttle_when_detached` | `0` | `1` でクライアントが接続されていない間は計測しません。ステータスラインは最後の計測値を保ちます |
| `@cpu_revamped_render` | `jobs` | `options` にすると `#()` の呼び出しの代わりに公開済みのオプションを読みます。それ以外の値は `jobs` として扱います |
| `@cpu_revamped_graph_width` | `20` | `#{cpu_graph}` のために残す計測値の数です |

### 段階とアラート

| オプション | 既定値 | 意味 |
|:-----------|:-------|:-----|
| `@cpu_revamped_medium_thresh` | `30` | 段階がmediumになる負荷のパーセントです |
| `@cpu_revamped_high_thresh` | `80` | 段階がhighになる負荷のパーセントで、`#{cpu_alert}`が表示される値でもあります |
| `@cpu_revamped_low_icon` | `▰▱▱` | low段階のアイコンです |
| `@cpu_revamped_medium_icon` | `▰▰▱` | medium段階のアイコンです |
| `@cpu_revamped_high_icon` | `▰▰▰` | high段階のアイコンです |
| `@cpu_revamped_low_fg_color` | 空 | 負荷のlow段階の前景のスタイルで、たとえば`#[fg=green]`です |
| `@cpu_revamped_medium_fg_color` | 空 | 負荷のmedium段階の前景のスタイルです |
| `@cpu_revamped_high_fg_color` | 空 | 負荷のhigh段階の前景のスタイルです |
| `@cpu_revamped_low_bg_color` | 空 | 負荷のlow段階の背景のスタイルです |
| `@cpu_revamped_medium_bg_color` | 空 | 負荷のmedium段階の背景のスタイルです |
| `@cpu_revamped_high_bg_color` | 空 | 負荷のhigh段階の背景のスタイルです |
| `@cpu_revamped_temp_medium_thresh` | `65` | 温度の段階がmediumになる摂氏の度数です |
| `@cpu_revamped_temp_high_thresh` | `80` | 温度の段階がhighになる摂氏の度数で、`#{cpu_alert}`が表示される値でもあります |
| `@cpu_revamped_temp_low_icon` | 空 | 温度のlow段階のアイコンです |
| `@cpu_revamped_temp_medium_icon` | 空 | 温度のmedium段階のアイコンです |
| `@cpu_revamped_temp_high_icon` | 空 | 温度のhigh段階のアイコンです |
| `@cpu_revamped_temp_low_fg_color` | 空 | 温度のlow段階の前景のスタイルです |
| `@cpu_revamped_temp_medium_fg_color` | 空 | 温度のmedium段階の前景のスタイルです |
| `@cpu_revamped_temp_high_fg_color` | 空 | 温度のhigh段階の前景のスタイルです |
| `@cpu_revamped_temp_low_bg_color` | 空 | 温度のlow段階の背景のスタイルです |
| `@cpu_revamped_temp_medium_bg_color` | 空 | 温度のmedium段階の背景のスタイルです |
| `@cpu_revamped_temp_high_bg_color` | 空 | 温度のhigh段階の背景のスタイルです |
| `@cpu_revamped_load_medium_ratio` | `0.7` | `#{cpu_load_color}`がmediumになる、コアあたりのロードアベレージです |
| `@cpu_revamped_load_high_ratio` | `1.0` | `#{cpu_load_color}`がhighになる、コアあたりのロードアベレージです |
| `@cpu_revamped_alert_icon` | `!` | `#{cpu_alert}`が表示するテキストです |

### 書式とラベル

| オプション | 既定値 | 意味 |
|:-----------|:-------|:-----|
| `@cpu_revamped_temp_unit` | `C` | `C`または`F`です |
| `@cpu_revamped_percentage_format` | `%s%%` | 負荷のprintf書式です |
| `@cpu_revamped_temp_format` | `%s°C` | 温度のprintf書式です。単位は`@cpu_revamped_temp_unit`に従います |
| `@cpu_revamped_freq_format` | `%sMHz` | クロックのprintf書式です |
| `@cpu_revamped_load_format` | `%s` | 3つのロードアベレージのprintf書式です |
| `@cpu_revamped_icons` | `ascii` | `nerd`にするとすべての値にNerd Fontの記号のラベルを付けます |
| `@cpu_revamped_<metric>_label` | 空 | 1つの値の前に出すテキストで、値が空でないときだけ出ます |
| `@cpu_revamped_fixed_width` | `off` | `on`で各値を本来の幅に揃え、`9%`が`42%`に変わってもステータス行がずれないようにします |
| `@cpu_revamped_<metric>_width` | 空 | 1つの値をこの文字数に揃えます。長い値は切り詰めません |

ラベルと幅を持てる指標は、`percentage`、`temp`、`freq`、`load`、`load5`、`load15`、`count`、`graph`、`top_process`、`governor`です。

### ポップアップ

| オプション | 既定値 | 意味 |
|:-----------|:-------|:-----|
| `@cpu_revamped_popup_key` | `M-c` | 詳細のポップアップを開くプレフィックスキーです。`off`で何も割り当てません |
| `@cpu_revamped_popup_command` | btop、htop、top の順 | ポップアップが実行するコマンドで、引数も指定できます。インストールされていないものはメッセージで名前を表示します |
| `@cpu_revamped_popup_width` | `80%` | ポップアップの幅です |
| `@cpu_revamped_popup_height` | `80%` | ポップアップの高さです |

### 内部状態

以下のオプションはプラグイン自身が書き込みます。設定しないでください。

| オプション | 保持する内容 |
|:-----------|:-------------|
| `@cpu_revamped_published` | ステータス行が使う指標で、オプションモードがそれだけを書き込むよう読み込み時に記録します |
| `@cpu_revamped_history` | `#{cpu_graph}`のもとになる、最近の負荷の計測値です |
| `@cpu_revamped_out_<metric>` | オプションモードでの各指標の描画済みの値です |
| `@cpu_revamped_ticker_pid` | オプションモードのバックグラウンドのプロセスのIDです |
| `@cpu_revamped_percent` などの値、`_ts`、`_lock` | 保存した計測値、それぞれの読み取り時刻と更新ロック |

## キーバインド

| キー | 動作 | 既定 |
|:-----|:-----|:-----|
| `prefix + M-c` | CPU のモニターをポップアップで開きます。指定したコマンド、なければ btop、htop、top の順です | 割り当て済み |

`@cpu_revamped_popup_key` で別のキーを指定でき、`off` にすると割り当てません。既定のキーがすでに他で使われている場合は触れず、`cpu-revamped doctor` がそれを表示します。

<a id="仕組み"></a>

## 仕組み

tmux がプラグインを読み込むと、[`cpu-revamped.tmux`](cpu-revamped.tmux) が 1 回実行されます。`status-left` と `status-right` が使う指標を `@cpu_revamped_published` に記録し、各プレースホルダーを [`bin/cpu-revamped`](bin/cpu-revamped) の呼び出しに置き換えます。`options` モードでは、オプションの読み取りに置き換えてバックグラウンドプロセスを起動します。

既定のモードでは、各 `#()` の呼び出しは保存済みの計測値をすぐに返します。計測値が間隔より古ければ、ロックを取ってバックグラウンドで更新を始めるため、同時に動く更新は 1 つだけです。Linux の負荷は、0.3 秒おいて 2 回読んだ `/proc/stat` の使用中の割合で、iowait はアイドルとして数えます。macOS では `iostat` のアイドルの割合を 100 から引いた値で、`iostat` がなければ `top` から求めます。1 つの `awk` が読み取り結果をすべての値に変換し、1 回の tmux 呼び出しで保存します。温度、クロック、ロードアベレージ、最も忙しいプロセス、ガバナーは読み取りの負担が大きいため、ステータスラインが使うプレースホルダーの分だけ、`@cpu_revamped_detail_interval` 秒ごとに読み取ります。

温度は、応答した最初の取得元から得ます。Linux では thermal zone、coretemp、k10temp、`sensors` の順、Apple Silicon では `macmon`、Mac ではそのあとに `osx-cpu-temp` と `istats` です。最も忙しいプロセスの名前は `ps` から得られ、どのユーザーでも変えられるため、ステータスラインに渡す前にすべての `#` を二重にします。読み取り、計測、整形は [`lib/cpu.sh`](lib/cpu.sh) に、設定の表は [`lib/state.sh`](lib/state.sh) にあります。

<a id="画面"></a>

## 画面

<details>
<summary>実際の tmux の中で <code>make screens</code> により録画したすべての画面。押したキーをステータスラインに表示しています</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="cpu-revamped: 負荷の段階のアイコンと色、温度、クロック、ロードアベレージ、アラート"><br><sub>負荷の段階のアイコンと色、温度、クロック、ロードアベレージ、アラート, より <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/popup.png" alt="cpu-revamped: prefix M-c で CPU のモニターをポップアップで開きます"><br><sub><code>prefix M-c</code> で CPU のモニターをポップアップで開きます, より <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/icons.png" alt="cpu-revamped: @cpu_revamped_icons を nerd にすると、すべての指標にグリフのラベルが付きます"><br><sub><code>@cpu_revamped_icons</code> を <code>nerd</code> にすると、すべての指標にグリフのラベルが付きます, より <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/graph.png" alt="cpu-revamped: グラフ、負荷、最も忙しいプロセス"><br><sub>グラフ、負荷、最も忙しいプロセス, より <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="cpu-revamped: options 描画モードでは、各プレースホルダーが tmux のオプションを読み取ります"><br><sub><code>options</code> 描画モードでは、各プレースホルダーが tmux のオプションを読み取ります, より <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/card.png" alt="cpu-revamped: card はすべての値を表示します"><br><sub><code>card</code> はすべての値を表示します, より <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/temp.png" alt="cpu-revamped: 温度の段階のアイコンと色、アラート"><br><sub>温度の段階のアイコンと色、アラート, より <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/unit.png" alt="cpu-revamped: @cpu_revamped_temp_unit を F にした状態"><br><sub><code>@cpu_revamped_temp_unit</code> を <code>F</code> にした状態, より <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/load.png" alt="cpu-revamped: 3 つのロードアベレージ、コア数、ロードの色"><br><sub>3 つのロードアベレージ、コア数、ロードの色, より <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/load-format.png" alt="cpu-revamped: @cpu_revamped_load_format でロードアベレージの書式を決めます"><br><sub><code>@cpu_revamped_load_format</code> でロードアベレージの書式を決めます, より <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/ratios.png" alt="cpu-revamped: @cpu_revamped_load_medium_ratio と @cpu_revamped_load_high_ratio でロードの色の境界を動かします"><br><sub><code>@cpu_revamped_load_medium_ratio</code> と <code>@cpu_revamped_load_high_ratio</code> でロードの色の境界を動かします, より <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/clock.png" alt="cpu-revamped: クロック、ガバナー、最も忙しいプロセス"><br><sub>クロック、ガバナー、最も忙しいプロセス, より <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/freq-format.png" alt="cpu-revamped: @cpu_revamped_freq_format でクロックの書式を決めます"><br><sub><code>@cpu_revamped_freq_format</code> でクロックの書式を決めます, より <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/format.png" alt="cpu-revamped: @cpu_revamped_percentage_format で負荷のパーセントの書式を決めます"><br><sub><code>@cpu_revamped_percentage_format</code> で負荷のパーセントの書式を決めます, より <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/fixed.png" alt="cpu-revamped: @cpu_revamped_fixed_width は各値を本来の幅に揃えます"><br><sub><code>@cpu_revamped_fixed_width</code> は各値を本来の幅に揃えます, より <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/width.png" alt="cpu-revamped: @cpu_revamped_count_width は 1 つの指標を指定の幅に揃えます"><br><sub><code>@cpu_revamped_count_width</code> は 1 つの指標を指定の幅に揃えます, より <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/labels.png" alt="cpu-revamped: 1 つの指標の前に出す独自のラベル"><br><sub>1 つの指標の前に出す独自のラベル, より <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/tiers.png" alt="cpu-revamped: @cpu_revamped_medium_thresh と @cpu_revamped_high_thresh で段階の境界を動かします"><br><sub><code>@cpu_revamped_medium_thresh</code> と <code>@cpu_revamped_high_thresh</code> で段階の境界を動かします, より <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/graph-width.png" alt="cpu-revamped: @cpu_revamped_graph_width はグラフが残す計測値の数を決めます"><br><sub><code>@cpu_revamped_graph_width</code> はグラフが残す計測値の数を決めます, より <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/popup-key.png" alt="cpu-revamped: @cpu_revamped_popup_key でポップアップに別のキーを指定します"><br><sub><code>@cpu_revamped_popup_key</code> でポップアップに別のキーを指定します, より <code>features.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/popup-command.png" alt="cpu-revamped: @cpu_revamped_popup_command でポップアップが実行するコマンドを、サイズとともに指定します"><br><sub><code>@cpu_revamped_popup_command</code> でポップアップが実行するコマンドを、サイズとともに指定します, より <code>features.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/status-command.png" alt="cpu-revamped: status percentage と status graph はプレースホルダーを 1 つずつ出力します"><br><sub><code>status percentage</code> と <code>status graph</code> はプレースホルダーを 1 つずつ出力します, より <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/refresh.png" alt="cpu-revamped: refresh は CPU を今すぐ計測します"><br><sub><code>refresh</code> は CPU を今すぐ計測します, より <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="cpu-revamped: list はすべてのバインディングを表示します"><br><sub><code>list</code> はすべてのバインディングを表示します, より <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/json.png" alt="cpu-revamped: list --json は同じ内容を 1 つのオブジェクトで出力します"><br><sub><code>list --json</code> は同じ内容を 1 つのオブジェクトで出力します, より <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="cpu-revamped: doctor"><br><sub><code>doctor</code>, より <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu.png" alt="cpu-revamped: メニュー"><br><sub>メニュー, より <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/menu-card.png" alt="cpu-revamped: メニューから開いたカード"><br><sub>メニューから開いたカード, より <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/accent.png" alt="cpu-revamped: CPU_REVAMPED_ACCENT によるアクセント"><br><sub><code>CPU_REVAMPED_ACCENT</code> によるアクセント, より <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="cpu-revamped: gum なしのメニュー"><br><sub>gum なしのメニュー, より <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="cpu-revamped: メニューから開いた doctor（gum なし）"><br><sub>メニューから開いた <code>doctor</code>（gum なし）, より <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-card.png" alt="cpu-revamped: gum なしの card"><br><sub>gum なしの <code>card</code>, より <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/version.png" alt="cpu-revamped: バージョン"><br><sub>バージョン, より <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/error.png" alt="cpu-revamped: 未知のコマンド"><br><sub>未知のコマンド, より <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="cpu-revamped: 6 つのテーマでのヘッダー"><br><sub>6 つのテーマでのヘッダー, より <code>themes.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="cpu-revamped: ヘルプ"><br><sub>ヘルプ, より <code>help.tape</code></sub></td>
</tr>
</table>

録画では実際のプラグインと tmux を動かしています。`iostat`、`sysctl`、`macmon`、`osx-cpu-temp`、`ps`、`top` は小さなスクリプトで代用しているため、画面上の数値はそれらのものです。録画は macOS で行うため、ガバナーがなく、`#{cpu_governor}` は何も表示しません。

</details>

## 移植性

プラグインは POSIX `sh` です。CI は下の各行ですべてのテストを実行します。

| シェル | 状態 |
|:------|:-------|
| `dash`、macOS の `/bin/sh` | 対応 |
| `bash` 3.2 と 5.x、システムの `zsh` と Homebrew の `zsh` | 対応 |

| システム | 状態 |
|:-------|:-------|
| macOS | Apple Silicon と Intel の Tahoe。付属のツール、Homebrew の GNU ツール、Homebrew の uutils で確認 |
| Linux | x86_64 と arm64 の Ubuntu 26.04。GNU coreutils、uutils、BusyBox で確認 |

## 開発

| コマンド | 実行内容 |
|:--------|:-------------|
| `make fmt` | すべてのスクリプトに shfmt `-i 2` をかけます |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint、actionlint を、指摘ゼロで通します |
| `make test` | システムの `sh` で bats のテスト |
| `make test-all` | インストール済みのすべてのシェルでテスト。macOS では bash と zsh の両方のビルドを含みます |
| `make test-linux` | Ubuntu のコンテナでテスト |
| `make coverage` | この Mac と Ubuntu のコンテナで bashcov を実行し、合算して 100 パーセントで判定します |
| `make screens` | 上の画面を、本物のプラグインから tmux の中で VHS で録画します。macOS で実行します |
| `make install` | コマンド、manページ、補完を `PREFIX` の下に置きます |

macOS では、`brew bundle` を実行すると、これらのターゲットが使うツールがすべて [`Brewfile`](Brewfile) からインストールされます。

コミットは Conventional Commits の形式に従い、そのまま `main` に入ります。`main` で `ci` が成功すると、`release.yml` が semantic-release を実行します。前回のタグ以降に `feat` か `fix` があればリリースを公開し、バージョン定数を更新し、変更内容を [`CHANGELOG.md`](CHANGELOG.md) に追加します。

## ライセンス

[MIT](LICENSE)、copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped ファミリー

このプラグインは tmux-revamped ファミリーの一員です。すべてのメンバーが [`FAMILY.md`](FAMILY.md) の同じ規約と同じ共有ライブラリを持ちます。メンバーは一緒にインストールする前提で作られており、ほかのメンバーが使うキーや tmux オプションを使うメンバーはありません。

あるメンバーで見つかった不具合は、修正完了とする前に全メンバーで同じ不具合を探します。

| メンバー | 機能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | tmuxの設定を編集して保存するだけで、キーもコマンドも使わずに自動で再読み込みされます |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | tmuxのステータスバーに電池の状態を表示し、ステータスの描画を一切止めません |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 接続中のすべてのBluetooth機器とその電池残量をtmuxのステータスバーに表示し、描画を止めません |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | **このプラグイン**、CPUの負荷、温度、周波数をtmuxのステータスバーに表示し、描画を一切止めません |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | tmuxのステータスバーにディスク使用量を表示し、ステータスの描画を一切止めません |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 画面上の URL、パス、ハッシュなどのトークンを fzf で選び、カーソル位置に入力します。純粋なシェルだけで動きます |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | ポップアップ内の fzf ピッカーから、tmux のセッション、ウィンドウ、ペインの切り替え、終了、名前変更、作成を行います |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | アクティブなペインのgitブランチ、変更、プロバイダーの件数を、描画を止めずにtmuxのステータスバーに表示します |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | NVIDIA、AMD、Intel、Apple の GPU の負荷、温度、クロック、電力、メモリを tmux のステータスバーに表示します |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 現在の Kubernetes コンテキストと名前空間を、kubectl を使わずに kubeconfig から解析して tmux のステータスバーに表示します |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 任意の TUI アプリを、現在のペインのディレクトリでポップアップまたはウィンドウとして起動します。アプリごとにキーを設定できます |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 任意のペインをファイルに保存します。ライブのログ記録、スクロールバック全体、1 回限りのスクリーンショットに対応します |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 再生中の曲をステータスバーに表示し、ステータスの描画を止めません |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | ネットワークのスループットをステータスバーに表示し、描画を止めません |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux のペインとウィンドウの操作キー。tmux のバージョンに対応し、vim と共存でき、どの prefix キーも無効にできます |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | tmuxのすべてのセッション、ウィンドウ、ペインを保存し、タイマーで自動保存して、再起動後にすべて復元します |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revampedプラグインの出発点です。共有ライブラリ、batsハーネス、CIを含みます |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | すべての状態をtmuxオプションに保持し、一時ファイルを使わない、tmuxステータスバーのポモドーロタイマーです |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM、スワップ、メモリプレッシャーをtmuxのステータスバーに表示します。計測はバックグラウンドで行うため描画を待たせません |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | tmuxのステータスバー上でウィンドウのタブをマウスでドラッグして、そのウィンドウを移動します |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 自分でスクロールできるアプリにはマウスホイールを渡し、それ以外ではtmuxのコピーモードに入ります |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmuxのタイル型ウィンドウ管理です。BSPのdwindleとspiralを含む8つのレイアウトと、レイアウトの取り消しがあります |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | ステータスバーにローカル時計と世界時計を時間帯ごとの色で表示し、カウントダウンと夏時間の警告も出します |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | wttr.inの天気をバックグラウンドで取得し、ステータスバーを待たせずに表示します |

<!-- family:end -->
