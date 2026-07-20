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
    org_mouse_x="${drag_start%%-*}"
    org_mouse_y="${drag_start#*-}"

    log_it 3 "drag_start_get() - X:$org_mouse_x Y:$org_mouse_y"
}

mouse_drag_start() {
    drag_start="$mouse_x-$mouse_y"

    [ -f "$f_drag_start" ] && {
        log_it 2 "mouse_drag_start($mouse_x, $mouse_y) - repeated call"
        return # drag has already started
    }
    log_it 2 " "
    log_it 3 "mouse_drag_start($mouse_x, $mouse_y)"

    echo "$drag_start" >"$f_drag_start" || {
        err_msg "Can't write to f_drag_start: $f_drag_start"
    }
}

mouse_drag_end() {
    log_it 3 "mouse_drag_end($mouse_x, $mouse_y)"

    drag_start_get

    diff_x=$((mouse_x - org_mouse_x))
    diff_y=$((mouse_y - org_mouse_y))

    # get abs of diffs
    abs_x=${diff_x#-}
    abs_y=${diff_y#-}

    log_it 2 "diff abs: [$abs_x][$abs_y] rel: [$diff_x][$diff_y]"

    if [ $((abs_x + abs_y)) -eq 0 ]; then # no movement
        # shellcheck disable=SC2154
        log_it 0 "$plugin_name: Did not detect any movement!"

    elif [ "$abs_x" -gt "$abs_y" ]; then # Horizontal swipe
        # shellcheck disable=SC2154
        if [ "$($TMUX_BIN list-windows -F '#{window_id}' | wc -l)" -lt 2 ]; then
            display_msg "Only one Window, can't switch!"
            return
        elif [ "$mouse_x" -gt "$org_mouse_x" ]; then
            log_it 1 "will switch to the right"
            $TMUX_BIN select-window -n
        else
            log_it 1 "will switch to the left"
            $TMUX_BIN select-window -p
        fi

    elif [ "$abs_x" -eq "$abs_y" ]; then # Unclear direction
        log_it 0 "$plugin_name: equal horizontal and vertical movement, direction unclear!"

    else # Vertical swipe
        if [ "$($TMUX_BIN list-sessions | wc -l)" -lt "2" ]; then
            display_msg "Only one Session, can't switch!"
            return
        elif [ "$mouse_y" -gt "$org_mouse_y" ]; then
            log_it 1 "will switch to next session"
            $TMUX_BIN switch-client -n
        else
            log_it 1 "will switch to previous session"
            $TMUX_BIN switch-client -p
        fi
    fi
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

d_scripts="$(realpath "$(dirname "$0")")"

# shellcheck source=/dev/null
. "$d_scripts"/utils.sh

action_name="$1"
mouse_x="$2"
mouse_y="$3"

[ -n "$action_name" ] || err_msg "$0: No action_name param"
[ -n "$mouse_x" ] || err_msg "$0: No mouse_x param"
[ -n "$mouse_y" ] || err_msg "$0: No mouse_y param"

if [ "$action_name" = "down" ]; then
    [ -f "$f_drag_start" ] && return # dragging has already started
    mouse_drag_start                 #  Start drag detected
elif [ "$action_name" = "up" ]; then
    mouse_drag_end
    clear_drag_start
else
    log_it 0 "ERROR: Unknown action: [$action_name]"
    echo
    echo "${plugin_name} ERROR: bad 1st param! [$action_name]"
    echo
    echo "Valid parameters:"
    echo "  down / up   Normal plugin usage"
    echo
    exit_cleanup 1
fi

exit 0
