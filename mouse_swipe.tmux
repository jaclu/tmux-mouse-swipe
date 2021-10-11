#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

swipe_script="$CURRENT_DIR/scripts/tmux_mouse_swiping"

#source "$CURRENT_DIR/scripts/helpers.sh"

echo ">> Initiating mouse_swipe.tmux" >> /tmp/tmux_mouse_swiping.log
echo ">> location of swipe script  [$swipe_script]" >> /tmp/tmux_mouse_swiping.log

tmux set-option -s @mouse_drag_status  "untested"
#tmux bind-key -n MouseDrag3Pane    run "$swipe_script down \'#{mouse_x}\'"
tmux bind-key -n MouseDrag3Pane    run "$swipe_script down '#{mouse_x}'"
tmux bind-key -n MouseDragEnd3Pane run "$swipe_script up   \'#{mouse_x}\'"

tmux list-keys | grep 3Pane >> /tmp/tmux_mouse_swiping.log
