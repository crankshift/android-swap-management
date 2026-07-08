#!/system/bin/sh
SWAPFILE=/data/local/tmp/swapfile
LOG=/data/local/tmp/android-swap-management.log

swapoff "$SWAPFILE" 2>/dev/null || true
rm -f "$SWAPFILE"
rm -f "$LOG"
