#!/bin/sh
__version="1.4.1 2021-11-13"
#
#   Copyright (c) 2021: Jacob.Lundqvist@gmail.com for date see __version above
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-mouse-swipe
#
#   Version: $__version
#       Fixed a lot of bugs, that for some reason didn't show up on my system
#       sorry folks for causing issues!
#     1.4.0 2021-10-18
#       By using a benchmark script, I revrote a lot to increase performance
#       to be aprox 20 times faster!
#       Corrected Part of.. above
#       Corrected summary below
#     1.3.2 2021-10-13
#       Clarified message when no movement is detected
#     1.3.1 2021-10-13
#       Added handling of mouse_y to capture vertical swipes to switch session
#     1.3.0 2021-10-12
#       lot of cleanup and improved handle_up to make sure there was sideways motion
#     1.2.1 2021-10-11
#       corrected single window display-message to use simpler params for vers < 3.2
#     1.2.0 2021-10-11
#       Reworked logic to better detect invalid conditions, and
#       to deal with them.
#     1.1.2 2021-10-11
#       Some further tweaks to optimize performance on slow systems
#     1.1.1 2021-10-11
#       using cache file for status to reduce lag on slow systems
#     1.1.0 2021-10-11
#       Made comparison compliant with shellcheck recomendations
#     1.0.6 2021-09-29"
#       Udpdated info when detected tmux version is < 3.0
#     1.0.5 2021-09-28"
#       Initial deploy
#
#   This enables changing tmux windows or sessions by triggering the events
#   defined in mouse_swipe.tmux
#

#
#  set it to 1 if you are runing the benchmark script, but be aware
#  this will prevent any context switches, so should normally always be 0
#
benchmarking=0

#
#  If you do not want to use a ceche file during swipe operations
#  simplest is to just comment out the entire line, all code checks
#  if variable is defined, before using it.
#
#  On my machine using a cache file is aprox 20 times faster than storing
#  the values inside a tmux variable. You can test it on your system
#  by running benchmark.sh
#
drag_stat_cache_file="/tmp/drag_status_cache"






app_name="tmux_mouse_swiping"

action_name="$1"
mouse_x="$2"
mouse_y="$3"


min_version="3.0"

env_untested="untested"
env_incompatible="incompatible"
no_drag=0




log_file="/tmp/tmux_mouse_swiping.log"

debug() {
    return # comment out if you want to see a log of what is happening
    echo "$(date) $1" >> $log_file
}



remove_cache() {
    debug "remove_cache()"
    if [ -n "$drag_stat_cache_file" ] && [ -f "$drag_stat_cache_file" ]; then
        debug "  Found cache file, removing it"
        rm "$drag_stat_cache_file"
    fi
}


t_drag_status_set() {
    status="$1"
    push_it="$2"

    debug "drag_status_set($status, $push_it)"
    if [ -n "$drag_stat_cache_file" ]; then
        debug "  writing [$status] to $drag_stat_cache_file"
        echo "$status" > $drag_stat_cache_file
    else
        push_it=1 # not using cache, force saving to tmux
    fi
    drag_status="$status"
    if [ "$push_it" = "1" ]; then
        debug "  pushing status to tmux: $status"
        tmux set-option -s @mouse_drag_status "$status"
    fi
}


t_drag_status_get() {
    debug "t_drag_status_get()"
    if [ -n "$drag_stat_cache_file" ] && [ -f "$drag_stat_cache_file" ]; then
        drag_status="$(cat $drag_stat_cache_file)"
        debug "  < reading $drag_stat_cache_file, found: $drag_status"
    else
        drag_status="untested"
        ds_prel="$(tmux show -s @mouse_drag_status)"
        drag_status="$(echo "$ds_prel" | cut -d' ' -f 2)"
        debug "  < drag_status_get: prel[$ds_prel] status[$drag_status]"
    fi
}


incompatible_env() {
    msg="$1"
    if [ "$drag_status" != $env_incompatible ]; then
        echo " "
        echo "$app_name vers: $__version Detected an incompatible environment, and is now disabled"
        echo "Details should be bellow, press Escape when you have read this."
        echo "If you want to use this with limited functionality, change min_version in this script"
        echo "acordingly."
        echo " "
        drag_status=$env_incompatible
        t_drag_status_set "$drag_status" 1
    fi
    debug "*** Incompatability: $msg"
    echo "$msg"
}


env_check() {
    debug "env_check()"
    vers="$(tmux -V | cut -d' ' -f 2)"

    if [ "$drag_status" = "$env_incompatible" ]; then
        debug "env incompatible"
        clear_status
        exit 0
    elif [ "$drag_status" = "$env_untested" ] || [ -z "$drag_status" ]; then
        debug "  verifying env, vers[$vers]"
        if [ -z "$vers" ]; then
            incompatible_env "Can not detect the running tmux version, this tool neeeds at least tmux vers: $min_version"
            incompatible_env "Since it can't be detected to not be compatible, it will now be re-activated, but no guarantee anything will work."
            drag_status=$no_drag
            t_drag_status_set $drag_status 1
            return
        fi
        if  expr "'$vers" \< "'3.0"   > /dev/null ; then
            incompatible_env "vers < 3.0 no mouse_x / mouse_y support, so this utility can not work properly"
        fi
        if  expr "'$vers" \< "'$min_version"   > /dev/null ; then
            incompatible_env "tmux $vers < min vers: $min_version"
            clear_status
            exit 0
        fi
        debug "  no issues found"
        drag_status=$no_drag
        t_drag_status_set $drag_status 1
    fi
}


handle_up() {
    debug "handle_up()"

    case "$drag_status" in

        "$env_incompatible" )
            return
    esac

    org_mouse_x="${drag_status%%-*}"
    org_mouse_y="${drag_status#*-}"

    diff_x=$(( mouse_x - org_mouse_x ))
    diff_y=$(( mouse_y - org_mouse_y ))

    # get abs of diffs
    diff_x=${diff_x#-}
    diff_y=${diff_y#-}
    debug "diff abs: [$diff_x][$diff_y]"


    if [ $(( diff_x + diff_y )) -eq 0 ]; then
        tmux display-message "tmux-mouse-swipe: Did not detect any movement!"
    elif [ "$diff_x" -gt "$diff_y" ] ; then
        # Horizontal swipe
        if [ "$(tmux list-windows -F '#{window_id}' | wc -l)" -lt 2 ]; then
            tmux display-message "tmux-mouse-swipe: Only one window, can't switch!"
            return
        elif [ "$mouse_x" -gt "$org_mouse_x" ]; then
            debug "  will switch to the right"
            [ "$benchmarking" -eq 0 ] && tmux select-window -n
        else
            debug "  will switch to the left"
            [ "$benchmarking" -eq 0 ] && tmux select-window -p
        fi
    elif [ "$diff_y" -gt 0 ]; then
        # Vertical swipe
        if [ "$(tmux list-sessions | wc -l)" -lt "2" ]; then
            tmux display-message "tmux-mouse-swipe: Only one session, can't switch!"
            return
        elif [ "$mouse_y" -gt "$org_mouse_y" ]; then
            debug "  will switch to next session"
            [ "$benchmarking" -eq 0 ] && tmux switch-client -n
        else
            debug "  will switch to previous session"
            [ "$benchmarking" -eq 0 ] && tmux switch-client -p
        fi
    fi
}


clear_status() {
    debug "clear_status()"
    if [ "$drag_status" != "$env_incompatible" ]; then
        if [ -f "$drag_stat_cache_file" ]; then
            remove_cache
        else
            t_drag_status_set "$no_drag" 1 # reset it even if we dont move windows
        fi
    else
        remove_cache
    fi
    debug ""
}


#================================================================
#
#   Main
#
debug "tmux_mouse_swiping called, params: [$action_name] [$mouse_x] [$mouse_y]"

t_drag_status_get

debug "initial drag_status[$drag_status]"

case "$drag_status" in

    "$env_untested" | "")
        env_check
        ;;

    "$env_incompatible")
        debug "incompatible env!"
        clear_status
        exit 0
esac

debug "before checking action drag_status [$drag_status]"
if [ "$action_name" = "down" ] && [ "$drag_status" = "$no_drag" ]; then
    t_drag_status_set "$mouse_x-$mouse_y"  #  Start drag detected
elif [ "$action_name" = "up" ]; then
    handle_up
    clear_status
fi
