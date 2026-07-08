# Agent Guidance

This repository builds Android Swap Management, a Magisk/KernelSU module.

Runtime module files live in `android-swap-management/`.

The module manages only `/data/local/tmp/swapfile`.

Do not reintroduce zram management or touch ROM/system zram behavior.

Before claiming changes are complete, run:

```sh
./scripts/build.sh
./tests/validate_module.sh
```
