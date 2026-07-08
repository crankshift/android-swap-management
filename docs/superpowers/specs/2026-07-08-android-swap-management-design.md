# Android Swap Management Design

## Goal

Replace the current OnePlus 15 zram module with a universal Android swapfile module. The module should manage a real swapfile at `/data/local/tmp/swapfile`, let users choose 8 GiB or 16 GiB during installation with volume keys, and stop configuring zram entirely.

## Product Name

Use `Android Swap Management` as the user-facing module name.

Use `android-swap-management` as the module id and source directory name.

The repository can keep its current git history, but public documentation, generated ZIP names, module metadata, logs, and validation checks should move to the new name.

## Current State

The existing module is named `OnePlus 15 ZRAM 8GB` and only configures `/sys/block/zram0`. It does not create or enable `/data/local/tmp/swapfile`.

That behavior does not match the new goal. Zram is compressed swap backed by RAM, while the requested module should provide storage-backed swap through a file on `/data`.

## Scope

The new module will:

- Create and manage `/data/local/tmp/swapfile`.
- Support 8 GiB and 16 GiB swapfile sizes.
- Default to 8 GiB when no volume key selection is made.
- Enable the swapfile on boot with high priority.
- Remove the swapfile during uninstall.
- Avoid OnePlus-specific runtime assumptions.

The new module will not:

- Configure `/sys/block/zram0`.
- Reset, disable, or inspect system zram.
- Attempt to manage ROM-provided swap devices.
- Provide a WebUI settings page in this change.

## Installer Flow

The installer will present a volume-key selection UI:

- Volume Up selects 8 GiB.
- Volume Down selects 16 GiB.
- Timeout or no detected key selects 8 GiB.

The installer will write the selected size in bytes to `swap_size.conf` in the module directory.

The installer should print the chosen size and make clear that the module will create the swapfile after reboot.

## Runtime Service

`service.sh` will read the configured swapfile size at boot.

If the config file is missing or invalid, the service will fall back to 8 GiB.

The service will:

- Use `/data/local/tmp/swapfile` as the only managed swap target.
- Check available space on `/data` before creating or resizing the file when `df -k /data` output can be parsed. Require at least the selected size plus 256 MiB of free space.
- Create or recreate the swapfile if it is missing or has the wrong size.
- Create the swapfile as a fully allocated file, not a sparse file.
- Set permissions to `0600`.
- Run `mkswap` on the file.
- Enable it with `swapon -p 32767`.
- Log status to `/data/local/tmp/android-swap-management.log`.

If creation, formatting, or activation fails, the service will log the failure and exit without touching zram.

## Uninstall

`uninstall.sh` will:

- Run `swapoff /data/local/tmp/swapfile` if possible.
- Remove `/data/local/tmp/swapfile`.
- Remove `/data/local/tmp/android-swap-management.log`.

It will not change any zram state.

## Compatibility

The module is intended to be universal for rooted Android devices using Magisk or KernelSU, provided the ROM/kernel supports swapfiles on `/data`.

Documentation should state that the module is tested on OnePlus 15 / Lineage-based ROMs, but not limited to that device.

The README should warn about storage use, performance cost, thermals, and flash wear.

## Build And Validation

The build script should generate `dist/android-swap-management-<version>.zip`.

Validation should check:

- Module metadata uses `android-swap-management` and `Android Swap Management`.
- Runtime scripts contain `/data/local/tmp/swapfile`.
- Runtime scripts no longer contain zram management paths such as `/sys/block/zram0` or `/dev/zram0`.
- Installer code contains the 8 GiB, 16 GiB, and default 8 GiB choices.
- Uninstall removes the managed swapfile and log.
- The generated ZIP contains module files at archive root.

## Testing

Local validation should include:

```sh
./scripts/build.sh
./tests/validate_module.sh
```

Shell syntax checks should run against `service.sh`, `uninstall.sh`, `update-binary`, and `scripts/build.sh`.

Runtime behavior on an Android device should be verified after reboot with:

```sh
cat /proc/swaps
free -h
cat /data/local/tmp/android-swap-management.log
```

The expected result is that `/data/local/tmp/swapfile` appears in `/proc/swaps` with the selected size.

## Open Questions Resolved

The module will be universal rather than OnePlus-only.

The module will drop its own zram behavior completely.

The module will leave ROM/system zram alone because zram and swapfile are separate mechanisms.

The requested install-time selection is a volume-key installer UI, not a WebUI.
