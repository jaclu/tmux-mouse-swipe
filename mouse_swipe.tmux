#!/usr/bin/env bash
#
#   Copyright (c) 2021: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-mouse-swipe
#
#   Version: 1.0  2021-10-07
#       Initial release
#

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

swipe_script="$CURRENT_DIR/scripts/tmux_mouse_swiping"

# telling swipe_script to do an env check on first call
tmux set-option -s @mouse_drag_status  "untested"

#
#   Fot all the info you need about Mouse events and locations, see
#   man tmux - MOUSE SUPPORT section. to find what best matches your needs.
#
tmux bind-key -n MouseDrag3Pane    run "$swipe_script down '#{mouse_x}' '#{mouse_y}'"
tmux bind-key -n MouseDragEnd3Pane run "$swipe_script up   '#{mouse_x}' '#{mouse_y}'"
