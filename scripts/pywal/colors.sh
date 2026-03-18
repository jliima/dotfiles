#!/usr/bin/env bash

set -euo pipefail

input_file="${HOME}/.cache/wal/colors.sh"

if [[ ! -e "$input_file" ]]; then
  printf 'Error: file not found: %s\n' "$input_file" >&2
  exit 1
fi

if [[ ! -r "$input_file" ]]; then
  printf 'Error: file is not readable: %s\n' "$input_file" >&2
  exit 1
fi

normalize_hex() {
  local raw="${1#\#}"

  case "${#raw}" in
    3)
      printf '%s%s%s%s%s%s' \
        "${raw:0:1}" "${raw:0:1}" \
        "${raw:1:1}" "${raw:1:1}" \
        "${raw:2:1}" "${raw:2:1}"
      ;;
    6)
      printf '%s' "$raw"
      ;;
    8)
      printf '%s' "${raw:0:6}"
      ;;
    *)
      return 1
      ;;
  esac
}

color_to_rgb() {
  local normalized
  normalized="$(normalize_hex "$1")" || return 1
  printf '%d %d %d' \
    "$((16#${normalized:0:2}))" \
    "$((16#${normalized:2:2}))" \
    "$((16#${normalized:4:2}))"
}

pick_text_rgb() {
  local r="$1" g="$2" b="$3"
  local luminance=$(( (r * 299 + g * 587 + b * 114) / 1000 ))

  if (( luminance >= 140 )); then
    printf '0 0 0'
  else
    printf '255 255 255'
  fi
}

declare -A color_values=()
declare -a color_names=()

while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=[[:space:]]*[\"\']?(#[0-9A-Fa-f]{3,8})[\"\']?[[:space:]]*$ ]] || continue

  name="${BASH_REMATCH[1]}"
  value="${BASH_REMATCH[2]}"

  if [[ -v color_values["$name"] ]]; then
    color_values["$name"]="$value"
    continue
  fi

  color_values["$name"]="$value"
  color_names+=("$name")
done < "$input_file"

if (( ${#color_names[@]} == 0 )); then
  printf 'Error: no color variables found in %s\n' "$input_file" >&2
  exit 1
fi

max_label_length=0
for name in "${color_names[@]}"; do
  label="{${name}}"
  if (( ${#label} > max_label_length )); then
    max_label_length=${#label}
  fi
done

printf '\n'
printf 'Colors from %s\n\n' "$input_file"

for name in "${color_names[@]}"; do
  label="{${name}}"
  value="${color_values[$name]}"

  if rgb="$(color_to_rgb "$value")"; then
    read -r red green blue <<< "$rgb"
    read -r fg_red fg_green fg_blue <<< "$(pick_text_rgb "$red" "$green" "$blue")"

    printf "%-*s \033[48;2;%d;%d;%dm\033[38;2;%d;%d;%dm  %s  \033[0m\n" \
      "$max_label_length" "$label" \
      "$red" "$green" "$blue" \
      "$fg_red" "$fg_green" "$fg_blue" \
      "$value"
  else
    printf "%-*s %s\n" "$max_label_length" "$label" "$value"
  fi
done

printf '\n'
