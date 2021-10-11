#!/usr/bin/env bash

#CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#source "$CURRENT_DIR/scripts/helpers.sh"

echo ">> Initiating mouse_swipe.tmux" >> /tmp/tmux_mouse_swiping.log

set-option -s @mouse_drag_status  "untested"
bind-key -n MouseDrag3Pane    run "$CURRENT_DIR/scripts/tmux_mouse_swiping down \'#{mouse_x}\'"
bind-key -n MouseDragEnd3Pane run "$CURRENT_DIR/scripts/tmux_mouse_swiping up   \'#{mouse_x}\'"
