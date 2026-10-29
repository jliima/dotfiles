# shellcheck shell=bash
# Colored, indented status output for shell scripts. Source it, do not run it:
#
#   # shellcheck source=../helpers/log.sh
#   source "$(dirname "${BASH_SOURCE[0]}")/../helpers/log.sh"
#
#   log::header "Mounting vault"
#   log::info "Unlocking dataset"
#   log::indent
#   log::success "Dataset unlocked"
#   log::dedent
#   log::die "Mount failed"
#
# The Python counterpart is helpers/log.py and prints the same markers. Colors are dropped when the stream is not a
# terminal or NO_COLOR is set; FORCE_COLOR keeps them. LOG_TIMESTAMPS=1 puts [HH:MM:SS] in front of every line, for
# long runs whose output is tee'd or redirected.

# shellcheck disable=SC2034  # Colors are part of the library interface even when this file does not use them.
readonly LOG_INDENT_WIDTH=2
readonly LOG_RESET=$'\033[0m'
readonly LOG_BOLD=$'\033[1m'
readonly LOG_DIM=$'\033[2m'
readonly LOG_RED=$'\033[91m'
readonly LOG_GREEN=$'\033[92m'
readonly LOG_YELLOW=$'\033[93m'
readonly LOG_BLUE=$'\033[94m'
readonly LOG_MAGENTA=$'\033[95m'
readonly LOG_CYAN=$'\033[96m'
readonly LOG_WHITE=$'\033[97m'

# Current indent depth, changed by log::indent and log::dedent.
LOG_INDENT_LEVEL=0

# Set while a log::status line is unfinished.
LOG_STATUS_ACTIVE=0

# Set to 1 to send every message to stderr, for scripts whose stdout carries data.
LOG_STDERR_ONLY=0

# Set to 1 to prefix every line with the time.
LOG_TIMESTAMPS=0

# Set to 1 to silence log::header, log::info, log::detail and log::plain.
LOG_QUIET=0

#######################################
# Succeeds when ANSI colors should be written to a file descriptor.
# Arguments:
#   File descriptor, 1 or 2.
#######################################
log::use_color() {
  [[ -z "${NO_COLOR:-}" ]] && { [[ -n "${FORCE_COLOR:-}" ]] || [[ -t "$1" ]]; }
}

#######################################
# Prints one styled line per input line, indented.
# Globals:
#   LOG_INDENT_LEVEL, LOG_INDENT_WIDTH, LOG_QUIET, LOG_RESET, LOG_STATUS_ACTIVE, LOG_STDERR_ONLY, LOG_TIMESTAMPS
# Arguments:
#   File descriptor, 1 or 2.
#   Color and style codes, may be empty.
#   Marker, may be empty.
#   Message.
#   Non-empty if LOG_QUIET silences the line, optional.
# Outputs:
#   The lines on the file descriptor.
#######################################
log::emit() {
  local fd="$1" codes="$2" marker="$3" message="$4" quietable="${5:-}"
  local prefix line text
  if [[ -n "${quietable}" ]] && ((LOG_QUIET)); then
    return 0
  fi
  if ((LOG_STDERR_ONLY)); then
    fd=2
  fi
  if ((LOG_STATUS_ACTIVE)); then
    printf '\n' >&"${fd}"
    LOG_STATUS_ACTIVE=0
  fi
  printf -v prefix '%*s' $((LOG_INDENT_LEVEL * LOG_INDENT_WIDTH)) ''
  if ((LOG_TIMESTAMPS)); then
    prefix="[$(date +%H:%M:%S)] ${prefix}"
  fi
  while IFS= read -r line || [[ -n "${line}" ]]; do
    text="${marker:+${marker} }${line}"
    if [[ -n "${codes}" ]] && log::use_color "${fd}"; then
      text="${codes}${text}${LOG_RESET}"
    fi
    printf '%s%s\n' "${prefix}" "${text}" >&"${fd}"
  done <<< "${message}"
}

#######################################
# Shows a transient status on the current line, replaced by the next call and ended by the next message.
# Globals:
#   LOG_CYAN, LOG_RESET, LOG_STATUS_ACTIVE, LOG_STDERR_ONLY
# Arguments:
#   Message.
#######################################
log::status() {
  local fd=1
  if ((LOG_STDERR_ONLY)); then
    fd=2
  fi
  if log::use_color "${fd}"; then
    printf '\r%s%s%s  ' "${LOG_CYAN}" "$*" "${LOG_RESET}" >&"${fd}"
  else
    printf '\r%s  ' "$*" >&"${fd}"
  fi
  LOG_STATUS_ACTIVE=1
}

log::indent() { LOG_INDENT_LEVEL=$((LOG_INDENT_LEVEL + ${1:-1})); }

log::dedent() {
  LOG_INDENT_LEVEL=$((LOG_INDENT_LEVEL - ${1:-1}))
  if ((LOG_INDENT_LEVEL < 0)); then
    LOG_INDENT_LEVEL=0
  fi
}

log::header() { log::emit 1 "${LOG_BOLD}${LOG_MAGENTA}" '>>>' "$*" q; }
log::info() { log::emit 1 "${LOG_BLUE}" '>' "$*" q; }
log::success() { log::emit 1 "${LOG_GREEN}" '✓' "$*"; }
log::warn() { log::emit 2 "${LOG_YELLOW}" '!' "$*"; }
log::error() { log::emit 2 "${LOG_RED}" '✗' "$*"; }
log::detail() { log::emit 1 "${LOG_DIM}" '' "$*" q; }
log::plain() { log::emit 1 '' '' "$*" q; }

#######################################
# Prints an error and exits.
# Arguments:
#   Message.
#######################################
log::die() {
  log::error "$*"
  exit 1
}
