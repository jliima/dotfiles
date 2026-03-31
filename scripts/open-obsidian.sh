#!/bin/sh

show_help() {
    cat << EOF
Usage: $(basename "$0") [VAULT]

Open an Obsidian vault. If no vault is specified, the vault is determined
based on the current KDE Plasma activity.

Arguments:
  VAULT    Optional vault name to open. Valid values:
           - work, work-vault       Opens work-vault
           - school, school-vault   Opens school-vault
           - default, default-vault Opens default-vault

Options:
  -h, --help    Show this help message and exit

Examples:
  $(basename "$0")           # Open vault based on current activity
  $(basename "$0") work      # Open work-vault
  $(basename "$0") school    # Open school-vault
EOF
}

# Handle help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Determine vault folder
if [ -n "$1" ]; then
    # Vault specified as argument
    case "$1" in
        work|work-vault)
            vault_dir="$HOME/Obsidian/work-vault"
            ;;
        school|school-vault)
            vault_dir="$HOME/Obsidian/school-vault"
            ;;
        default|default-vault)
            vault_dir="$HOME/Obsidian/default-vault"
            ;;
        *)
            echo "Error: Unknown vault '$1'" >&2
            echo "Valid vaults: work, school, default (or work-vault, school-vault, default-vault)" >&2
            exit 1
            ;;
    esac
else
    # No argument - use activity-based detection
    CURRENT_ACTIVITY=$(plasma-activities-cli6 --current-activity | awk '{print $3}')

    if [ "$CURRENT_ACTIVITY" = "Work" ]; then
        vault_dir="$HOME/Obsidian/work-vault"
    elif [ "$CURRENT_ACTIVITY" = "School" ]; then
        vault_dir="$HOME/Obsidian/school-vault"
    else
        vault_dir="$HOME/Obsidian/default-vault"
    fi
fi

echo "Vault dir: $vault_dir"

# Extract vault name (folder name)
vault_name=$(basename "$vault_dir")

# URL‑encode spaces (POSIX‑shell safe)
vault_name_encoded=$(printf '%s' "$vault_name" | sed 's/ /%20/g')

# Open via the obsidian:// URI
xdg-open "obsidian://open?vault=${vault_name_encoded}" >/dev/null 2>&1 &
