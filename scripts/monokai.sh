#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $current_dir/utils.sh

main() {
  datafile=/tmp/.monokai-tmux-data

  # set configuration option variables
  show_fahrenheit=$(get_tmux_option "@monokai-show-fahrenheit" true)
  show_location=$(get_tmux_option "@monokai-show-location" true)
  fixed_location=$(get_tmux_option "@monokai-fixed-location")
  show_powerline=$(get_tmux_option "@monokai-show-powerline" true)
  show_flags=$(get_tmux_option "@monokai-show-flags" false)
  show_left_icon=$(get_tmux_option "@monokai-show-left-icon" session)
  show_left_icon_padding=$(get_tmux_option "@monokai-left-icon-padding" 0)
  show_military=$(get_tmux_option "@monokai-military-time" false)
  show_timezone=$(get_tmux_option "@monokai-show-timezone" true)
  show_left_sep=$(get_tmux_option "@monokai-show-left-sep" )
  show_right_sep=$(get_tmux_option "@monokai-show-right-sep" )
  show_border_contrast=$(get_tmux_option "@monokai-border-contrast" false)
  show_day_month=$(get_tmux_option "@monokai-day-month" false)
  show_refresh=$(get_tmux_option "@monokai-refresh-rate" 5)
  show_kubernetes_context_label=$(get_tmux_option "@monokai-kubernetes-context-label" "")
  IFS=' ' read -r -a plugins <<<$(get_tmux_option "@monokai-plugins" "cpu-usage ram-usage")

  # Monokai Pro Color Pallette
  # white='#fcfcfa'
  # black='#19181a'
  background='#2d2a2e'
  lightgray='#727072'
  # pink='#ff6188'
  # green='#a9dc76'
  # yellow='#ffd866'
  blue='#78dce8'
  orange='#fc9867'
  purple='#ab9df2'
  # red='#ff5c57'

  accent=${purple}
  accent2=${orange}

  dimmed1='#C1C0C0'
  # dimmed2='#939293'
  # dimmed3='#727072'
  # dimmed4='#5B595C'
  dimmed5='#403E41'

  # Handle left icon configuration
  case $show_left_icon in
  smiley)
    left_icon="☺"
    ;;
  session)
    left_icon="#S"
    ;;
  window)
    left_icon="#W"
    ;;
  *)
    left_icon=$show_left_icon
    ;;
  esac

  # Handle left icon padding
  padding=""
  if [ "$show_left_icon_padding" -gt "0" ]; then
    padding="$(printf '%*s' $show_left_icon_padding)"
  fi
  left_icon="$left_icon$padding"

  # Handle powerline option
  if $show_powerline; then
    right_sep="$show_right_sep"
    left_sep="$show_left_sep"
  fi

  # start weather script in background
  if [[ "${plugins[@]}" =~ "weather" ]]; then
    $current_dir/sleep_weather.sh $show_fahrenheit $show_location $fixed_location &
  fi

  # Set timezone unless hidden by configuration
  case $show_timezone in
  false)
    timezone=""
    ;;
  true)
    timezone="#(date +%Z)"
    ;;
  esac

  case $show_flags in
  false)
    flags=""
    current_flags=""
    ;;
  true)
    flags="#{?window_flags,#[fg=${purple}]#{window_flags},}"
    current_flags="#{?window_flags,#[fg=${purple}]#{window_flags},}"
    ;;
  esac

  # sets refresh interval to every 5 seconds
  tmux set-option -g status-interval $show_refresh

  # set the prefix + t time format
  if $show_military; then
    tmux set-option -g clock-mode-style 24
  else
    tmux set-option -g clock-mode-style 12
  fi

  # set length
  tmux set-option -g status-left-length 100
  tmux set-option -g status-right-length 100

  # pane border styling
  if $show_border_contrast; then
    tmux set-option -g pane-active-border-style "fg=${accent}"
  else
    tmux set-option -g pane-active-border-style "fg=${accent}"
  fi
  tmux set-option -g pane-border-style "fg=${dimmed5}"

  # message styling
  tmux set-option -g message-style "bg=${lightgray},fg=${dimmed1}"

  # status bar
  tmux set-option -g status-style "bg=${background},fg=${dimmed1}"

  # Status left
  if $show_powerline; then
    tmux set-option -g status-left "#[fg=${accent},bg=${background}]#{?client_prefix,#[fg=${accent2}],}#[bg=${accent},fg=${background},bold]#{?client_prefix,#[bg=${accent2}],} ${left_icon} #[fg=${accent},bg=${background}]#{?client_prefix,#[fg=${accent2}],}${left_sep}"
    powerbg=${background}
  else
    tmux set-option -g status-left "#[bg=${accent2},fg=${background},bold]#{?client_prefix,#[bg=${accent2}],} ${left_icon} "
  fi

  # Status right
  tmux set-option -g status-right ""

  for plugin in "${plugins[@]}"; do

    if [ $plugin = "git" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-git-colors" "accent background")
      script="#($current_dir/git.sh)"
    fi

    if [ $plugin = "battery" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-battery-colors" "pink background")
      script="#($current_dir/battery.sh)"
    fi

    if [ $plugin = "gpu-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-gpu-usage-colors" "pink background")
      script="#($current_dir/gpu_usage.sh)"
    fi

    if [ $plugin = "cpu-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-cpu-usage-colors" "background dimmed1 dimmed5")
      script="#($current_dir/cpu_info.sh)"
    fi

    if [ $plugin = "ram-usage" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-ram-usage-colors" "dimmed5 accent accent")
      script="#($current_dir/ram_info.sh)"
    fi

    if [ $plugin = "network" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-network-colors" "blue background")
      script="#($current_dir/network.sh)"
    fi

    if [ $plugin = "network-bandwidth" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-network-bandwidth-colors" "blue background")
      tmux set-option -g status-right-length 250
      script="#($current_dir/network_bandwidth.sh)"
    fi

    if [ $plugin = "network-ping" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-network-ping-colors" "background dimmed1")
      script="#($current_dir/network_ping.sh)"
    fi

    if [ $plugin = "spotify-tui" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-spotify-tui-colors" "green background")
      script="#($current_dir/spotify-tui.sh)"
    fi

    if [ $plugin = "kubernetes-context" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-kubernetes-context-colors" "blue background")
      script="#($current_dir/kubernetes_context.sh $show_kubernetes_context_label)"
    fi

    if [ $plugin = "weather" ]; then
      # wait unit $datafile exists just to avoid errors
      # this should almost never need to wait unless something unexpected occurs
      while [ ! -f $datafile ]; do
        sleep 0.01
      done

      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-weather-colors" "accent2 background")
      script="#(cat $datafile)"
    fi

    if [ $plugin = "time" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@monokai-time-colors" "green dimmed1")
      if $show_day_month && $show_military; then # military time and dd/mm
        script="%a %d/%m %R ${timezone} "
      elif $show_military; then # only military time
        script="%a %m/%d %R ${timezone} "
      elif $show_day_month; then # only dd/mm
        script="%a %d/%m %I:%M %p ${timezone} "
      else
        script="%a %m/%d %I:%M %p ${timezone} "
      fi
    fi

    if $show_powerline; then
    #   tmux set-option -ga status-right "#[fg=${!colors[0]},bg=${powerbg},nobold,nounderscore,noitalics]${right_sep}#[fg=${!colors[1]},bg=${!colors[0]}] $script "
      tmux set-option -ga status-right "#[fg=${!colors[0]},bg=${powerbg},nobold,nounderscore,noitalics]#[fg=${!colors[1]},bg=${!colors[0]}] $script #[fg=${!colors[2]},bg=${!colors[0]},nobold,nounderscore,noitalics]${right_sep}"

      powerbg=${!colors[0]}
    else
      tmux set-option -ga status-right "#[fg=${!colors[1]},bg=${!colors[0]}] $script "
    fi
  done

  if $show_powerline; then
    tmux set-option -ga status-right "#[bg=${accent},fg=${background},bold] #h #[bg=${background},fg=${accent}]"
  else
    tmux set-option -ga status-right "#[fg=${accent},bg=${blue}]${right_sep}#[bg=${accent},fg=${background},bold] #h "
  fi

  # Window option
  if $show_powerline; then
    tmux set-window-option -g window-status-current-format "#[bg=${accent},fg=${background}]${left_sep} #[fg=${background},bg=${accent}]#I #W${current_flags} #[bg=${background},fg=${accent}]${left_sep}"
  else
    tmux set-window-option -g window-status-current-format "#[fg=${background},bg=${dimmed1}] #I #W${current_flags}"
  fi

  tmux set-window-option -g window-status-format "#[bg=${dimmed5},fg=${background}]${left_sep} #[fg=${accent},bg=${dimmed5}]#I #W${flags} #[bg=${background},fg=${dimmed5}]${left_sep}"
  tmux set-window-option -g window-status-activity-style "bold"
  tmux set-window-option -g window-status-bell-style "bold"
  tmux set-window-option -g window-status-separator ""
}

# run main function
main
