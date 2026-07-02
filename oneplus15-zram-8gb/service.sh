#!/system/bin/sh
MODDIR=${0%/*}
LOG=/data/local/tmp/oneplus15-zram-8gb.log
ZRAM_SYS=/sys/block/zram0
SIZE_BYTES=8589934592
SWAPPINESS=100

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"
}

find_zram_dev() {
  if [ -e /dev/block/zram0 ]; then
    printf '%s\n' /dev/block/zram0
    return 0
  fi

  if [ -e /dev/zram0 ]; then
    printf '%s\n' /dev/zram0
    return 0
  fi

  return 1
}

ZRAM_DEV=
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if [ -d "$ZRAM_SYS" ]; then
    ZRAM_DEV=$(find_zram_dev) && break
  fi
  sleep 3
done

if [ ! -d "$ZRAM_SYS" ] || [ -z "$ZRAM_DEV" ]; then
  log "zram0 is not available; exiting"
  exit 0
fi

log "configuring $ZRAM_DEV"
swapoff "$ZRAM_DEV" 2>/dev/null

if [ -w "$ZRAM_SYS/reset" ]; then
  echo 1 > "$ZRAM_SYS/reset"
else
  log "reset node is not writable; exiting"
  exit 0
fi

if [ -r "$ZRAM_SYS/comp_algorithm" ] && grep -qw lz4 "$ZRAM_SYS/comp_algorithm"; then
  if echo lz4 > "$ZRAM_SYS/comp_algorithm"; then
    log "compression set to lz4"
  else
    log "failed to set lz4 compression; keeping kernel default"
  fi
else
  log "lz4 compression not available; keeping kernel default"
fi

if ! echo "$SIZE_BYTES" > "$ZRAM_SYS/disksize"; then
  log "failed to set zram disksize"
  exit 0
fi

if ! mkswap "$ZRAM_DEV" >> "$LOG" 2>&1; then
  log "mkswap failed"
  exit 0
fi

if ! swapon -p 32767 "$ZRAM_DEV" >> "$LOG" 2>&1; then
  log "swapon failed"
  exit 0
fi

if [ -w /proc/sys/vm/swappiness ]; then
  echo "$SWAPPINESS" > /proc/sys/vm/swappiness
fi

log "zram configured: size=${SIZE_BYTES}, swappiness=${SWAPPINESS}"
exit 0
