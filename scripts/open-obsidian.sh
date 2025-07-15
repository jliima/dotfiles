#!/bin/sh

CURRENT_ACTIVITY_SCRIPT="$HOME/scripts/get-current-activity-name.sh"

# Get current activity
CURRENT_ACTIVITY=$("$CURRENT_ACTIVITY_SCRIPT")
echo "Activity: $CURRENT_ACTIVITY"

# Determine vault folder based on activity
if [ "$CURRENT_ACTIVITY" = "Work" ]; then
    vault_dir="$HOME/Obsidian/work_vault"
else
    vault_dir="$HOME/Obsidian/default_vault"
fi

echo "Vault dir: $vault_dir"

# Extract vault name (folder name)
vault_name=$(basename "$vault_dir")

# URL‑encode spaces (POSIX‑shell safe)
vault_name_encoded=$(printf '%s' "$vault_name" | sed 's/ /%20/g')

# Open via the obsidian:// URI
xdg-open "obsidian://open?vault=${vault_name_encoded}" >/dev/null 2>&1 &
