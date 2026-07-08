# Android Swap Management

Magisk/KernelSU module authored by crankshift.

This module creates and enables `/data/local/tmp/swapfile` at boot.

Install-time size choices:

- Volume Up: 8 GiB
- Volume Down: 16 GiB
- No key press: 8 GiB

The module does not configure, disable, reset, or inspect zram.

## Verify

Run as root after reboot:

```sh
cat /proc/swaps
free -h
cat /data/local/tmp/android-swap-management.log
```

You should see `/data/local/tmp/swapfile` active with the selected size.

## Remove

Remove the module in Magisk or KernelSU Manager, then reboot. The uninstall script removes `/data/local/tmp/swapfile` and the module log.
