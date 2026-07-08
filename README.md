# Android Swap Management

Magisk/KernelSU module that creates and enables a configurable Android swapfile at `/data/local/tmp/swapfile`.

## What It Does

- Creates a real storage-backed swapfile on `/data`.
- Lets you choose 8 GiB or 16 GiB during installation.
- Defaults to 8 GiB when no volume key is pressed.
- Runs `mkswap` and enables the swapfile with high priority at boot.
- Writes a boot log to `/data/local/tmp/android-swap-management.log`.
- Leaves ROM/system zram alone.

## Compatibility

This module is intended for rooted Android devices with Magisk or KernelSU where the ROM/kernel supports swapfiles on `/data`.

It is tested on OnePlus 15 / Lineage-based ROMs, but the implementation avoids OnePlus-specific runtime paths.

Swapfiles use storage and can affect performance, thermals, and flash wear. Install at your own risk.

## Download

Download the latest `android-swap-management-*.zip` from the GitHub Releases page for this repository.

## Install

1. Open Magisk Manager or KernelSU Manager.
2. Flash the release ZIP.
3. During installation, press Volume Up for 8 GiB or Volume Down for 16 GiB.
4. If no key is pressed, the module defaults to 8 GiB.
5. Reboot.

## Verify

Run these commands as root after reboot:

```sh
cat /proc/swaps
free -h
cat /data/local/tmp/android-swap-management.log
```

You should see `/data/local/tmp/swapfile` active with the selected size.

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

## Release Process

Releases are built by GitHub Actions when a version tag is pushed.

```sh
git tag v1.0
git push origin v1.0
```

The workflow builds the module ZIP, validates it, and uploads it to the GitHub Release for that tag. Keep `version=` in `android-swap-management/module.prop` aligned with the release tag.

## Uninstall

Remove the module in Magisk Manager or KernelSU Manager, then reboot. The uninstall script removes `/data/local/tmp/swapfile` and `/data/local/tmp/android-swap-management.log`.

## License

MIT License. See `LICENSE`.
