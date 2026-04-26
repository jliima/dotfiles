# Pywal instructions

## Core files/locations
- Pywal colorscheme folder: `~/dotfiles/.config/wal/colorschemes/dark`
- Pywal template folder: `~/dotfiles/.config/wal/templates`
- Created pywal theme cache folder: `~/.cache/wal/`
- Pywal running script: `~/dotfiles/scripts/pywal/run-pywal.py`
- Pywal custom application scripts folder: `~/dotfiles/scripts/pywal/applications`

## Example flow
1. Modify existing pywal colorscheme or create new one
2. Execute `run-pywal.py` script with desired flags, If targetting single application, select with the flag `--app <application_script_name>`. Example of full command: `python3 ~/dotfiles/scripts/pywal/run-pywal.py --theme parecolors --app obsidian --debug`
3. `~/.cache/wal/` is populated with the latest colors from the colorscheme `parecolors`
4. The application script `~/dotfiles/scripts/pywal/applications/obsidian.sh` is ran
5. `~/.cache/wal/colors-obsidian.css` is copied to the target folder `~/Obsidian/.config/.obsidian-desktop/themes/PywalColors/theme.css`

## About pywal templates
- Pywal templates refer to the colors in the colorscheme files with the notation `{color0}`. This produces the hex color variant defined in the colorscheme. To get rgb variant, they need to be referenced with the notation `{color0.rgb}`.
- Since the colors are always referenced inside curly braces, other curly braces need to be escaped by defining two curly braces in a row, e.g. `{{` becomes single `{` in the resulting theme.

## About application script
- The main point of the application scripts is to copy the resulting theme from the cache folder to the applications configuration folder.
- Some programs can be automatically refreshed by running some commands after the theme copying. This dependes on the situation.
- Some programs include special plugins that automatically refresh the program upon running the pywal script, e.g. VS code.
