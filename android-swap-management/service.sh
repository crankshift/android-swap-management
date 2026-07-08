#!/system/bin/sh
MODDIR=${0%/*}
CONF=$MODDIR/swap_size.conf
LOG=/data/local/tmp/android-swap-management.log
SWAPFILE=/data/local/tmp/swapfile
DEFAULT_SIZE_BYTES=8589934592
SIZE_16_BYTES=17179869184
RESERVE_KIB=262144
SWAP_PRIORITY=32767

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"
}

read_size_bytes() {
  size=$(cat "$CONF" 2>/dev/null || true)

  case "$size" in
    8589934592|17179869184)
      printf '%s\n' "$size"
      ;;
    *)
      log "invalid or missing swap size config; defaulting to 8589934592 bytes"
      printf '%s\n' "$DEFAULT_SIZE_BYTES"
      ;;
  esac
}

size_mib_for_bytes() {
  case "$1" in
    17179869184)
      printf '%s\n' 16384
      ;;
    *)
      printf '%s\n' 8192
      ;;
  esac
}

file_size_bytes() {
  [ -e "$SWAPFILE" ] || return 1

  size=$(stat -c '%s' "$SWAPFILE" 2>/dev/null || true)
  if [ -n "$size" ]; then
    printf '%s\n' "$size"
    return 0
  fi

  ls -ln "$SWAPFILE" 2>/dev/null | awk '{ print $5 }'
}

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

swap_is_active() {
  target=$(swap_target_for_swapfile || true)
  [ -n "$target" ]
}

disable_swapfile_swap() {
  target=$(swap_target_for_swapfile || true)
  if [ -n "$target" ]; then
    if ! swapoff "$target" >> "$LOG" 2>&1; then
      log "failed to disable active swap target=$target"
      return 1
    fi
    log "disabled active swap target=$target"
  fi

  loop=$(loop_for_swapfile || true)
  if [ -n "$loop" ]; then
    if ! losetup -d "$loop" >> "$LOG" 2>&1; then
      log "failed to detach loop device: $loop"
      return 1
    fi
    log "detached loop device: $loop"
  fi

  return 0
}

enable_disk_based_swap() {
  if [ -w /proc/sys/vm/disk_based_swap ]; then
    if printf '1\n' > /proc/sys/vm/disk_based_swap; then
      log "enabled /proc/sys/vm/disk_based_swap"
    else
      log "failed to enable /proc/sys/vm/disk_based_swap"
    fi
  fi
}

free_kib_for_data() {
  df -k /data 2>/dev/null | awk 'NR == 2 { print $4; exit }'
}

ensure_space() {
  size_bytes=$1
  current_size=$2
  size_kib=$(( (size_bytes + 1023) / 1024 ))
  required_kib=$(( size_kib + RESERVE_KIB ))
  free_kib=$(free_kib_for_data)

  case "$free_kib" in
    ''|*[!0-9]*)
      log "could not parse free space for /data; skipping swapfile creation"
      return 1
      ;;
  esac

  case "$current_size" in
    ''|*[!0-9]*)
      reusable_kib=0
      ;;
    *)
      reusable_kib=$(( (current_size + 1023) / 1024 ))
      ;;
  esac

  available_kib=$(( free_kib + reusable_kib ))

  if [ "$available_kib" -lt "$required_kib" ]; then
    log "not enough free space on /data: free=${free_kib}KiB reusable=${reusable_kib}KiB required=${required_kib}KiB"
    return 1
  fi

  return 0
}

create_swapfile() {
  size_bytes=$1
  size_mib=$(size_mib_for_bytes "$size_bytes")

  disable_swapfile_swap || return 1
  rm -f "$SWAPFILE"

  log "creating swapfile: path=$SWAPFILE size=${size_mib}MiB"
  if ! dd if=/dev/zero of="$SWAPFILE" bs=1048576 count="$size_mib" >> "$LOG" 2>&1; then
    log "failed to create swapfile"
    rm -f "$SWAPFILE"
    return 1
  fi

  if ! chmod 0600 "$SWAPFILE"; then
    log "failed to set swapfile permissions"
    rm -f "$SWAPFILE"
    return 1
  fi

  sync
  return 0
}

activate_loop_swap() {
  command -v losetup >/dev/null 2>&1 || {
    log "losetup unavailable; loop device fallback cannot run"
    return 1
  }

  loop=$(loop_for_swapfile || true)
  if [ -z "$loop" ]; then
    loop=$(losetup -f 2>> "$LOG" | awk 'NR == 1 { print $1; exit }')
    if [ -z "$loop" ]; then
      log "failed to find free loop device"
      return 1
    fi

    if ! losetup "$loop" "$SWAPFILE" >> "$LOG" 2>&1; then
      log "failed to attach swapfile to loop device: $loop"
      return 1
    fi
  fi

  if ! mkswap "$loop" >> "$LOG" 2>&1; then
    log "mkswap failed for loop device: $loop"
    losetup -d "$loop" >> "$LOG" 2>&1 || true
    return 1
  fi

  if ! swapon -p "$SWAP_PRIORITY" "$loop" >> "$LOG" 2>&1; then
    log "loop swapon failed: target=$loop"
    losetup -d "$loop" >> "$LOG" 2>&1 || true
    return 1
  fi

  log "swapfile configured through loop device: path=$SWAPFILE target=$loop size=${size_bytes} priority=${SWAP_PRIORITY}"
  return 0
}

size_bytes=$(read_size_bytes)
current_size=$(file_size_bytes || true)

if swap_is_active && [ "$current_size" = "$size_bytes" ]; then
  log "swapfile already active: path=$SWAPFILE size=${size_bytes}"
  exit 0
fi

if [ "$current_size" != "$size_bytes" ]; then
  ensure_space "$size_bytes" "$current_size" || exit 0
  create_swapfile "$size_bytes" || exit 0
else
  chmod 0600 "$SWAPFILE" || {
    log "failed to set swapfile permissions"
    exit 0
  }
fi

if ! mkswap "$SWAPFILE" >> "$LOG" 2>&1; then
  log "mkswap failed"
  exit 0
fi

enable_disk_based_swap

if swapon -p "$SWAP_PRIORITY" "$SWAPFILE" >> "$LOG" 2>&1; then
  log "swapfile configured: path=$SWAPFILE size=${size_bytes} priority=${SWAP_PRIORITY}"
  exit 0
fi

log "direct swapon failed; trying loop device fallback"
activate_loop_swap || log "swapon failed"
exit 0
