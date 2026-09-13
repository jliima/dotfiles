#!/usr/bin/env zsh
# removes existing history entries matching .zsh_history_ignore patterns
# multi-line commands are matched and removed as one entry, never split
# requires rg on PATH, asks for y/n confirmation before deleting anything
# pass --repair to drop orphaned entries (no head line) instead

SCRIPT_DIR="${0:A:h}"
IGNORE_FILE="$SCRIPT_DIR/.zsh_history_ignore"
STATE_DIR="$HOME/.local/state/zsh"

blue=$'\033[34m'
red=$'\033[91m'
reset=$'\033[0m'

build_rg_patterns() {
  local out="$1" p
  : > "$out"
  for p in "${patterns[@]}"; do
    printf '^(%s)$\n' "$p" >> "$out"
  done
}

# reads a history file into entry_raw[]/entry_flat[], one per entry
# entry_raw is the exact original text, entry_flat is a single-line version
# for matching (head prefix and continuation backslashes stripped)
# a line only continues the previous entry if that entry's last physical
# line ended in a backslash, so orphaned fragments stay their own entry
parse_history_file() {
  local file="$1"
  entry_raw=()
  entry_flat=()
  local pline body raw="" flat="" in_entry=0 continues=0

  while IFS= read -r pline || [[ -n "$pline" ]]; do
    if (( continues )); then
      raw="$raw"$'\n'"$pline"
      flat="$flat ${pline%\\}"
    else
      if (( in_entry )); then
        entry_raw+=("$raw")
        entry_flat+=("$flat")
      fi
      raw="$pline"
      if [[ "$pline" =~ '^: [0-9]+:[0-9]+;' ]]; then
        body="${pline#*;}"
      else
        body="$pline"
      fi
      flat="${body%\\}"
      in_entry=1
    fi
    [[ "$pline" == *'\' ]] && continues=1 || continues=0
  done < "$file"

  (( in_entry )) && { entry_raw+=("$raw"); entry_flat+=("$flat") }
}

# true if an entry's raw text starts with a proper history head
entry_has_head() {
  [[ "$1" =~ '^: [0-9]+:[0-9]+;' ]]
}

# populates entry_raw, entry_flat, and matched (entry_flat values that hit
# an ignore pattern) for one history file
load_ignore_matches() {
  local file="$1"
  parse_history_file "$file"
  matched=()
  (( ${#entry_flat[@]} == 0 )) && return

  local -A uniq
  local -a uniq_list
  local cmd
  for cmd in "${entry_flat[@]}"; do
    (( ${+uniq[$cmd]} )) || { uniq[$cmd]=1; uniq_list+=("$cmd") }
  done

  local uniq_file
  uniq_file="$(mktemp)"
  printf '%s\n' "${uniq_list[@]}" > "$uniq_file"

  # --max-columns=0 overrides any max-columns from RIPGREP_CONFIG_PATH
  # --no-unicode lets . match invalid UTF-8 bytes (e.g. mangled emoji)
  local rg_out
  rg_out="$(rg -N --max-columns=0 --no-unicode -f "$rg_patterns" -- "$uniq_file" 2>/dev/null)"
  rm -f "$uniq_file"

  [[ -z "$rg_out" ]] && return
  local m
  for m in "${(@f)rg_out}"; do
    matched[$m]=1
  done
}

# writes entries not flagged by $3 (a should_drop_* function) back to file,
# backing up the original first
apply_filter() {
  local file="$1" backup_dir="$2"
  local tmp idx changed=0
  tmp="$(mktemp)"
  for (( idx=1; idx<=${#entry_raw[@]}; idx++ )); do
    if "$3" "$idx"; then
      changed=1
      continue
    fi
    print -r -- "${entry_raw[$idx]}" >> "$tmp"
  done

  if (( changed )); then
    cp "$file" "$backup_dir/${file:t}.bak.$(date +%s)"
    mv "$tmp" "$file"
    echo "cleaned $file (backup saved in $backup_dir)"
  else
    rm -f "$tmp"
  fi
}

should_drop_matched() {
  (( ${+matched[${entry_flat[$1]}]} ))
}

should_drop_orphan() {
  ! entry_has_head "${entry_raw[$1]}"
}

run_repair() {
  local -a history_files
  history_files=(
    "$STATE_DIR"/history(N)
    "$STATE_DIR"/history_work(N)
    "$STATE_DIR"/history_archive/*(N)
    "$STATE_DIR"/history_archive_work/*(N)
  )

  local found=0 file idx
  for file in "${history_files[@]}"; do
    [[ -f "$file" ]] || continue
    parse_history_file "$file"
    local -a orphans
    orphans=()
    for (( idx=1; idx<=${#entry_raw[@]}; idx++ )); do
      entry_has_head "${entry_raw[$idx]}" || orphans+=("${entry_raw[$idx]}")
    done
    (( ${#orphans[@]} == 0 )) && continue
    found=1
    printf 'in %s%s%s:\n' "$blue" "$file" "$reset"
    printf '  %s\n' "${orphans[@]}"
    echo
  done

  if (( ! found )); then
    echo "no orphaned entries found"
    return 0
  fi

  local reply
  read -r "reply?remove these orphaned entries? [y/N] "
  if [[ "$reply" != [yY] ]]; then
    echo "cancelled"
    return 0
  fi

  local backup_dir="$STATE_DIR/.clean-history-backups"
  mkdir -p "$backup_dir"
  for file in "${history_files[@]}"; do
    [[ -f "$file" ]] || continue
    parse_history_file "$file"
    apply_filter "$file" "$backup_dir" should_drop_orphan
  done
}

run_clean() {
  if ! command -v rg >/dev/null; then
    echo "ripgrep (rg) is required but not found on PATH"
    return 1
  fi

  if [[ ! -f "$IGNORE_FILE" ]]; then
    echo "no ignore file found at $IGNORE_FILE"
    return 1
  fi

  local -a patterns
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == '#'* ]] && continue
    patterns+=("$line")
  done < "$IGNORE_FILE"

  if (( ${#patterns[@]} == 0 )); then
    echo "no patterns in $IGNORE_FILE"
    return 0
  fi

  local rg_patterns
  rg_patterns="$(mktemp)"
  build_rg_patterns "$rg_patterns"

  local -a history_files
  history_files=(
    "$STATE_DIR"/history(N)
    "$STATE_DIR"/history_work(N)
    "$STATE_DIR"/history_archive/*(N)
    "$STATE_DIR"/history_archive_work/*(N)
  )

  local found=0 file cmd c
  local -a shown_order
  local -A shown_count matched

  for file in "${history_files[@]}"; do
    [[ -f "$file" ]] || continue
    load_ignore_matches "$file"
    (( ${#matched[@]} == 0 )) && continue

    shown_order=()
    shown_count=()
    for cmd in "${entry_flat[@]}"; do
      (( ${+matched[$cmd]} )) || continue
      (( ${+shown_count[$cmd]} )) || shown_order+=("$cmd")
      (( shown_count[$cmd]++ ))
    done

    found=1
    printf 'in %s%s%s:\n' "$blue" "$file" "$reset"
    for c in "${shown_order[@]}"; do
      if (( shown_count[$c] > 1 )); then
        printf '  %s%s%s (%d entries)\n' "$red" "$c" "$reset" "$shown_count[$c]"
      else
        printf '  %s%s%s\n' "$red" "$c" "$reset"
      fi
    done
    echo
  done

  if (( ! found )); then
    echo "nothing in history matches the ignore list"
    rm -f "$rg_patterns"
    return 0
  fi

  local reply
  read -r "reply?remove these entries? [y/N] "
  if [[ "$reply" != [yY] ]]; then
    echo "cancelled"
    rm -f "$rg_patterns"
    return 0
  fi

  local backup_dir="$STATE_DIR/.clean-history-backups"
  mkdir -p "$backup_dir"
  for file in "${history_files[@]}"; do
    [[ -f "$file" ]] || continue
    load_ignore_matches "$file"
    (( ${#matched[@]} == 0 )) && continue
    apply_filter "$file" "$backup_dir" should_drop_matched
  done

  rm -f "$rg_patterns"
}

main() {
  if [[ "$1" == "--repair" ]]; then
    run_repair
  else
    run_clean
  fi
}

main "$@"
