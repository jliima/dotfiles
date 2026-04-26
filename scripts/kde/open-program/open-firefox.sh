#!/usr/bin/env bash
# script location: /scripts/open-firefox.sh

show_help() {
    cat << EOF
Usage: $(basename "$0") [PROFILE] [FIREFOX_ARGS...]

Open Firefox with a specific profile. If no profile is specified, the profile
is determined based on the current KDE Plasma activity.

Arguments:
  PROFILE    Optional profile name to use. Valid values:
             - work       Uses Work profile
             - school     Uses School profile
             - default    Uses default profile (no --P flag)

Options:
  -h, --help    Show this help message and exit

Any additional arguments are passed directly to Firefox.

Examples:
  $(basename "$0")                    # Open based on current activity
  $(basename "$0") work               # Open with Work profile
  $(basename "$0") school             # Open with School profile
  $(basename "$0") work https://...   # Open Work profile with URL
EOF
}

# Handle help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Needed for custom Dark Reader plugin to work
export PATH="$HOME/.nvm/versions/node/v22.20.0/bin:$PATH"

# Check if first argument is a profile name
case "$1" in
    work)
        shift
        /usr/bin/firefox --P "Work" "$@"
        exit 0
        ;;
    school)
        shift
        /usr/bin/firefox --P "School" "$@"
        exit 0
        ;;
    default)
        shift
        /usr/bin/firefox "$@"
        exit 0
        ;;
esac

# No profile argument - use activity-based detection
CURRENT_ACTIVITY=$(plasma-activities-cli6 --current-activity | awk '{print $3}')

if [ "$CURRENT_ACTIVITY" = "Work" ]; then
    /usr/bin/firefox --P "Work" "$@"
elif [ "$CURRENT_ACTIVITY" = "School" ]; then
    /usr/bin/firefox --P "School" "$@"
else
    /usr/bin/firefox "$@"
fi
