#!/usr/bin/env bash
#
#   Copyright (c) 2021,2022: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-mouse-swipe
#
#   Version: 1.2.0 2022-03-19
#

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SCRIPTS_DIR="$CURRENT_DIR/scripts"

. "$SCRIPTS_DIR/utils.sh"

swipe_script="$SCRIPTS_DIR/handle_mouse_swipe.sh"


#
#  Generic plugin setting I use to add Notes to keys that are bound
#  This makes this key binding show up when doing <prefix> ?
#  If not set to "Yes", no attempt at adding notes will happen
#  bind-key Notes were added in tmux 3.1, so should not be used on older versions!
#
if bool_param "$(get_tmux_option "@plugin_use_notes" "No")"; then
    use_notes=1
else
    use_notes=0
fi
log_it "use_notes=[$use_notes]"


#
#  This normally triggers the right click default popups, they don't
#  play well when we use right clicks for other purposes.
#
tmux unbind-key -n MouseDown3Pane


#
#  Telling handle_mose_swipe.sh to do an env check on first call.
#
#  I previously set this as a server setting with -s and it worked fine.
#  Until I whilst working on something else ran tmux customize-mode
#  tmux instantly crashed with "server exited unexpectedly".
#  It turned out this was caused by putting this user option with -s
#  tmux didn't show any error or warning when setting an -s user variable,
#  and it could be read fine with -s  :(
#
#  Either way now it is switched to a -g both here and in the handler script,
#  and this issue is gone!
#
tmux set-option -g @mouse_drag_status 'untested'


#
#   For all the info you need about Mouse events and locations, see
#   man tmux - MOUSE SUPPORT section. to find what best matches your needs.
#
if [ "$use_notes" -eq 1 ]; then
    tmux bind-key -N "tmux-mouse-swipe drag start" -n MouseDrag3Pane    run "$swipe_script down '#{mouse_x}' '#{mouse_y}'"
    tmux bind-key -N "tmux-mouse-swipe drag stop" -n MouseDragEnd3Pane run "$swipe_script up   '#{mouse_x}' '#{mouse_y}'"
else
    tmux bind-key -n MouseDrag3Pane    run "$swipe_script down '#{mouse_x}' '#{mouse_y}'"
    tmux bind-key -n MouseDragEnd3Pane run "$swipe_script up   '#{mouse_x}' '#{mouse_y}'"
fi
