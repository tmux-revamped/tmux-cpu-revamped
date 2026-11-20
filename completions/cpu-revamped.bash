# shellcheck shell=bash
# shellcheck disable=SC2207

_cpu_revamped() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  case "${prev}" in
  --theme)
    COMPREPLY=($(compgen -W "kodougu catppuccin-mocha catppuccin-latte dracula nord gruvbox tokyo-night mono" -- "${cur}"))
    return
    ;;
  status)
    COMPREPLY=($(compgen -W "percentage icon fg_color bg_color temp temp_icon temp_fg_color temp_bg_color freq load load5 load15 count graph top_process governor load_color alert cores sep_left sep_right throttle" -- "${cur}"))
    return
    ;;
  --throttle-when-detached | --notify)
    COMPREPLY=($(compgen -W "0 1" -- "${cur}"))
    return
    ;;
  --render)
    COMPREPLY=($(compgen -W "jobs options" -- "${cur}"))
    return
    ;;
  --temp-unit)
    COMPREPLY=($(compgen -W "C F" -- "${cur}"))
    return
    ;;
  --icons)
    COMPREPLY=($(compgen -W "ascii nerd" -- "${cur}"))
    return
    ;;
  --fixed-width)
    COMPREPLY=($(compgen -W "on off" -- "${cur}"))
    return
    ;;
  --popup-key | --popup-width | --popup-height | --popup-command | --interval | --detail-interval | --medium-thresh | --high-thresh | --temp-medium-thresh | --temp-high-thresh | --load-medium-ratio | --load-high-ratio | --low-icon | --medium-icon | --high-icon | --low-fg-color | --medium-fg-color | --high-fg-color | --low-bg-color | --medium-bg-color | --high-bg-color | --temp-low-icon | --temp-medium-icon | --temp-high-icon | --temp-low-fg-color | --temp-medium-fg-color | --temp-high-fg-color | --temp-low-bg-color | --temp-medium-bg-color | --temp-high-bg-color | --alert-icon | --throttle-icon | --sep-left | --sep-right | --sep-bg | --percentage-format | --temp-format | --freq-format | --load-format | --percentage-label | --temp-label | --freq-label | --load-label | --load5-label | --load15-label | --count-label | --graph-label | --top-process-label | --governor-label | --cores-label | --percentage-width | --temp-width | --freq-width | --load-width | --load5-width | --load15-width | --count-width | --graph-width | --top-process-width | --governor-width | --cores-width)
    return
    ;;
  *) ;;
  esac

  COMPREPLY=($(compgen -W "apply list status refresh card popup daemon doctor version help --json --theme --popup-key --popup-width --popup-height --popup-command --interval --detail-interval --throttle-when-detached --render --medium-thresh --high-thresh --temp-medium-thresh --temp-high-thresh --load-medium-ratio --load-high-ratio --low-icon --medium-icon --high-icon --low-fg-color --medium-fg-color --high-fg-color --low-bg-color --medium-bg-color --high-bg-color --temp-low-icon --temp-medium-icon --temp-high-icon --temp-low-fg-color --temp-medium-fg-color --temp-high-fg-color --temp-low-bg-color --temp-medium-bg-color --temp-high-bg-color --alert-icon --throttle-icon --notify --sep-left --sep-right --sep-bg --temp-unit --percentage-format --temp-format --freq-format --load-format --icons --fixed-width --percentage-label --temp-label --freq-label --load-label --load5-label --load15-label --count-label --graph-label --top-process-label --governor-label --cores-label --percentage-width --temp-width --freq-width --load-width --load5-width --load15-width --count-width --graph-width --top-process-width --governor-width --cores-width" -- "${cur}"))
}

complete -F _cpu_revamped cpu-revamped
