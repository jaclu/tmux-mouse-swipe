#!/usr/bin/env bash
#
#   Copyright (c) 2021: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-mouse-swipe
#
#   Version: 1.1.2 2021-11-16
#       switched to -g flag for @mouse_drag_status
#     1.1.1 2021-11-14
#       Renamed action script to handle_mouse_swipe.sh
#       Sets initial mouse_drag_status as a server option to be
#       consistent between all sessions
#     1.1 2021-11-04
#       Added unbinding of the right click default popup
#     1.0  2021-10-07
#       Initial release
#

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

swipe_script="$CURRENT_DIR/scripts/handle_mouse_swipe.sh"


#
#  This normally triggers the right click default popups, they dont
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
tmux bind-key -n MouseDrag3Pane    run "$swipe_script down '#{mouse_x}' '#{mouse_y}'"
tmux bind-key -n MouseDragEnd3Pane run "$swipe_script up   '#{mouse_x}' '#{mouse_y}'"
