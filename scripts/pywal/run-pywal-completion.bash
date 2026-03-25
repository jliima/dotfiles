#!/usr/bin/env bash
# Bash completion for run-pywal.py
#
# To enable, add this line to ~/.bashrc or ~/.zshrc:
#   source "$HOME/dotfiles/scripts/pywal/run-pywal-completion.bash"

_run_pywal_completions() {
  local cur prev script_dir apps_dir app_names

  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  # Find the script directory (works for both direct call and alias)
  script_dir="$HOME/dotfiles/scripts/pywal"
  apps_dir="$script_dir/applications"

  # If previous word is --app, complete with application names
  if [[ "$prev" == "--app" ]]; then
    if [[ -d "$apps_dir" ]]; then
      # Get script names without .sh extension, filter by current input
      app_names=$(find "$apps_dir" -maxdepth 1 -type f -name "*.sh" -printf "%f\n" 2>/dev/null | sed 's/\.sh$//' | sort)
      COMPREPLY=($(compgen -W "$app_names" -- "$cur"))
    fi
    return
  fi

  # Default completion for flags
  local flags="--app --debug --help -h"
  COMPREPLY=($(compgen -W "$flags" -- "$cur"))
}

# Register completion for the script and common aliases
complete -F _run_pywal_completions run-pywal.py
complete -F _run_pywal_completions pare
complete -F _run_pywal_completions pare.sh
