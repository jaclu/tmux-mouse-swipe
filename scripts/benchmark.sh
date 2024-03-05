#!/usr/bin/env bash
#
#   Copyright (c) 2021-2023: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-mouse-swipe
#
#   Version: 1.2 2023-02-17
#
#
#  Benchmark script to test how responsive tmux_mouse_swiping is.
#  This does not use tmux events, so if you have changed the bound event,
#  it doesn't matter.
#
#  At least one tmux session must be running on the same machine as
#  this benchmark will be run, since  @mouse_drag_status will be read and set.
#  It doesn't matter if this is run inside tmux or not.
#
#  Setup for running benchmarks:
#
#  You will want to examine the following settings in:
#  scripts/tmux_mouse_swiping
#
#  benchmarking    Should be set to 1, otherwise this benchmark will try
#                  to change the focus of the running tmux.
#                  This benchmark is not meant to be testing how fast
#                  tmux can switch contexts, it is just about how fast
#                  mouse events are processed.
#
#                  >>>  Remember to set it back to 0 when you are done!
#
#
#  drag_stat_cache_file
#                  Experiment with enabling/disabling to see how much
#                  performance gain it gives you, on my laptop it is some
#                  20 times faster to use it. In the rare event it doesn't
#                  improve things. you can always leave it disabled.
#
#  debug()         If you want to see what is happening consider enabling
#                  this, on my machine this halves the performance of
#                  the benchmark...
#

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#
# amount of seconds this should run
#
duration=10

master_script="$(dirname "$CURRENT_DIR")"/mouse-swipe.tmux
swipe_script="$CURRENT_DIR"/handle_mouse_swipe.sh

# reset env, especially force a env_check at first run
$master_script

$swipe_script paramcheck

#
# First do one run, so env should have been picked up before the loop
#
$swipe_script down 2 2
$swipe_script up 4 2

echo "--- Will simulate mouse swiping for ${duration}s ---"
t_start="$(date +%s)"
t_end="$((t_start + duration))"

x=0
while :; do
    x=$((x + 1))
    $swipe_script down "$x" 5
    #
    # Calculating duration and comparing it inside the loop gives something
    # like a 25% overhead, but since it is constant on a given system,
    # it doesn't really matter. The interesting part is not
    # the absolute number, it is how it changes depending on code tweaks.
    #
    [[ "$(date +%s)" -ge "$t_end" ]] && break
done
echo "---  ending swipe  ---"

$swipe_script up "5" "5"

# shellcheck disable=SC2154
echo "Made $x swipe steps in ${duration} seconds"

$master_script # reset env again
