#!/bin/sh
__version="1.4.2 2021-11-14"
#
#   Copyright (c) 2021: Jacob.Lundqvist@gmail.com for date see __version above
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-mouse-swipe
#
#   Version: $__version
#       Added param paramcheck, to verify user set variables
#       Implemented debug levels
#     1.4.1 2021-11-13
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
# 0  Critical Errors, always reported
# 1  Errors that are also reported via tmux
# 2  Announce action taken after a completed swipe
# 3  display final movement
# 4  entering more important functions
# 5  reading writing state
# 6  reading writing state functions
# 7  adv checks turned out ok
# 9  really detailed rarely to be used stuff
#
debug_lvl=0

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

#
#  set it to 1 if you are runing the benchmark script, but be aware
#  this will prevent any context switches, so should normally always be 0
#
benchmarking=0



log_file="/tmp/tmux_mouse_swiping.log"




app_name="tmux_mouse_swiping"

action_name="$1"
mouse_x="$2"
mouse_y="$3"


min_version="3.0"

env_untested="untested"
env_incompatible="incompatible"
no_drag=0



debug() {
    log_lvl="$1"
    msg="$2"

    case "$log_lvl" in
        (*[!0123456789]*)
            msg="ERROR log_lvl [$log_lvl] not an integer value!"
            if [ -n "$log_file" ]; then
                debug 0 "$msg"
            else
                echo "$msg"
            fi
            exit 1
            ;;
    esac

    [ "$log_lvl" -gt "$debug_lvl" ] && return
    [ -z "$log_file" ] && return

    echo "$(date) [$log_lvl] $msg" >> $log_file
}


verify_file_writeable() {
    varibale_name="$1"
    fname="$2"

    if [ -z "$fname" ]; then
        echo "ERROR: verify_file_writeable() - no fname param!"
        exit 1
    fi
    if [ -z "$varibale_name" ]; then
        echo "ERROR: verify_file_writeable() - no varibale_name param!"
        exit 1
    fi

    file_dir="$( dirname "$fname")"
    mkdir -p "$file_dir" 2> /dev/null
    if [ "$?" -ne 0 ]; then
        echo "ERROR: $varibale_name - Can not create the directory for [$fname]!"
        exit 1
    fi

    touch "$fname" 2> /dev/null
    if [ "$?" -ne 0 ]; then
        echo "ERROR: $varibale_name - Can not create the file [$fname]!"
        exit 1
    fi

}

param_checks() {
    #
    #  Param check
    #
    case "$benchmarking" in
        (*[!01]*)
            echo "ERROR benchmarking [$benchmarking] must be 0 or 1!"
            exit 1
            ;;
    esac

    case "$debug_lvl" in
        (*[!0123456789]*)
            echo "ERROR debug_lvl [$debug_lvl] not an integer value!"
            exit 1
            ;;
    esac

    [ -n "$drag_stat_cache_file" ] && verify_file_writeable \
        drag_stat_cache_file  "$drag_stat_cache_file"
    [ -n "$log_file" ] && verify_file_writeable \
        log_file  "$log_file"

    echo "Completed params check"
}


drag_status_set() {
    status="$1"
    push_it="$2"

    debug 4 "drag_status_set($status, $push_it)"
    if [ -n "$drag_stat_cache_file" ]; then
        debug 5 "  writing [$status] to $drag_stat_cache_file"
        echo "$status" > $drag_stat_cache_file
        if [ "$?" -ne 0 ]; then
            echo "ERROR! cant write to drag_stat_cache_file [$drag_stat_cache_file]!"
            exit 1
        fi
    else
        push_it=1 # not using cache, force saving to tmux
    fi
    drag_status="$status"
    if [ "$push_it" = "1" ]; then
        debug 5 "  pushing status to tmux: $status"
        tmux set-option -s @mouse_drag_status "$status"
    fi
}


drag_status_get() {
    debug 6 "drag_status_get()"
    if [ -n "$drag_stat_cache_file" ] && [ -f "$drag_stat_cache_file" ]; then
        drag_status="$(cat $drag_stat_cache_file)"
        debug 5 "  < reading $drag_stat_cache_file, found: $drag_status"
    else
        drag_status="untested"
        ds_prel="$(tmux show -s @mouse_drag_status)"
        drag_status="$(echo "$ds_prel" | cut -d' ' -f 2)"
        debug 5 "  < drag_status_get: prel[$ds_prel] status[$drag_status]"
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
        drag_status_set "$drag_status" 1
    fi
    debug 1 "*** Incompatability: $msg"
    echo "$msg"
}


env_check() {
    debug 4 "env_check()"
    vers="$(tmux -V | cut -d' ' -f 2)"

    if [ "$drag_status" = "$env_incompatible" ]; then
        debug 0 "ERROR: env incompatible"
        clear_status
        exit 0
    elif [ "$drag_status" = "$env_untested" ] || [ -z "$drag_status" ]; then
        if [ -z "$vers" ]; then
            incompatible_env "Can not detect the running tmux version, this tool neeeds at least tmux vers: $min_version"
            incompatible_env "Since it can't be detected to not be compatible, it will now be re-activated, but no guarantee anything will work."
            drag_status=$no_drag
            drag_status_set $drag_status 1
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
        debug 7 "  no issues found"
        drag_status=$no_drag
        drag_status_set $drag_status 1
    fi
}


handle_up() {
    debug 4 "handle_up()"

    case "$drag_status" in

        "$env_incompatible" )
            return
    esac

    org_mouse_x="${drag_status%%-*}"
    org_mouse_y="${drag_status#*-}"

    diff_x=$(( mouse_x - org_mouse_x ))
    diff_y=$(( mouse_y - org_mouse_y ))

    # get abs of diffs
    abs_x=${diff_x#-}
    abs_y=${diff_y#-}

    debug 3 "diff abs: [$abs_x][$abs_y] rel: [$diff_x][$diff_y]"

    if [ $(( abs_x + abs_y )) -eq 0 ]; then
        msg="tmux-mouse-swipe: Did not detect any movement!"
        debug 2 "$msg"
        tmux display-message "$msg"
    elif [ "$abs_x" -gt "$abs_y" ] ; then
        # Horizontal swipe
        if [ "$(tmux list-windows -F '#{window_id}' | wc -l)" -lt 2 ]; then
            msg="tmux-mouse-swipe: Only one window, can't switch!"
            debug 2 "$msg"
            tmux display-message "$msg"
            return
        elif [ "$mouse_x" -gt "$org_mouse_x" ]; then
            debug 2 "  will switch to the right"
            [ "$benchmarking" -eq 0 ] && tmux select-window -n
        else
            debug 2 "  will switch to the left"
            [ "$benchmarking" -eq 0 ] && tmux select-window -p
        fi
    #elif [ "$abs_y" -gt 0 ]; then
    else
        # Vertical swipe
        if [ "$(tmux list-sessions | wc -l)" -lt "2" ]; then
            msg="tmux-mouse-swipe: Only one session, can't switch!"
            debug 2 "$msg"
            tmux display-message "$msg"
            return
        elif [ "$mouse_y" -gt "$org_mouse_y" ]; then
            debug 2 "  will switch to next session"
            [ "$benchmarking" -eq 0 ] && tmux switch-client -n
        else
            debug 2 "  will switch to previous session"
            [ "$benchmarking" -eq 0 ] && tmux switch-client -p
        fi
    fi
}


clear_status() {
    debug 6 "clear_status()"
    if [ "$drag_status" != "$env_incompatible" ]; then
        if [ -f "$drag_stat_cache_file" ]; then
            remove_cache
        else
            drag_status_set "$no_drag" 1 # reset it even if we dont move windows
        fi
    else
        remove_cache
    fi
    debug 9 ""
}


remove_cache() {
    debug 6 "remove_cache()"
    if [ -n "$drag_stat_cache_file" ] && [ -f "$drag_stat_cache_file" ]; then
        debug 5 "  Found cache file [$drag_stat_cache_file], removing it"
        rm "$drag_stat_cache_file"
    fi
}


main() {
    debug 9 "tmux_mouse_swiping called, params: [$action_name] [$mouse_x] [$mouse_y]"

    drag_status_get

    debug 9 "initial drag_status[$drag_status]"

    case "$drag_status" in

        "$env_untested" | "")
            env_check
            ;;

        "$env_incompatible")
            debug 0 "ERROR: incompatible env!"
            clear_status
            exit 0
    esac

    debug 9 "verified drag_status [$drag_status]"
    if [ "$action_name" = "down" ] && [ "$drag_status" = "$no_drag" ]; then
        drag_status_set "$mouse_x-$mouse_y"  #  Start drag detected
    elif [ "$action_name" = "up" ]; then
        handle_up
        clear_status
    fi
}


#================================================================
#
#   Main
#

case "$action_name" in

    "down" | "up" ) main ;;

    "paramcheck" ) param_checks ;;

    *)  echo
        echo "ERROR: bad param! [$action_name]"
        echo
        echo "Valid params:"
        echo "  paramcheck  ensures all usese settings are valid"
        echo
        echo "  down / up   Normal plugin usage"
        echo
        exit 1
        ;;
esac



