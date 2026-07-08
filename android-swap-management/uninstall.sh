#!/system/bin/sh
SWAPFILE=/data/local/tmp/swapfile
LOG=/data/local/tmp/android-swap-management.log

loop_for_swapfile() {
  command -v losetup >/dev/null 2>&1 || return 1
  losetup -j "$SWAPFILE" 2>/dev/null | awk -F: 'NR == 1 { print $1; exit }'
}

swap_target_for_swapfile() {
  [ -r /proc/swaps ] || return 1

  if awk -v path="$SWAPFILE" '$1 == path { found = 1 } END { exit found ? 0 : 1 }' /proc/swaps; then
    printf '%s\n' "$SWAPFILE"
    return 0
  fi

  loop=$(loop_for_swapfile || true)
  [ -n "$loop" ] || return 1

  if awk -v path="$loop" '$1 == path { found = 1 } END { exit found ? 0 : 1 }' /proc/swaps; then
    printf '%s\n' "$loop"
    return 0
  fi

  return 1
}

target=$(swap_target_for_swapfile || true)
if [ -n "$target" ]; then
  swapoff "$target" 2>/dev/null || true
fi

loop=$(loop_for_swapfile || true)
if [ -n "$loop" ]; then
  losetup -d "$loop" 2>/dev/null || true
fi

swapoff "$SWAPFILE" 2>/dev/null || true
rm -f "$SWAPFILE"
rm -f "$LOG"
