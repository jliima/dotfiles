#!/bin/bash

# Terminal colors (Intense variants)
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "${BOLD}${CYAN}================================${NC}"
echo -e "${BOLD}${CYAN}  System Package Update Script  ${NC}"
echo -e "${BOLD}${CYAN}================================${NC}"

# Function to print section headers
print_header() {
    echo -e "${BOLD}${MAGENTA}>>> $1${NC}"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print info messages
print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Update Flatpak packages
echo ""
print_header "Updating Flatpak packages"
if command -v flatpak &> /dev/null; then
    if flatpak update -y; then
        print_success "Flatpak packages updated successfully"
    else
        print_error "Failed to update Flatpak packages"
    fi
else
    print_info "Flatpak is not installed, skipping..."
fi

# Update APT packages
echo ""
print_header "Updating APT packages"
if command -v apt &> /dev/null; then
    print_info "Updating package lists..."
    if sudo apt update 2>&1 | grep -v "stable CLI interface" | sed '/^[[:space:]]*$/d' | sed 's/^/  /'; then
        print_success "Package lists updated"
        
        print_info "Upgrading packages..."
        if sudo apt upgrade -y 2>&1 | grep -v "stable CLI interface" | sed '/^[[:space:]]*$/d' | sed 's/^/  /'; then
            print_success "Packages upgraded successfully"
        else
            print_error "Failed to upgrade packages"
        fi
    else
        print_error "Failed to update package lists"
    fi
else
    print_info "APT is not available, skipping..."
fi

# Update KDE Plasma plugins/widgets
print_header "Updating KDE Plasma plugins"
if [ "$XDG_CURRENT_DESKTOP" = "KDE" ] || [ "$DESKTOP_SESSION" = "plasma" ] || command -v plasmashell &> /dev/null; then
    # Try kpackagetool6 first (for Plasma 6), then kpackagetool5 (for Plasma 5)
    if command -v kpackagetool6 &> /dev/null; then
        KPACKAGE_CMD="kpackagetool6"
    elif command -v kpackagetool5 &> /dev/null; then
        KPACKAGE_CMD="kpackagetool5"
    else
        print_info "No KDE package tool found, skipping..."
        KPACKAGE_CMD=""
    fi
    
    if [ -n "$KPACKAGE_CMD" ]; then
        print_info "Checking for plugin updates using $KPACKAGE_CMD..."
        
        # Update Plasma widgets/applets
        if $KPACKAGE_CMD --type Plasma/Applet --upgrade-all 2>/dev/null; then
            print_success "Plasma widgets updated"
        else
            print_info "No Plasma widget updates available"
        fi
        
        # Update Plasma themes
        if $KPACKAGE_CMD --type Plasma/Theme --upgrade-all 2>/dev/null; then
            print_success "Plasma themes updated"
        else
            print_info "No Plasma theme updates available"
        fi
        
        # Update Plasma look and feel packages
        if $KPACKAGE_CMD --type Plasma/LookAndFeel --upgrade-all 2>/dev/null; then
            print_success "Plasma look and feel packages updated"
        else
            print_info "No look and feel updates available"
        fi
    fi
else
    print_info "KDE Plasma not detected, skipping plugin updates..."
fi

# Summary
echo ""
echo -e "${BOLD}${CYAN}================================${NC}"
echo -e "${BOLD}${CYAN}  Update process completed!${NC}"
echo -e "${BOLD}${CYAN}================================${NC}"
