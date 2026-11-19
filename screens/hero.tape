Source common.tape
Output hero.gif
Hide
Type "printf 3 >/Users/Shared/demo/phase; tmux -L revamped-screens attach -t demo"
Enter
Sleep 1.5s
Show
Sleep 7s
Screenshot status.png
Sleep 1s
Hide
Ctrl+B
Type ":"
Sleep 300ms
Type "run-shell 'rm -f /Users/Shared/demo/phase'"
Enter
Show
Sleep 5s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "prefix M-c, C-c"
Enter
Show
Ctrl+B
Escape
Type@1ms "c"
Sleep 5s
Screenshot popup.png
Sleep 1s
Ctrl+C
Sleep 1500ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_icons nerd"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_icons nerd"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3500ms
Screenshot icons.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_icons ascii"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_icons ascii"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 1500ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{cpu_graph} #{cpu_percentage} #{cpu_top_process} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{cpu_graph} #{cpu_percentage} #{cpu_top_process} '"
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
Screenshot graph.png
Sleep 1s
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g @cpu_revamped_render options"
Enter
Show
Sleep 800ms
Type "tmux set -g @cpu_revamped_render options"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 800ms
Hide
Ctrl+]
Sleep 300ms
Type@5ms "tmux set -g status-right #{cpu_graph} #{cpu_percentage} #{cpu_top_process} "
Enter
Show
Sleep 800ms
Type "tmux set -g status-right '#{cpu_graph} #{cpu_percentage} #{cpu_top_process} '"
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
Type@5ms "tmux show -gv status-right | cut -c1-90"
Enter
Show
Sleep 800ms
Type "tmux show -gv status-right | cut -c1-90"
Hide
Ctrl+]
Sleep 300ms
Type@5ms "Enter"
Enter
Show
Enter
Sleep 3s
Screenshot options.png
Sleep 1s
Sleep 1500ms
