#!/bin/sh
#
#   Copyright (c) 2022,2024,2026: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-menus
#
#  Common stuff
#

exit_cleanup() {
    # Cleanup then exit, if ex_code was given, terminate as an error
    ex_code="${1:-0}"
    clear_drag_start
    exit "$ex_code"
}

err_msg() {
    msg="$plugin_name - ERROR: $1"
    printf '\n%s\n' "$msg" >/dev/stderr
    exit_cleanup 1
}

display_msg() {
    # Friendly exit, display message on status-bar, then exit 0 in order not to
    # cause tmux to display a separate error about exit code not being 0
    msg="$1"
    [ -n "$msg" ] || err_msg "display_msg() - No param"
    log_it - "$msg"
    $TMUX_BIN display-message "$plugin_name: $msg"
    exit_cleanup
}

log_it() {
    #  Log if log_lvl <= debug_lvl

    [ -n "$log_file" ] || return # no log file being used
    log_lvl="$1"
    msg="$2"
    [ -n "$msg" ] || err_msg "log_it() - Call without msg param"
    [ "$log_lvl" -gt "$debug_lvl" ] && return

    printf "[%s] [%s] %s\n" "$(date '+%H:%M:%S')" "$log_lvl" "$msg" >>"$log_file"
}

clear_drag_start() {
    log_it 4 "clear_drag_start()"
    [ -n "$f_drag_start" ] && {
        rm -f "$f_drag_start" || err_msg "Failed to remove: $f_drag_start"
    }
}

verify_file_writeable() {
    fname="$1"

    [ -n "$fname" ] || err_msg "verify_file_writeable() - no param"

    d_file="$(dirname "$d_file")"
    mkdir -p "$d_file" 2>/dev/null || err_msg "Unable to create the directory for: $fname"
    touch "$fname" 2>/dev/null || err_msg "Unable to write to: $fname"
}

param_checks() {
    #
    #  Config check, if $1 is set, display variables
    #
    case "$1" in
        "") verbose="" ;;
        *) verbose=1 ;;
    esac

    [ -n "$plugin_name" ] || err_msg "Variable not defined: plugin_name"

    case "$debug_lvl" in
        *[!0123456789]*) err_msg "Not an integer value: debug_lvl: [$debug_lvl]" ;;
        *) ;;
    esac

    [ -n "$verbose" ] && printf 'Drag status cache-file: %s\n' "$f_drag_start"
    [ -n "$log_file" ] && {
        verify_file_writeable "$log_file"
        [ -n "$verbose" ] && {
            printf '\n\nLog file: %s\nLog lvl:  %s\n' "$log_file" "$debug_lvl"
        }
    }
    [ -n "$verbose" ] && printf '\nCompleted parameters check for: %s\n' "$plugin_name"
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
#  This is needed when checking backwards compatibility with various versions.
#  If not found, it is set to whatever is in path, so should have no negative
#  impact. In all calls to tmux I use $TMUX_BIN instead in the rest of this
#  plugin.
#
[ -z "$TMUX_BIN" ] && TMUX_BIN="tmux"

TMPDIR="${TMPDIR:-/tmp}"
TMPDIR="${TMPDIR%/}" # argh on some system TMPDIR incorrectly ends with /

f_drag_start="$TMPDIR/drag_status_cache-$(id -u)"

#
#  If log_file is empty or undefined, no logging will occur,
#  so comment it out for normal usage.
#
# log_file="$HOME/tmp/$plugin_name.log"

#
#  Notification types logged
#
#  0  Always logged
#  1  Announce action taken after a completed swipe
#  2  Display final movement detected
#  3  Display mouse locations start/stop drag
#  4  Display clear status
#
debug_lvl=9
