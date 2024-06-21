#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/helpers.sh
source "$CURRENT_DIR/helpers.sh"

sum_macos_vm_stats() {
  grep -Eo '[0-9]+' | awk '{ a += $1 * 16384 } END { print a }'
}

print_memory_free() {
  if [[ -r /proc/meminfo ]]; then
    cached_eval awk '/MemFree/{ printf("%2.2f\n", $2/1048576) }' </proc/meminfo
  elif command_exists "vm_stat"; then
    # page size of 16384 bytes
    stats="$(cached_eval vm_stat)"

    used_and_cached=$(
      echo "$stats" |
        grep -E "(Pages active|Pages inactive|Pages speculative|Pages wired down|Pages occupied by compressor)" |
        sum_macos_vm_stats
    )

    cached=$(
      echo "$stats" |
        grep -E "(Pages purgeable|File-backed pages)" |
        sum_macos_vm_stats
    )

    free=$(
      echo "$stats" |
        grep -E "(Pages free)" |
        sum_macos_vm_stats
    )

    used=$((used_and_cached - cached))
    total=$((used_and_cached + free))
    memory=$((total - used))

    echo "$memory" | awk '{printf("%2.2f\n", $1)}'
  fi
}

main() {
  print_memory_free
}

main
