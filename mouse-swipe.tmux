#!/usr/bin/env bash
#  shellcheck disable=SC2154
#  Directives for shellcheck directly after bang path are global
#
#   Copyright (c) 2021,2024: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-mouse-swipe
#

d_plugin="$(realpath "$(dirname "$0")")"

# shellcheck source=/dev/null
. "$d_plugin/scripts/utils.sh"

swipe_script="$d_plugin/scripts/handle_mouse_swipe.sh"

case "$1" in
paramcheck) param_checks ;;
"") ;;
*)
    echo
    echo "ERROR: bad param! [$1]"
    echo
    echo "Valid parameters:"
    echo "  paramcheck  ensures all used settings are valid"
    echo
    exit 1
    ;;
esac

clear_status

#
#  This normally triggers the right click default popups, they don't
#  play well when we use right clicks for other purposes.
#
$TMUX_BIN unbind-key -n MouseDown3Pane

#
#   For all the info you need about Mouse events and locations, see
#   man tmux - MOUSE SUPPORT section. to find what best matches your needs.
#
#  still by tmux 3.5a it seems Notes can't be assigned to mouse events...
#
$TMUX_BIN bind-key -n MouseDrag3Pane run "$swipe_script down '#{mouse_x}' '#{mouse_y}'"
$TMUX_BIN bind-key -n MouseDragEnd3Pane run "$swipe_script up   '#{mouse_x}' '#{mouse_y}'"
