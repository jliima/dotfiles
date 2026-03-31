#!/usr/bin/env bash
# Bash completion for run-pywal.py
#
# To enable, add this line to ~/.bashrc or ~/.zshrc:
#   source "$HOME/dotfiles/scripts/pywal/run-pywal-completion.bash"

_run_pywal_completions() {
  local cur prev script_dir apps_dir app_names all_apps selected_apps remaining_apps
  local i in_app_context

  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  # Find the script directory (works for both direct call and alias)
  script_dir="$HOME/dotfiles/scripts/pywal"
  apps_dir="$script_dir/applications"

  # If previous word is --open-script, complete with application names
  if [[ "$prev" == "--open-script" ]]; then
    if [[ -d "$apps_dir" ]]; then
      app_names=$(find "$apps_dir" -maxdepth 1 -type f -name "*.sh" -printf "%f\n" 2>/dev/null | sed 's/\.sh$//' | sort)
      COMPREPLY=($(compgen -W "$app_names" -- "$cur"))
    fi
    return
  fi

  # Check if we're in --app context (after --app but before another flag)
  in_app_context=false
  for ((i=1; i < COMP_CWORD; i++)); do
    if [[ "${COMP_WORDS[i]}" == "--app" ]]; then
      in_app_context=true
    elif [[ "${COMP_WORDS[i]}" == --* ]]; then
      in_app_context=false
    fi
  done

  # If in --app context, suggest remaining apps not already selected
  if [[ "$in_app_context" == true ]]; then
    if [[ -d "$apps_dir" ]]; then
      all_apps=$(find "$apps_dir" -maxdepth 1 -type f -name "*.sh" -printf "%f\n" 2>/dev/null | sed 's/\.sh$//' | sort)

      # Collect already selected apps
      selected_apps=""
      for ((i=1; i < COMP_CWORD; i++)); do
        if [[ "${COMP_WORDS[i]}" == "--app" ]]; then
          continue
        elif [[ "${COMP_WORDS[i]}" == --* ]]; then
          break
        else
          selected_apps="$selected_apps ${COMP_WORDS[i]}"
        fi
      done

      # Filter out already selected apps
      remaining_apps=""
      for app in $all_apps; do
        if [[ ! " $selected_apps " =~ " $app " ]]; then
          remaining_apps="$remaining_apps $app"
        fi
      done

      # Also include other flags as options
      remaining_apps="$remaining_apps --debug --open-script --help -h"
      COMPREPLY=($(compgen -W "$remaining_apps" -- "$cur"))
    fi
    return
  fi

  # Default completion for flags
  local flags="--app --debug --open-script --help -h"
  COMPREPLY=($(compgen -W "$flags" -- "$cur"))
}

# Register completion for the script and common aliases
complete -F _run_pywal_completions run-pywal.py
complete -F _run_pywal_completions pare
complete -F _run_pywal_completions pare.sh
