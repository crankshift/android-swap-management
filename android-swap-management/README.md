# Android Swap Management

Magisk/KernelSU module authored by crankshift.

This module creates and enables `/data/local/tmp/swapfile` at boot.

Install-time size choices:

- Volume Up: 8 GiB
- Volume Down: 16 GiB
- No key press: 8 GiB

The module does not configure, disable, reset, or inspect zram.

## WebUI

Open WebUI from a root manager that supports module web interfaces, then choose 8 GiB or 16 GiB and tap Apply.

## Verify

Run as root after reboot:

```sh
cat /proc/swaps
free -h
cat /data/local/tmp/android-swap-management.log
```

You should see `/data/local/tmp/swapfile` active with the selected size. On ROMs that reject direct swapfiles, `/proc/swaps` may show a loop device backed by `/data/local/tmp/swapfile`.

## Remove

Remove the module in Magisk or KernelSU Manager, then reboot. The uninstall script removes `/data/local/tmp/swapfile` and the module log.
