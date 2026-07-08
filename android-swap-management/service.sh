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

swap_is_active() {
  [ -r /proc/swaps ] || return 1
  awk -v path="$SWAPFILE" '$1 == path { found = 1 } END { exit found ? 0 : 1 }' /proc/swaps
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

  swapoff "$SWAPFILE" 2>/dev/null || true
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

if ! swapon -p "$SWAP_PRIORITY" "$SWAPFILE" >> "$LOG" 2>&1; then
  log "swapon failed"
  exit 0
fi

log "swapfile configured: path=$SWAPFILE size=${size_bytes} priority=${SWAP_PRIORITY}"
exit 0
