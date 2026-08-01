# Chanelog

All notable changes to this project will be documented here.

---

## 2026-08-01

### Added

- Config params for swipe `@mouse_swipe_start` `@mouse_swipe_end`
- Combining mouse and pane coords,in order to get absolute positions in
  the tmux window, handling swipes crossing pane borders correctly

### Changed

- improved param handling and logging
- avoid using /dev/stderr, so that err msgs will be displayed when called via tmux
- display error if no log_lvl provided to log_it()
- renames: handle_mouse_down -> mouse_drag_start handle_mouse_up -> mouse_drag_end
- General Code cleanup, and partial rewrite
