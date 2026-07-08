# Contributing

Thanks for helping improve Android Swap Management.

## Development

- Keep runtime changes in `android-swap-management/` minimal and easy to audit.
- The module manages only `/data/local/tmp/swapfile`.
- Do not reintroduce zram management or change ROM/system zram behavior.
- Update `android-swap-management/module.prop` when preparing a versioned release.
- Keep `README.md` and `android-swap-management/README.md` aligned with behavior changes.

## Validate

Run the local validation command before opening a pull request:

```sh
./scripts/build.sh
./tests/validate_module.sh
```

The validation script checks required repository files, module metadata, shell syntax, and generated ZIP structure.

## Pull Requests

- Explain the behavior change and why it is needed.
- Include validation output in the pull request description.
- Avoid unrelated formatting churn.
