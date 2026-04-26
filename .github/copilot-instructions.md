# AI Code Style Instructions

When generating or editing code in this repository, follow these rules:

- Use **2 spaces** for indentation (never tabs unless an existing file already requires tabs).
- Keep line length to a maximum of **120 characters**.
- Prefer **colored output** for user-facing terminal messages when appropriate
  (for example: status, success, warning, and error messages).
- **Never hardcode absolute home paths** (e.g. `/home/username/...`). Always use `$HOME` or `~` in shell
  scripts and `Path.home()` in Python so that scripts are portable across users and machines.

---

## Script Structure

Every script (shell or Python) **must** follow this structure in order:

1. **Shebang line**
2. **Header comment** — describes what the script does (see format below)
3. **Global variables / configuration** — paths, URLs, filenames, defaults
4. **Color definitions and output helpers**
5. **Functions**
6. **Main logic / entry point**

### Header Comment

Use this consistent format at the top of every script, right after the shebang:

**Shell:**
```bash
#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Name:        script-name.sh
# Description: One-line summary of what this script does.
#
# Details:
#   Longer explanation if needed. Describe behavior, side effects, or
#   dependencies here. Each detail line is indented with 2 spaces.
# ------------------------------------------------------------------------------
```

**Python:**
```python
#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Name:        script-name.py
# Description: One-line summary of what this script does.
#
# Details:
#   Longer explanation if needed. Describe behavior, side effects, or
#   dependencies here. Each detail line is indented with 2 spaces.
#
# Dependencies: requests, pathlib  (list non-stdlib dependencies)
# ------------------------------------------------------------------------------
```

### Global Variables

Declare **all** paths, file references, URLs, and configurable defaults as global variables at the top of
the script, immediately after the header comment and imports. This lets a reader quickly see what files and
resources the script touches.

**Shell:**
```bash
# ==== Configuration ====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CONFIG_FILE="$HOME/.config/myapp/config.toml"
LOG_FILE="/tmp/myscript.log"
```

**Python:**
```python
# ==== Configuration ====
SCRIPT_DIR = Path(__file__).parent.resolve()
WALLPAPER_DIR = Path.home() / "Pictures/Wallpapers"
CONFIG_FILE = Path.home() / ".config/myapp/config.toml"
LOG_FILE = Path("/tmp/myscript.log")
```

---

## Colored Output

Use the **exact** color definitions and helper functions below. Do not invent alternative approaches.
This keeps every script in the repo visually consistent.

### Shell — Colors and Helpers

```bash
# ==== Colors ====
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
BOLD='\033[1m'
NC='\033[0m'

# ==== Output helpers ====
print_header()  { echo -e "${BOLD}${MAGENTA}>>> $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error()   { echo -e "${RED}✗ $1${NC}"; }
print_info()    { echo -e "${BLUE}> $1${NC}"; }
print_warn()    { echo -e "${YELLOW}! $1${NC}"; }
```

### Python — Colors and Helpers

```python
import sys

class Colors:
  """ANSI color codes for terminal output."""
  RESET = "\033[0m"
  BOLD = "\033[1m"
  RED = "\033[91m"
  GREEN = "\033[92m"
  YELLOW = "\033[93m"
  BLUE = "\033[94m"
  MAGENTA = "\033[95m"
  CYAN = "\033[96m"


def print_header(message: str) -> None:
  """Print a section header."""
  print(f"{Colors.BOLD}{Colors.MAGENTA}>>> {message}{Colors.RESET}")


def print_success(message: str) -> None:
  """Print a success message."""
  print(f"{Colors.GREEN}✓ {message}{Colors.RESET}")


def print_error(message: str) -> None:
  """Print an error message."""
  print(f"{Colors.RED}✗ {message}{Colors.RESET}", file=sys.stderr)


def print_info(message: str) -> None:
  """Print an informational message."""
  print(f"{Colors.BLUE}> {message}{Colors.RESET}")


def print_warn(message: str) -> None:
  """Print a warning message."""
  print(f"{Colors.YELLOW}! {message}{Colors.RESET}", file=sys.stderr)
```

> **Rule:** Always use these helpers for user-facing messages. Never use bare `echo -e` with inline
> color codes or bare `print()` with manual ANSI sequences for status output.

---

## Help / Usage (`-h` / `--help`)

Every script **must** support `-h` and `--help` flags that print a usage summary and exit.

### Shell

```bash
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

  One-line description of what the script does.

Options:
  -h, --help    Show this help message and exit
EOF
}

# Parse flags (place near the top of the main logic)
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac
```

For scripts that accept more flags, use a `while` / `case` loop:

```bash
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -v|--verbose) VERBOSE=true; shift ;;
    *) print_error "Unknown option: $1"; usage; exit 1 ;;
  esac
done
```

### Python

Use `argparse` with a description that matches the header comment:

```python
import argparse

def create_parser() -> argparse.ArgumentParser:
  parser = argparse.ArgumentParser(
    description="One-line description of what the script does.",
    formatter_class=argparse.RawDescriptionHelpFormatter,
  )
  parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose output.")
  return parser
```

> `argparse` provides `-h` / `--help` automatically.

---

## Full Templates

### Shell Script Template

```bash
#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Name:        example.sh
# Description: Brief summary of the script's purpose.
#
# Details:
#   Additional context, behavior notes, or usage examples.
# ------------------------------------------------------------------------------
set -euo pipefail

# ==== Configuration ====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
TARGET_DIR="$HOME/.config/myapp"

# ==== Colors ====
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
BOLD='\033[1m'
NC='\033[0m'

# ==== Output helpers ====
print_header()  { echo -e "${BOLD}${MAGENTA}>>> $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error()   { echo -e "${RED}✗ $1${NC}"; }
print_info()    { echo -e "${BLUE}> $1${NC}"; }
print_warn()    { echo -e "${YELLOW}! $1${NC}"; }

# ==== Functions ====
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

  Brief summary of the script's purpose.

Options:
  -h, --help    Show this help message and exit
EOF
}

# ==== Main ====
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

print_header "Starting example"
# ... script logic ...
print_success "Done"
```

### Python Script Template

```python
#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Name:        example.py
# Description: Brief summary of the script's purpose.
#
# Details:
#   Additional context, behavior notes, or usage examples.
#
# Dependencies: requests  (list non-stdlib packages)
# ------------------------------------------------------------------------------

import argparse
import sys
from pathlib import Path

# ==== Configuration ====
SCRIPT_DIR = Path(__file__).parent.resolve()
TARGET_DIR = Path.home() / ".config/myapp"


# ==== Colors ====
class Colors:
  """ANSI color codes for terminal output."""
  RESET = "\033[0m"
  BOLD = "\033[1m"
  RED = "\033[91m"
  GREEN = "\033[92m"
  YELLOW = "\033[93m"
  BLUE = "\033[94m"
  MAGENTA = "\033[95m"
  CYAN = "\033[96m"


# ==== Output helpers ====
def print_header(message: str) -> None:
  """Print a section header."""
  print(f"{Colors.BOLD}{Colors.MAGENTA}>>> {message}{Colors.RESET}")


def print_success(message: str) -> None:
  """Print a success message."""
  print(f"{Colors.GREEN}✓ {message}{Colors.RESET}")


def print_error(message: str) -> None:
  """Print an error message."""
  print(f"{Colors.RED}✗ {message}{Colors.RESET}", file=sys.stderr)


def print_info(message: str) -> None:
  """Print an informational message."""
  print(f"{Colors.BLUE}> {message}{Colors.RESET}")


def print_warn(message: str) -> None:
  """Print a warning message."""
  print(f"{Colors.YELLOW}! {message}{Colors.RESET}", file=sys.stderr)


# ==== Functions ====
def create_parser() -> argparse.ArgumentParser:
  """Create the argument parser."""
  parser = argparse.ArgumentParser(
    description="Brief summary of the script's purpose.",
    formatter_class=argparse.RawDescriptionHelpFormatter,
  )
  parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose output.")
  return parser


def main() -> int:
  """Main entry point."""
  parser = create_parser()
  args = parser.parse_args()

  print_header("Starting example")
  # ... script logic ...
  print_success("Done")
  return 0


if __name__ == "__main__":
  sys.exit(main())
```
