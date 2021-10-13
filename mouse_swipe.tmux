#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

swipe_script="$CURRENT_DIR/scripts/tmux_mouse_swiping"

# telling swipe_script to do an env check on first call
tmux set-option -s @mouse_drag_status  "untested"

tmux bind-key -n MouseDrag3Pane    run "$swipe_script down '#{mouse_x}' '#{mouse_y}'"
tmux bind-key -n MouseDragEnd3Pane run "$swipe_script up   '#{mouse_x}' '#{mouse_y}'"
