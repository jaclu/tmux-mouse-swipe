#!/bin/sh
#  shellcheck disable=SC2034
#  Directives for shellcheck directly after bang path are global
#
#   Copyright (c) 2022,2024: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-menus
#
#  Common stuff
#

#
#  Log if log_lvl <= debug_lvl
#
log_it() {
    if [ -z "$log_file" ]; then
        return
    fi
    log_lvl="$1"
    msg="$2"

    [ "$log_lvl" -gt "$debug_lvl" ] && return

    printf "[%s] [%s] %s\n" "$(date '+%H:%M:%S')" "$log_lvl" "$msg" >>"$log_file"
}

clear_status() {
    log_it 4 "clear_status()"
    rm -f "$f_drag_stat"
}

verify_file_writeable() {
    varibale_name="$1"
    fname="$2"

    if [ -z "$fname" ]; then
        echo "ERROR: verify_file_writeable() - no fname param!"
        exit 1
    fi
    if [ -z "$varibale_name" ]; then
        echo "ERROR: verify_file_writeable() - no varibale_name param!"
        exit 1
    fi

    file_dir="$(dirname "$fname")"
    if ! mkdir -p "$file_dir" 2>/dev/null; then
        echo "ERROR: $varibale_name - Can not create the directory for [$fname]!"
        exit 1
    fi

    if ! touch "$fname" 2>/dev/null; then
        echo "ERROR: $varibale_name - Can not create the file [$fname]!"
        exit 1
    fi
}

param_checks() {
    #
    #  Param check
    #

    # shellcheck disable=SC2154
    case "$debug_lvl" in
    *[!0123456789]*)
        echo "ERROR debug_lvl [$debug_lvl] not an integer value!"
        exit 1
        ;;
    *) ;;
    esac

    echo "Drag status cache-file: $f_drag_stat"
    [ -n "$log_file" ] && verify_file_writeable \
        log_file "$log_file"

    echo "Completed parameters check"
    exit 0
}

#===============================================================
#
#   Main
#
#===============================================================

[ -z "$d_plugin" ] && d_plugin="$(realpath "$(dirname "$(dirname "$0")")")"

#
#  Shorthand, to avoid manually typing package name on multiple
#  locations, easily getting out of sync.
#
plugin_name="tmux-mouse-swipe"

#
#  I use an env var TMUX_BIN to point at the current tmux, defined in my
#  tmux.conf, in order to pick the version matching the server running.
#  This is needed when checking backwards compatability with various versions.
#  If not found, it is set to whatever is in path, so should have no negative
#  impact. In all calls to tmux I use $TMUX_BIN instead in the rest of this
#  plugin.
#
[ -z "$TMUX_BIN" ] && TMUX_BIN="tmux"

TMPDIR="${TMPDIR:-/tmp}"
f_drag_stat="$TMPDIR/drag_status_cache-$(id -u)"

#
#  If log_file is empty or undefined, no logging will occur,
#  so comment it out for normal usage.
#
# log_file="$HOME/tmp/$plugin_name.log"

#
#  0  Always logged
#  1  Announce action taken after a completed swipe
#  2  Display final movement
#  3  Display mouse locations start/stop drag
#  4  Display clear status
#
debug_lvl=9
