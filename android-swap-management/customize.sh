CONF=swap_size.conf
SIZE_8_BYTES=8589934592
SIZE_16_BYTES=17179869184

read_volume_key() {
  command -v getevent >/dev/null 2>&1 || return 1
  command -v timeout >/dev/null 2>&1 || return 1

  timeout 10 getevent -ql 2>/dev/null | while IFS= read -r line; do
    case "$line" in
      *KEY_VOLUMEUP*DOWN*)
        printf '%s\n' up
        exit 0
        ;;
      *KEY_VOLUMEDOWN*DOWN*)
        printf '%s\n' down
        exit 0
        ;;
    esac
  done
}

choose_swap_size() {
  key=$(read_volume_key || true)

  case "$key" in
    up)
      SWAP_SIZE_BYTES=$SIZE_8_BYTES
      SWAP_SIZE_LABEL="8 GiB"
      ;;
    down)
      SWAP_SIZE_BYTES=$SIZE_16_BYTES
      SWAP_SIZE_LABEL="16 GiB"
      ;;
    *)
      SWAP_SIZE_BYTES=$SIZE_8_BYTES
      SWAP_SIZE_LABEL="8 GiB"
      ;;
  esac
}

ui_print "- Android Swap Management"
ui_print "- Choose swapfile size now"
ui_print "- Press Volume Up for 8 GiB"
ui_print "- Press Volume Down for 16 GiB"
ui_print "- Waiting 10 seconds; default is 8 GiB"

choose_swap_size

printf '%s\n' "$SWAP_SIZE_BYTES" > "$MODPATH/$CONF" || abort "! Failed to write swap size config"
chmod 0644 "$MODPATH/$CONF"

ui_print "- Selected swapfile size: $SWAP_SIZE_LABEL"
ui_print "- Swapfile path: /data/local/tmp/swapfile"
