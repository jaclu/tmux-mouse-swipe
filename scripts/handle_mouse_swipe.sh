#!/bin/sh
#
#   Copyright (c) 2021-2024,2026: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-mouse-swipe
#
#   This enables changing tmux windows or sessions by triggering the events
#   defined in mouse_swipe.tmux
#

drag_start_get() {
    # shellcheck disable=SC2154 # f_drag_start defined in utils.sh
    if [ -f "$f_drag_start" ]; then
        drag_start="$(cat "$f_drag_start")" || {
            err_msg "Can't read f_drag_start: $f_drag_start"
        }
    else
        #
        #  A drag end can arrive without a recorded drag start, for example
        #  when the drag began on the status line or a pane border (locations
        #  this plugin does not bind), or when the cache file was cleared by
        #  a config reload whilst a drag was in progress. There is nothing
        #  to act upon, so just ignore it.
        #
        display_msg "Failed to detect prior drag start"
    fi
    start_x="${drag_start%%-*}"
    start_y="${drag_start#*-}"

    log_it 6 "drag_start_get()   - X:$start_x Y:$start_y"
}

abort_if_drag_is_started() {
    [ -f "$f_drag_start" ] && {
        # drag has already started
        log_it 7 "  mouse_drag_start($mouse_x, $mouse_y) - repeated call"
        exit 0 # exit to ensure drag start location is not removed
    }
}

mouse_drag_start() {
    log_it 1 " " # blank line to separate swipes
    log_it 3 "mouse_drag_start() - X:$win_x Y:$win_y"
    drag_start="$win_x-$win_y"
    echo "$drag_start" >"$f_drag_start" || {
        err_msg "Can't write to f_drag_start: $f_drag_start"
    }
    exit 0
}

mouse_drag_end() {
    drag_start_get
    log_it 3 "mouse_drag_end()   - X:$win_x Y:$win_y"

    diff_x=$((win_x - start_x))
    diff_y=$((win_y - start_y))

    # get abs of diffs
    abs_x=${diff_x#-}
    abs_y=${diff_y#-}

    log_it 2 "diff abs: [$abs_x][$abs_y] rel: [$diff_x][$diff_y]"

    if [ $((diff_x + diff_y)) -eq 0 ]; then # no movement
        # shellcheck disable=SC2154
        log_it 1 "$plugin_name: Did not detect any movement!"

    elif [ "$abs_x" -gt "$abs_y" ]; then # Horizontal swipe
        # shellcheck disable=SC2154
        if [ "$($TMUX_BIN list-windows -F '#{window_id}' | wc -l)" -lt 2 ]; then
            display_msg "Only one Window, can't switch!"
        elif [ "$win_x" -gt "$start_x" ]; then
            log_it 1 "will switch to the right"
            $TMUX_BIN select-window -n
        else
            log_it 1 "will switch to the left"
            $TMUX_BIN select-window -p
        fi

    elif [ "$abs_x" -eq "$abs_y" ]; then # Unclear direction
        log_it 1 "Same horizontal and vertical movement, direction unclear!"
        display_msg "$plugin_name: Equal X & Y movement - direction unclear"

    else # Vertical swipe
        if [ "$($TMUX_BIN list-sessions | wc -l)" -lt "2" ]; then
            display_msg "Only one Session, can't switch!"
        elif [ "$mouse_y" -gt "$start_y" ]; then
            log_it 1 "will switch to next session"
            $TMUX_BIN switch-client -n
        else
            log_it 1 "will switch to previous session"
            $TMUX_BIN switch-client -p
        fi
    fi
}

param_validation() {
    log_it 6 "params: action_name[$action_name]"
    [ -n "$action_name" ] || err_msg "$0: No action_name param"
    [ -z "$mouse_x" ] && [ -z "$mouse_y" ] && {
        #
        # This can happen if the swipe crossed into another pane
        # Just abort this call, leaving the potential prior swipe start in place
        #
        log_it 0 "X and Y missing"
        exit 0
    }

    [ -z "$mouse_x" ] && err_msg "No mouse_x param given"
    [ -z "$mouse_y" ] && err_msg "No mouse_y param given"
    [ -z "$pane_x" ] && err_msg "No pane_x param given"
    [ -z "$pane_y" ] && err_msg "No pane_y param given"

    # Generate absolute window coordinates
    win_x=$((mouse_x + pane_x))
    win_y=$((mouse_y + pane_y))
    # log_it 6 "Window coordinates: $win_x $win_y"
}

#===============================================================
#
#   Main
#
#===============================================================

#
#  Avoid colliding if more than one tmux-server is running, by
#  extracting the socket name
#
# socket_name="$(tmux display -p "#{socket_path}" | sed 's/\// /g' | awk 'NF>1{print $NF}')"

d_scripts=$(cd "${0%/*}" && pwd)

# shellcheck source=/dev/null
. "$d_scripts"/utils.sh

action_name="$1"
mouse_x="$2"
mouse_y="$3"
pane_x="$4"
pane_y="$5"

param_validation

case "$action_name" in
    down)
        abort_if_drag_is_started
        # [ -f "$f_drag_start" ] && return # dragging has already started
        mouse_drag_start #  Start drag detected
        ;;
    up) mouse_drag_end ;;
    *)
        log_it 0 "ERROR: Unknown action: [$action_name]"
        echo
        echo "${plugin_name} ERROR: bad 1st param! [$action_name]"
        echo
        echo "Valid parameters:"
        echo "  down / up   Normal plugin usage"
        echo
        exit_cleanup 1
        ;;
esac

exit_cleanup
