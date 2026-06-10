---
name: open-gui
description: Use when the user explicitly invokes $open-gui or asks to open a file, folder, URL, app, or other local target in the macOS GUI using the open command. Resolve descriptive phrases like "this folder" to the correct shell target, then run open.
---

# Open GUI

Open the user's requested target with macOS `open`.

## Workflow

1. Interpret the user's descriptive argument as the target to open.
2. Resolve common phrases:
   1. `this folder`, `current folder`, `current directory`, `here`, `.` -> `.`
   2. `repo`, `repository`, `project` -> the current repository root if inside a Git repo, otherwise `.`
   3. `parent folder` -> `..`
   4. `home folder` -> `~`
3. If the target is a file or folder name, verify it exists before opening. Use `rg --files` or shell path checks when needed.
4. If the target is a URL, app name, or Finder-compatible target, no existence check is required.
5. Run `open "$TARGET"` from the relevant working directory. Quote the target safely.
6. If the description is ambiguous and there is no reasonable default, inspect local context first; ask only when the target cannot be determined.

## Examples

1. `$open-gui this folder` -> `open .`
2. `$open-gui current repo` -> `open "$(git rev-parse --show-toplevel)"`
3. `$open-gui the README` -> find the README path, then `open "$README_PATH"`
4. `$open-gui Safari` -> `open -a Safari`
