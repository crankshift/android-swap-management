# Contributing

Contributions are welcome when they keep the module small, reviewable, and focused on the OnePlus 15 ZRAM configuration.

## Before Opening a Pull Request

Run:

```sh
./scripts/build.sh
./tests/validate_module.sh
```

The validation script checks the module source, repository metadata, release workflow, and generated ZIP contents.

## Guidelines

- Keep runtime changes in `oneplus15-zram-8gb/` minimal and easy to audit.
- Do not change the target zram size, compression preference, or swappiness without explaining the reason.
- Update `oneplus15-zram-8gb/module.prop` when preparing a versioned release.
- Update `README.md` when behavior or user instructions change.
- Do not commit generated ZIP files; use `./scripts/build.sh` to create local artifacts under `dist/`.
