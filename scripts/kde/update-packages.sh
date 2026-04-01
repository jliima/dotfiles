#!/bin/bash

# ~/scripts/update-packages.sh

# Terminal colors (Intense variants)
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'


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
  echo -e "${BLUE}> $1${NC}"
}

# Update APT packages
echo ""
print_header "Updating APT packages"
if command -v apt &> /dev/null; then
  print_info "sudo apt update && sudo apt upgrade -y"
  if sudo apt update && sudo apt upgrade -y; then
    print_success "sudo apt update && sudo apt upgrade -y"
  else
    print_error "Failed to run apt update/upgrade"
  fi
else
  print_info "APT is not available, skipping..."
fi

# Update Flatpak packages
echo ""
print_header "Updating Flatpak packages"
if command -v flatpak &> /dev/null; then
  print_info "flatpak update -y"
  if flatpak update -y; then
    print_success "flatpak update -y"
  else
    print_error "Failed to update Flatpak packages"
  fi
else
  print_info "Flatpak is not installed, skipping..."
fi

# Update KDE Plasma plugins/widgets
echo ""
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
    print_info "$KPACKAGE_CMD --type Plasma/Applet --upgrade-all"
    if $KPACKAGE_CMD --type Plasma/Applet --upgrade-all 2>/dev/null; then
      print_success "$KPACKAGE_CMD --type Plasma/Applet --upgrade-all"
    else
      echo "No Plasma widget updates available"
    fi

    print_info "$KPACKAGE_CMD --type Plasma/Theme --upgrade-all"
    if $KPACKAGE_CMD --type Plasma/Theme --upgrade-all 2>/dev/null; then
      print_success "$KPACKAGE_CMD --type Plasma/Theme --upgrade-all"
    else
      echo "No Plasma theme updates available"
    fi

    print_info "$KPACKAGE_CMD --type Plasma/LookAndFeel --upgrade-all"
    if $KPACKAGE_CMD --type Plasma/LookAndFeel --upgrade-all 2>/dev/null; then
      print_success "$KPACKAGE_CMD --type Plasma/LookAndFeel --upgrade-all"
    else
      echo "No look and feel updates available"
    fi
  fi
else
  print_info "KDE Plasma not detected, skipping plugin updates..."
fi

echo ""
echo -e "${BOLD}${GREEN}Finished running script${NC}"
