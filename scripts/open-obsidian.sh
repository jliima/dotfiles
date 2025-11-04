#!/bin/sh

CURRENT_ACTIVITY=$(plasma-activities-cli6 --current-activity | awk '{print $3}')

# Determine vault folder based on activity
if [ "$CURRENT_ACTIVITY" = "Work" ]; then
    vault_dir="$HOME/Obsidian/work-vault"
elif [ "$CURRENT_ACTIVITY" = "School" ]; then
    vault_dir="$HOME/Obsidian/school-vault"
else
    vault_dir="$HOME/Obsidian/default-vault"
fi

echo "Vault dir: $vault_dir"

# Extract vault name (folder name)
vault_name=$(basename "$vault_dir")

# URL‑encode spaces (POSIX‑shell safe)
vault_name_encoded=$(printf '%s' "$vault_name" | sed 's/ /%20/g')

# Open via the obsidian:// URI
xdg-open "obsidian://open?vault=${vault_name_encoded}" >/dev/null 2>&1 &
