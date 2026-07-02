# OnePlus 15 ZRAM 8GB

Magisk/KernelSU module that configures `zram0` at boot for an 8 GiB compressed swap device.

## What It Does

- Sets `/sys/block/zram0/disksize` to 8 GiB.
- Uses `lz4` compression when the kernel exposes it in `comp_algorithm`.
- Runs `mkswap` and enables zram swap with high priority.
- Sets `/proc/sys/vm/swappiness` to `100` when writable.
- Writes a boot log to `/data/local/tmp/oneplus15-zram-8gb.log`.

## Compatibility

This module is intended for rooted OnePlus 15 systems with Magisk or KernelSU and an available `zram0` block device. It was written for setups where zram is exposed at `/sys/block/zram0` and the device node exists at `/dev/block/zram0` or `/dev/zram0`.

Changing swap and zram settings can affect stability, thermals, and performance. Install at your own risk.

## Download

Download the latest `oneplus15-zram-8gb-*.zip` from the GitHub Releases page for this repository.

## Install

1. Open Magisk Manager or KernelSU Manager.
2. Flash the release ZIP.
3. Reboot.

## Verify

Run these commands as root after reboot:

```sh
cat /proc/swaps
free -h
cat /data/local/tmp/oneplus15-zram-8gb.log
```

You should see `zram0` active with about 8 GiB of swap.

## Build From Source

Requirements:

- POSIX shell
- `zip`
- `unzip` for validation

Build the flashable ZIP:

```sh
./scripts/build.sh
```

The ZIP is written to `dist/`.

Validate the source and generated ZIP:

```sh
./tests/validate_module.sh
```

## Uninstall

Remove the module in Magisk Manager or KernelSU Manager, then reboot.

## License

MIT License. See `LICENSE`.
