# tmux-mouse-swipe

Right click and swipe left or right in any pane to switch window in that direction or swipe up or down to switch session.

As allways any suggestions for improvements are welcome!

## Purpose

When you are at the keyboard obviously a key sequence is both faster and more natural to switch sessions or windows. 
I use this tool mostly to just getting a quick overview when having the terminal on a side screen, in such cases mouse swiping is handy.

The reason I wrote it as a posix script is that since it gets run multiple times in quick sequence,  on my iPad running iSH, there is a noticeable performance boost not having to repeatedly start bash scripts.

## Installation

Compatability: tmux version 3.0 or higher

### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

```tmux
set -g @plugin 'jaclu/tmux-mouse-swipe'
```

Hit `<prefix> + I` to fetch the plugin and source it.

### Manual Installation

Clone the repo:

```shell
git clone https://github.com/jaclu/tmux-mouse-swipe.git ~/clone/path
```

Add this line to the bottom of `.tmux.conf`:

```tmux
run-shell ~/clone/path/mouse_swipe.tmux
```

From the terminal, reload TMUX environment:

```shell
tmux source-file ~/.tmux.conf
```

## Usage

Once installed, try pressing down right button and swipe up, down, left or right on any pane.

Once you release the button, tmux should switch window after horizonal swipe and session after vertical.

If you only have one Window or Session, a message will be displayed that the requested action can not be performed, depending on swipe direction.

### Pane borders

tmux sends mouse coordinates relative to the pane that the mouse is over, so if you cross a pane border during the swipe, 
the direction of movement will most likely not be the intended.

### Basic modifications

The probably most likely thing to change would be to bind the actual script registering mouse events to other mouse triggering events. 
For that check mouse_swipe.tmux in the top directory of this repo.

### Performance

As of 2021-10-18 after using a benchmarking script I added to the repo and doing some tweaking, it can now handle arround 100 mouse events per second on my laptop.

Please note the plugin will be called each time the mouse moves another char, 
so on really slow systems, there might be some lag between letting go of the button 
and the windows switch to occur.
If you notice such lag, try a shorter move, you only need to swipe one character.

Let me know if that doesn't help, and I will see if I can optimize things further.

On any device with remotely normal performance, this should not be an issue, I only noticed this lag on an old iPad running iSH

## License

[MIT](LICENSE.md)
