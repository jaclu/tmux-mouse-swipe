#!/bin/sh
#
#   Copyright (c) 2021-2024: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-mouse-swipe
#
#   This enables changing tmux windows or sessions by triggering the events
#   defined in mouse_swipe.tmux
#

drag_start_set() {
    drag_start="$mouse_x-$mouse_y"

    log_it 3 "drag_start_set($drag_start)"

    # shellcheck disable=SC2154
    if ! echo "$drag_start" >"$f_drag_stat"; then
        echo "ERROR! can't write to f_drag_stat [$f_drag_stat]!"
        exit 1
    fi
}

drag_start_get() {

    if [ -f "$f_drag_stat" ]; then
        drag_start="$(cat "$f_drag_stat")"
    else
        echo "ERROR! No drag start file: $f_drag_stat"
        exit 1
    fi
    org_mouse_x="${drag_start%%-*}"
    org_mouse_y="${drag_start#*-}"

    log_it 3 "drag_start_get() - X:$org_mouse_x Y:$org_mouse_y"
}

handle_up() {
    log_it 3 "handle_up($mouse_x, $mouse_y)"

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
            log_it 0 "$plugin_name: Only one window, can't switch!"
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
            log_it 0 "$plugin_name: Only one session, can't switch!"
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

main() {
    # log_it 1 "$plugin_name called - parameters: [$action_name] [$mouse_x] [$mouse_y]"

    if [ "$action_name" = "down" ]; then
        [ -f "$f_drag_stat" ] && return # dragging has already started
        drag_start_set                  #  Start drag detected
    elif [ "$action_name" = "up" ]; then
        handle_up
        clear_status
    else
        log_it 0 "${plugin_name} ERROR: Unknown action: [$action_name]"
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

action_name="$1"
mouse_x="$2"
mouse_y="$3"

# shellcheck disable=SC1007
d_scripts="$(realpath "$(dirname "$0")")"

# shellcheck source=/dev/null
. "$d_scripts"/utils.sh

# . /Users/jaclu/git_repos/mine/tmux-mouse-swipe/scripts/utils.sh

case "$action_name" in
    "down" | "up") main ;;
    *)
        echo
        echo "${plugin_name} ERROR: bad 1st param! [$action_name]"
        echo
        echo "Valid parameters:"
        echo "  down / up   Normal plugin usage"
        echo
        exit 1
        ;;
esac

exit 0
