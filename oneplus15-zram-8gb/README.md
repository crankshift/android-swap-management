# OnePlus 15 ZRAM 8GB

Magisk/KernelSU module authored by crankshift.

This configures `/sys/block/zram0` to:

- Size: 8192 MiB
- Compression: `lz4` when supported by the kernel
- Swappiness: `100`

## Install

Flash `oneplus15-zram-8gb-v1.0.zip` in Magisk or KernelSU Manager, then reboot.

## Verify

Run as root:

```sh
cat /proc/swaps
free -h
cat /data/local/tmp/oneplus15-zram-8gb.log
```

You should see zram0 active with about 8 GiB of swap.

## Remove

Remove the module in Magisk or KernelSU Manager, then reboot.
