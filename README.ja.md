<div align="center">

# tmux-cpu-revamped

<strong>CPUの負荷、温度、周波数をtmuxのステータスバーに表示し、描画を一切止めません。</strong>

[English](README.md) &nbsp;|&nbsp; 日本語 &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-cpu-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-cpu-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.3.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">機能</a> &nbsp;|&nbsp;
  <a href="#requirements">動作要件</a> &nbsp;|&nbsp;
  <a href="#installation">インストール</a> &nbsp;|&nbsp;
  <a href="#usage">使い方</a> &nbsp;|&nbsp;
  <a href="#configuration">設定</a> &nbsp;|&nbsp;
  <a href="#key-bindings">キーバインド</a> &nbsp;|&nbsp;
  <a href="#how-it-works">仕組み</a>
</p>

</div>

プレースホルダー**18**個。描画モード**2**種類。LinuxとmacOSで温度の情報源**7**種類。CIはLinuxとmacOSの**10**通りのツールチェーンの組み合わせでテストを実行します。

---

<a id="what-it-does"></a>

## 機能

`status-left`と`status-right`の`#{cpu_*}`プレースホルダーを、CPUの負荷、温度、クロック、ロードアベレージ、コア数、負荷の履歴、最も負荷の高いプロセス、Linuxのガバナーに置き換えます。どのプレースホルダーもtmuxのオプションにキャッシュされた値を読みます。計測はバックグラウンドで行うため、ステータスラインが待たされることはありません。ディスクには何も書き込みません。

`prefix + M-c`で`btop`を動かす詳細ポップアップも開きます。

<a id="requirements"></a>

## 動作要件

| ツール | バージョン | 用途 |
|:-----|:--------|:-----------|
| tmux | 3.2以降 | 詳細ポップアップの`display-popup` |
| bash | 3.2以降 | macOSの`/bin/bash`を含むすべてのスクリプト |
| `btop` | 任意 | 任意。ポップアップの既定のコマンド |
| 温度の補助ツール | 任意 | 任意。下の表を参照 |

| 値 | Linux、x86_64とarm64 | macOS Intel | macOS Apple Silicon |
|:------|:------------------------|:------------|:--------------------|
| 負荷 | `/proc/stat`を0.3秒の間隔で2回読む | `iostat`、次に`top` | `iostat`、次に`top` |
| 温度 | サーマルゾーン、次にcoretemp、次にk10temp、次に`sensors` | `osx-cpu-temp`、次に`istats` | `macmon` |
| クロック | `/proc/cpuinfo`、次に`scaling_cur_freq` | `sysctl hw.cpufrequency` | チップごとの最大クロックの表 |
| ロードアベレージとコア数 | `/proc/loadavg`、`/proc/cpuinfo` | `sysctl` | `sysctl` |
| ガバナー | `scaling_governor` | なし | なし |

| プラットフォーム | 温度の補助ツール |
|:---------|:-------------------|
| macOS Apple Silicon | `brew install macmon`。sudoなしでセンサーを読みます |
| macOS Intel | `brew install osx-cpu-temp`、または`gem install iStats` |
| Linux | ほとんどのマシンで不要。`sensors`を代替手段にするなら`lm-sensors` |

ホストに情報源がない値は空で表示されます。`osx-cpu-temp`と`istats`はApple Siliconで`0.0`を返し、プラグインはそれを読み取りなしとして扱います。このホストで使えるものは`src/cpu.sh doctor`で確認できます。

<a id="installation"></a>

## インストール

### TPMでインストール

`~/.tmux.conf`にプラグインとプレースホルダーを追加し、`prefix + I`を押します。

```tmux
set -g @plugin 'tmux-revamped/tmux-cpu-revamped'
set -g status-right '#{cpu_icon} #{cpu_percentage} #{cpu_temp}'
```

### 手動インストール

```bash
git clone https://github.com/tmux-revamped/tmux-cpu-revamped ~/.tmux/plugins/tmux-cpu-revamped
```

次の行を`~/.tmux.conf`の`status-left`と`status-right`を設定する行より後に追加し、tmuxを再読み込みします。

```tmux
run-shell ~/.tmux/plugins/tmux-cpu-revamped/cpu-revamped.tmux
```

<a id="usage"></a>

## 使い方

`status-left`か`status-right`にプレースホルダーを書きます。プラグインは読み込み時にそれを置き換えます。完全な例は[`examples/status-right.tmux.conf`](examples/status-right.tmux.conf)にあります。

```tmux
set -g status-right '#{cpu_graph} #{cpu_load_color}#{cpu_icon} #{cpu_percentage}#[default] #{cpu_temp} #{cpu_alert}'
```

| プレースホルダー | 出力 |
|:------------|:-------|
| `#{cpu_percentage}` | CPUの負荷。例：`42%` |
| `#{cpu_icon}` | 現在の負荷段階のアイコン |
| `#{cpu_fg_color}`、`#{cpu_bg_color}` | 現在の負荷段階の色 |
| `#{cpu_temp}` | 整数の温度。例：`54°C` |
| `#{cpu_temp_icon}` | 現在の温度段階のアイコン |
| `#{cpu_temp_fg_color}`、`#{cpu_temp_bg_color}` | 現在の温度段階の色 |
| `#{cpu_freq}` | クロック。例：`4000MHz` |
| `#{cpu_load}`、`#{cpu_load5}`、`#{cpu_load15}` | 1分、5分、15分のロードアベレージ。例：`1.23` |
| `#{cpu_count}` | 論理CPUの数 |
| `#{cpu_graph}` | 最近の負荷の推移。例：`▁▂▄▆█` |
| `#{cpu_top_process}` | 最も負荷の高いプロセス。例：`node 42%` |
| `#{cpu_governor}` | Linuxの周波数ガバナー。例：`performance` |
| `#{cpu_load_color}` | コアあたりの1分ロードアベレージで決まる負荷段階の文字色 |
| `#{cpu_alert}` | 負荷か温度が高の閾値に達したときに`@cpu_revamped_alert_icon`、それ以外は空 |

<a id="configuration"></a>

## 設定

| オプション | 既定値 | 意味 |
|:-------|:--------|:--------|
| `@cpu_revamped_interval` | `5` | 負荷の読み取りを新しいとみなす秒数 |
| `@cpu_revamped_detail_interval` | `60` | 温度、クロック、ロードアベレージ、コア数、最も負荷の高いプロセス、ガバナーを新しいとみなす秒数 |
| `@cpu_revamped_render` | 空 | `options`でオプション描画モードにする。[仕組み](#how-it-works)を参照 |
| `@cpu_revamped_throttle_when_detached` | `0` | `1`でクライアントが接続していない間は計測を止める |
| `@cpu_revamped_percentage_format` | `%s%%` | 負荷のprintf書式 |
| `@cpu_revamped_medium_thresh`、`@cpu_revamped_high_thresh` | `30`、`80` | 中と高の段階が始まる負荷のパーセント |
| `@cpu_revamped_low_icon` | `▰▱▱` | 負荷が低の段階のアイコン |
| `@cpu_revamped_medium_icon` | `▰▰▱` | 負荷が中の段階のアイコン |
| `@cpu_revamped_high_icon` | `▰▰▰` | 負荷が高の段階のアイコン |
| `@cpu_revamped_{low,medium,high}_{fg,bg}_color` | 空 | 負荷段階ごとの色 |
| `@cpu_revamped_temp_unit` | `C` | `C`または`F` |
| `@cpu_revamped_temp_format` | `%s°C` | 温度のprintf書式。単位は`@cpu_revamped_temp_unit`に従う |
| `@cpu_revamped_temp_medium_thresh`、`@cpu_revamped_temp_high_thresh` | `65`、`80` | 温度の中と高の段階が始まる摂氏の温度 |
| `@cpu_revamped_temp_low_icon` | 空 | 温度が低の段階のアイコン |
| `@cpu_revamped_temp_medium_icon` | 空 | 温度が中の段階のアイコン |
| `@cpu_revamped_temp_high_icon` | 空 | 温度が高の段階のアイコン |
| `@cpu_revamped_temp_{low,medium,high}_{fg,bg}_color` | 空 | 温度段階ごとの色 |
| `@cpu_revamped_freq_format` | `%sMHz` | クロックの書式 |
| `@cpu_revamped_load_format` | `%s` | ロードアベレージの書式 |
| `@cpu_revamped_graph_width` | `20` | `#{cpu_graph}`に残す読み取りの数 |
| `@cpu_revamped_load_medium_ratio`、`@cpu_revamped_load_high_ratio` | `0.7`、`1.0` | `#{cpu_load_color}`が中と高になるコアあたりの負荷 |
| `@cpu_revamped_alert_icon` | `!` | `#{cpu_alert}`の記号 |
| `@cpu_revamped_icons` | `ascii` | `nerd`ですべての指標にNerd Fontの記号のラベルを付ける |
| `@cpu_revamped_<metric>_label` | 空 | 値が空でないときに1つの指標の値の前に出す文字列。`''`で`nerd`のラベルを消す |
| `@cpu_revamped_fixed_width` | `off` | `on`で各値を最大幅まで左側に詰め物をする |
| `@cpu_revamped_<metric>_width` | 空 | 1つの指標の幅。固定幅より優先 |
| `@cpu_revamped_popup_key` | `M-c` | 詳細ポップアップのprefixキー。`off`で割り当てない |
| `@cpu_revamped_popup_command` | `btop` | ポップアップで実行するコマンド |
| `@cpu_revamped_popup_width`、`@cpu_revamped_popup_height` | `80%`、`80%` | ポップアップの大きさ |

ラベルは`percentage`、`temp`、`freq`、`load`、`load5`、`load15`、`count`、`graph`、`top_process`、`governor`に付きます。幅の設定で長い値が切り詰められることはありません。

### テーマの色

色のオプションは既定で空のため、設定するまで色は付きません。次の各ブロックは低、中、高の段階をそれぞれ緑、黄、赤にします。

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

### 内部状態

次のオプションはプラグインが自身で書き込みます。設定しないでください。

| オプション | 内容 |
|:-------|:------|
| `@cpu_revamped_published` | 読み込み時に`status-left`と`status-right`で見つかった指標。オプションモードで公開するもの |
| `@cpu_revamped_out_<metric>` | オプションモードで公開される各指標の値 |
| `@cpu_revamped_ticker_pid` | オプションモードのバックグラウンドプロセスのpid |
| `@cpu_revamped_option_names` | バックグラウンドプロセスが1周期に1回の呼び出しで読むオプション |
| `@cpu_revamped_history` | `#{cpu_graph}`用の最近の負荷 |
| `@cpu_revamped_{percent,temp,freq,load,load5,load15,count,top_process,governor}` | キャッシュされた読み取り。それぞれに`_ts`のタイムスタンプ、`percent`には`_lock`もある |

<a id="key-bindings"></a>

## キーバインド

| キー | 操作 | オプション |
|:----|:-------|:-------|
| `prefix + M-c` | `@cpu_revamped_popup_command`を実行するポップアップを開く | `@cpu_revamped_popup_key` |

tmux 3.2より古い場合、このキーはポップアップの代わりにメッセージを表示します。

<a id="how-it-works"></a>

## 仕組み

既定のジョブモードでは、各プレースホルダーが[`src/cpu.sh`](src/cpu.sh)を呼ぶ`#()`になります。呼び出しはキャッシュされた値をすぐに出力します。キャッシュされた負荷が`@cpu_revamped_interval`より古ければ、バックグラウンドでの更新を1つ開始します。更新はロックで守られ、並行した呼び出しが2つ目を開始することはありません。

tmuxはステータスを描き直すたびにすべての`#()`を実行します。1つのバーに複数のプラグインがあると、およそ1秒に1回になります。オプションモードはこの呼び出しをなくします。

```tmux
set -g @cpu_revamped_render 'options'
set -g @cpu_revamped_fixed_width 'on'
```

各プレースホルダーは`#{E:@cpu_revamped_out_percentage}`のようなオプションの読み取りになります。サーバーごとに1つのバックグラウンドプロセスが`@cpu_revamped_interval`秒ごとにCPUを計測し、ステータスラインが使うすべての値を1回のtmux呼び出しで書き込み、1回だけ再描画します。このプロセスはサーバーが止まるか、設定の再読み込みで後継が起動すると終了します。ジョブモードに戻すと解放されます。

最も負荷の高いプロセスの名前は、キャッシュする前にすべての`#`を二重にします。そのためtmuxの書式に似た名前のプロセスも文字として表示されます。

<a id="development"></a>

## 開発

| コマンド | 実行内容 |
|:--------|:-------------|
| `make test` | [`test/`](test)以下のbatsテスト |
| `make lint` | すべてのシェルファイルへのshellcheck |
| `make coverage` | Linuxでのkcovによる行カバレッジ。95%未満で失敗します |

<a id="license"></a>

## ライセンス

[MIT](LICENSE)、copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped ファミリー

このプラグインは tmux-revamped ファミリーの一員です。すべてのメンバーが [`FAMILY.md`](FAMILY.md) の同じ規約、`family/` 配下の同じツール、同じ共有ライブラリを持ち、チェックサムの一覧によってバイト単位で同一に保たれています。メンバーは一緒にインストールする前提で作られており、ほかのメンバーが使うキーや tmux オプションを使うメンバーはありません。

あるメンバーで見つかった不具合は、修正完了とする前に全メンバーで同じ不具合を探します。この義務は記憶に頼らず規約に書かれており、`family/bin/sweep` がその作業を行います。

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
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revampedプラグインの出発点です。共有ライブラリ、batsハーネス、CI、ファミリーのツールを含みます |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | すべての状態をtmuxオプションに保持し、一時ファイルを使わない、tmuxステータスバーのポモドーロタイマーです |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM、スワップ、メモリプレッシャーをtmuxのステータスバーに表示します。計測はバックグラウンドで行うため描画を待たせません |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | tmuxのステータスバー上でウィンドウのタブをマウスでドラッグして、そのウィンドウを移動します |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 自分でスクロールできるアプリにはマウスホイールを渡し、それ以外ではtmuxのコピーモードに入ります |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmuxのタイル型ウィンドウ管理です。BSPのdwindleとspiralを含む8つのレイアウトと、レイアウトの取り消しがあります |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | ステータスバーにローカル時計と世界時計を時間帯ごとの色で表示し、カウントダウンと夏時間の警告も出します |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | wttr.inの天気をバックグラウンドで取得し、ステータスバーを待たせずに表示します |

### インストールの確認

全メンバーがディスク上にあれば、1 つのコマンドでメンバー間の衝突を報告できます。

```sh
family/bin/doctor --live
```

各メンバーと実行中の tmux サーバーを読み取り、重複したキー、重複したステータスのプレースホルダー、命名規則に合わないオプション、規約のバージョンが古いメンバーを報告します。

<!-- family:end -->
