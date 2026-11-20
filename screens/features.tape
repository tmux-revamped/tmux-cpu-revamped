Source common.tape
Output scratch.gif
Hide
Type "tmux -L revamped-screens attach -t demo"
Enter
Sleep 1.5s
Show
Sleep 3500ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "cpu-revamped card"
Enter
Show
Sleep 800ms
Type "cpu-revamped card"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 4s
Screenshot card.png
Sleep 1s
Hide
Type "clear"
Enter
Sleep 600ms
Show
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_temp_medium_thresh 50"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_temp_medium_thresh 50"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_temp_high_thresh 75"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_temp_high_thresh 75"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{cpu_temp_fg_color}#{cpu_temp_bg_color}#{cpu_temp_icon}#{cpu_temp}#[default] #{cpu_alert} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{cpu_temp_fg_color}#{cpu_temp_bg_color}#{cpu_temp_icon}#{cpu_temp}#[default] #{cpu_alert} '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "cpu-revamped apply"
Enter
Show
Sleep 800ms
Type "cpu-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Ctrl+B
Type ":"
Sleep 300ms
Type "run-shell 'printf 3 >/Users/Shared/demo/phase'"
Enter
Show
Enter
Sleep 12s
Screenshot temp.png
Sleep 1s
Hide
Ctrl+B
Type ":"
Sleep 300ms
Type "run-shell 'rm -f /Users/Shared/demo/phase'"
Enter
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_temp_unit F"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_temp_unit F"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot unit.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_temp_format %s deg"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_temp_format '%s deg'"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Hide
Type "clear"
Enter
Sleep 600ms
Show
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{cpu_load} #{cpu_load5} #{cpu_load15} #{cpu_count} #{cpu_load_color}#{cpu_icon}#[default] "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{cpu_load} #{cpu_load5} #{cpu_load15} #{cpu_count} #{cpu_load_color}#{cpu_icon}#[default] '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "cpu-revamped apply"
Enter
Show
Sleep 800ms
Type "cpu-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3s
Screenshot load.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_load_format load %s"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_load_format 'load %s'"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot load-format.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_load_medium_ratio 0.1"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_load_medium_ratio 0.1"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_load_high_ratio 0.2"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_load_high_ratio 0.2"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot ratios.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{cpu_freq} #{cpu_governor} #{cpu_top_process} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{cpu_freq} #{cpu_governor} #{cpu_top_process} '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "cpu-revamped apply"
Enter
Show
Sleep 800ms
Type "cpu-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 4s
Screenshot clock.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_freq_format %s MHz"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_freq_format '%s MHz'"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot freq-format.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{cpu_percentage} #{cpu_count} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{cpu_percentage} #{cpu_count} '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "cpu-revamped apply"
Enter
Show
Sleep 800ms
Type "cpu-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_percentage_format cpu %s%%"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_percentage_format 'cpu %s%%'"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot format.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_fixed_width on"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_fixed_width on"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot fixed.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_count_width 6"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_count_width 6"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot width.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_count_label cores"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_count_label cores"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot labels.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_medium_thresh 20"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_medium_thresh 20"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_high_thresh 50"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_high_thresh 50"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{cpu_fg_color}#{cpu_icon} #{cpu_percentage}#[default] "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{cpu_fg_color}#{cpu_icon} #{cpu_percentage}#[default] '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "cpu-revamped apply"
Enter
Show
Sleep 800ms
Type "cpu-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 6s
Screenshot tiers.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_graph_width 6"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_graph_width 6"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{cpu_graph} #{cpu_percentage} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{cpu_graph} #{cpu_percentage} '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "cpu-revamped apply"
Enter
Show
Sleep 800ms
Type "cpu-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 8s
Screenshot graph-width.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_popup_key M"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_popup_key M"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "cpu-revamped apply"
Enter
Show
Sleep 800ms
Type "cpu-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 2s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "prefix M, C-c"
Enter
Show
Ctrl+B
Type@1ms "M"
Sleep 4s
Screenshot popup-key.png
Sleep 1s
Ctrl+C
Sleep 1500ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_popup_command top -u"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_popup_command 'top -u'"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_popup_width 60%"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_popup_width 60%"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_popup_height 50%"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_popup_height 50%"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "prefix M, C-c"
Enter
Show
Ctrl+B
Type@1ms "M"
Sleep 4s
Screenshot popup-command.png
Sleep 1s
Ctrl+C
Sleep 1500ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{cpu_cores} #{cpu_percentage} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{cpu_cores} #{cpu_percentage} '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "cpu-revamped apply"
Enter
Show
Sleep 800ms
Type "cpu-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 6s
Screenshot cores.png
Sleep 1s
Hide
Ctrl+B
Type ":"
Sleep 300ms
Type "run-shell 'printf 0 >/Users/Shared/demo/phase'"
Enter
Sleep 500ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_low_bg_color ##[bg=#ff00aa]"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_low_bg_color '#[bg=#ff00aa]'"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_sep_bg #202020"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_sep_bg '#202020'"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{cpu_sep_left}#{cpu_bg_color}#{cpu_percentage} #{cpu_cores}##[default]#{cpu_sep_right} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{cpu_sep_left}#{cpu_bg_color}#{cpu_percentage} #{cpu_cores}#[default]#{cpu_sep_right} '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "cpu-revamped apply"
Enter
Show
Sleep 800ms
Type "cpu-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot separators.png
Sleep 1s
Hide
Ctrl+B
Type ":"
Sleep 300ms
Type "run-shell 'rm -f /Users/Shared/demo/phase'"
Enter
Sleep 500ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{cpu_throttle} #{cpu_percentage} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{cpu_throttle} #{cpu_percentage} '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "cpu-revamped apply"
Enter
Show
Sleep 800ms
Type "cpu-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+B
Type ":"
Sleep 300ms
Type "run-shell 'printf 1 >/Users/Shared/demo/throttle'"
Enter
Sleep 500ms
Show
Sleep 7s
Screenshot throttle.png
Sleep 1s
Hide
Hide
Ctrl+B
Type ":"
Sleep 300ms
Type "run-shell 'rm -f /Users/Shared/demo/throttle'"
Enter
Sleep 500ms
Hide
Ctrl+B
Type ":"
Sleep 300ms
Type "run-shell 'printf 3 >/Users/Shared/demo/phase'"
Enter
Sleep 500ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{cpu_icon}#{cpu_percentage} #{cpu_temp_icon}#{cpu_temp} #{cpu_alert}| "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{cpu_icon}#{cpu_percentage} #{cpu_temp_icon}#{cpu_temp} #{cpu_alert}| '"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "cpu-revamped apply"
Enter
Show
Sleep 800ms
Type "cpu-revamped apply"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_high_icon off"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_high_icon off"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_temp_high_icon off"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_temp_high_icon off"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1200ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_alert_icon off"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_alert_icon off"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot off.png
Sleep 1s
Hide
Ctrl+B
Type ":"
Sleep 300ms
Type "run-shell 'rm -f /Users/Shared/demo/phase'"
Enter
Sleep 500ms
