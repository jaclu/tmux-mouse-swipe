#!/bin/sh
#  shellcheck disable=SC2034
#  Directives for shellcheck directly after bang path are global
#
#   Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-menus
#
#   Version: 1.3.1 2022-04-13
#
#  Common stuff
#


#
#  Shorthand, to avoid manually typing package name on multiple
#  locations, easily getting out of sync.
#
# plugin_name="tmux-mouse-swipe"


#
#  If log_file is empty or undefined, no logging will occur,
#  so comment it out for normal usage.
#
log_file="/tmp/$plugin_name.log"


#
#  0  Always logged
#  1  Announce action taken after a completed swipe
#  2  display final movement
#  3  entering more important functions
#  4  reading writing state
#  5  reading writing state functions
#  6  adv checks turned out ok
#  9  really detailed rarely to be used stuff
#
debug_lvl=2


#
#  If $log_file is empty or undefined, no logging will occur.
#
log_it() {
    if [ -z "$log_file" ]; then
        return
    fi
    printf "[%s] %s\n" "$(date '+%H:%M:%S')" "$@" >> "$log_file"
}
