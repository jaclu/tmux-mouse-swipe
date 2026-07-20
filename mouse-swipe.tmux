#!/bin/sh
#
#   Copyright (c) 2021,2024,2026: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-mouse-swipe
#

d_plugin=$(cd "${0%/*}" && pwd)

# shellcheck source=/dev/null
. "$d_plugin/scripts/utils.sh"

swipe_script="$d_plugin/scripts/handle_mouse_swipe.sh"

case "$1" in
    config)
        config_check -v
        exit_cleanup
        ;;
    "") ;;
    *)
        log_it 0 "Bad option [$1]"
        echo
        echo "ERROR: bad option! [$1]"
        echo
        echo "Valid options:"
        echo "  config - Display settings"
        echo
        exit_cleanup 1
        ;;
esac

config_check

#
#  This normally triggers the right click default popups, they don't
#  play well when we use right clicks for other purposes.
#
# shellcheck disable=SC2154 # TMUX_BIN defined in scripts/utils.sh
$TMUX_BIN unbind-key -n MouseDown3Pane

#
#   For all the info you need about Mouse events and locations, see
#   man tmux - MOUSE SUPPORT section. to find what best matches your needs.
#
#  still by tmux 3.5a it seems Notes can't be assigned to mouse events...
#

$TMUX_BIN bind-key -n MouseDrag3Pane run "$swipe_script down  '#{mouse_x}' '#{mouse_y}'"
$TMUX_BIN bind-key -n MouseDragEnd3Pane run "$swipe_script up '#{mouse_x}' '#{mouse_y}'"

exit_cleanup
