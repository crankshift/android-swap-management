#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MODDIR="$ROOT/android-swap-management"
WORKFLOW="$ROOT/.github/workflows/release.yml"
OLD_MODDIR="$ROOT/oneplus15-zram-8gb"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_file() {
  [ -f "$1" ] || fail "missing file: $1"
}

assert_not_path() {
  [ ! -e "$1" ] || fail "old path remains: $1"
}

assert_executable() {
  [ -x "$1" ] || fail "file is not executable: $1"
}

assert_contains() {
  file=$1
  pattern=$2
  grep -Fq -- "$pattern" "$file" || fail "$file does not contain: $pattern"
}

assert_not_contains() {
  file=$1
  pattern=$2
  if grep -Fq -- "$pattern" "$file"; then
    fail "$file still contains: $pattern"
  fi
}

assert_file "$ROOT/.gitignore"
assert_file "$ROOT/LICENSE"
assert_file "$ROOT/README.md"
assert_file "$ROOT/CONTRIBUTING.md"
assert_file "$ROOT/SECURITY.md"
assert_file "$ROOT/AGENTS.md"
assert_file "$ROOT/scripts/build.sh"
assert_executable "$ROOT/scripts/build.sh"
assert_file "$WORKFLOW"

assert_contains "$ROOT/.gitignore" "docs/superpowers/"
assert_contains "$ROOT/LICENSE" "MIT License"
assert_contains "$ROOT/README.md" "Android Swap Management"
assert_contains "$ROOT/README.md" "/data/local/tmp/swapfile"
assert_contains "$ROOT/README.md" "./scripts/build.sh"
assert_contains "$ROOT/CONTRIBUTING.md" "./tests/validate_module.sh"
assert_contains "$ROOT/CONTRIBUTING.md" "swapfile"
assert_contains "$ROOT/SECURITY.md" "security vulnerability"
assert_contains "$ROOT/AGENTS.md" "Android Swap Management"
assert_contains "$ROOT/AGENTS.md" "Do not reintroduce zram management"
assert_contains "$ROOT/AGENTS.md" "./tests/validate_module.sh"
assert_contains "$ROOT/scripts/build.sh" 'android-swap-management-$VERSION.zip'
assert_contains "$WORKFLOW" "tags:"
assert_contains "$WORKFLOW" "'v*'"
assert_contains "$WORKFLOW" "./scripts/build.sh"
assert_contains "$WORKFLOW" "./tests/validate_module.sh"
assert_contains "$WORKFLOW" "gh release"
assert_contains "$WORKFLOW" "--clobber"
assert_contains "$WORKFLOW" "android-swap-management-*.zip"
assert_not_contains "$WORKFLOW" "oneplus15-zram-8gb-*.zip"
assert_not_path "$OLD_MODDIR"

assert_file "$MODDIR/module.prop"
VERSION=$(awk -F= '$1 == "version" { print $2; exit }' "$MODDIR/module.prop")
[ -n "$VERSION" ] || fail "missing version in module.prop"
ZIP="$ROOT/dist/android-swap-management-$VERSION.zip"

assert_file "$MODDIR/skip_mount"
assert_file "$MODDIR/service.sh"
assert_file "$MODDIR/uninstall.sh"
assert_file "$MODDIR/customize.sh"
assert_file "$MODDIR/README.md"
assert_file "$MODDIR/META-INF/com/google/android/update-binary"
assert_file "$MODDIR/META-INF/com/google/android/updater-script"

assert_contains "$MODDIR/module.prop" "id=android-swap-management"
assert_contains "$MODDIR/module.prop" "name=Android Swap Management"
assert_contains "$MODDIR/module.prop" "author=crankshift"
assert_contains "$MODDIR/module.prop" "version=v1.0"
assert_contains "$MODDIR/module.prop" "description=Creates and enables a configurable swapfile"

assert_contains "$MODDIR/service.sh" "SWAPFILE=/data/local/tmp/swapfile"
assert_contains "$MODDIR/service.sh" 'CONF=$MODDIR/swap_size.conf'
assert_contains "$MODDIR/service.sh" "DEFAULT_SIZE_BYTES=8589934592"
assert_contains "$MODDIR/service.sh" "SIZE_16_BYTES=17179869184"
assert_contains "$MODDIR/service.sh" "reusable_kib"
assert_contains "$MODDIR/service.sh" 'available_kib=$(( free_kib + reusable_kib ))'
assert_contains "$MODDIR/service.sh" 'ensure_space "$size_bytes" "$current_size"'
assert_contains "$MODDIR/service.sh" "could not parse free space for /data; skipping swapfile creation"
assert_not_contains "$MODDIR/service.sh" "could not parse free space for /data; continuing"
assert_contains "$MODDIR/service.sh" "dd if=/dev/zero"
assert_contains "$MODDIR/service.sh" 'mkswap "$SWAPFILE"'
assert_contains "$MODDIR/service.sh" 'swapon -p "$SWAP_PRIORITY" "$SWAPFILE"'
assert_contains "$MODDIR/service.sh" "/data/local/tmp/android-swap-management.log"
assert_not_contains "$MODDIR/service.sh" "/sys/block/zram0"
assert_not_contains "$MODDIR/service.sh" "/dev/zram0"
assert_not_contains "$MODDIR/service.sh" "ZRAM_SYS"

assert_contains "$MODDIR/uninstall.sh" "SWAPFILE=/data/local/tmp/swapfile"
assert_contains "$MODDIR/uninstall.sh" 'swapoff "$SWAPFILE"'
assert_contains "$MODDIR/uninstall.sh" 'rm -f "$SWAPFILE"'
assert_contains "$MODDIR/uninstall.sh" "/data/local/tmp/android-swap-management.log"

assert_contains "$MODDIR/META-INF/com/google/android/update-binary" "MODID=android-swap-management"
assert_contains "$MODDIR/META-INF/com/google/android/update-binary" "SIZE_8_BYTES=8589934592"
assert_contains "$MODDIR/META-INF/com/google/android/update-binary" "SIZE_16_BYTES=17179869184"
assert_contains "$MODDIR/META-INF/com/google/android/update-binary" "KEY_VOLUMEUP"
assert_contains "$MODDIR/META-INF/com/google/android/update-binary" "KEY_VOLUMEDOWN"
assert_contains "$MODDIR/META-INF/com/google/android/update-binary" "swap_size.conf"
assert_contains "$MODDIR/META-INF/com/google/android/update-binary" "Selected swapfile size"
assert_not_contains "$MODDIR/META-INF/com/google/android/update-binary" "ZRAM"

assert_contains "$MODDIR/customize.sh" "Android Swap Management"
assert_contains "$MODDIR/customize.sh" "Press Volume Up for 8 GiB"
assert_contains "$MODDIR/customize.sh" "Press Volume Down for 16 GiB"
assert_contains "$MODDIR/customize.sh" "KEY_VOLUMEUP"
assert_contains "$MODDIR/customize.sh" "KEY_VOLUMEDOWN"
assert_contains "$MODDIR/customize.sh" "swap_size.conf"
assert_contains "$MODDIR/customize.sh" "Selected swapfile size"
assert_not_contains "$MODDIR/customize.sh" "ZRAM"

assert_contains "$MODDIR/README.md" "Android Swap Management"
assert_contains "$MODDIR/README.md" "/data/local/tmp/swapfile"
assert_contains "$MODDIR/README.md" "cat /proc/swaps"

sh -n "$ROOT/scripts/build.sh"
sh -n "$MODDIR/service.sh"
sh -n "$MODDIR/uninstall.sh"
sh -n "$MODDIR/customize.sh"
sh -n "$MODDIR/META-INF/com/google/android/update-binary"

assert_file "$ZIP"
unzip -l "$ZIP" | grep -Fq "module.prop" || fail "zip missing module.prop"
unzip -l "$ZIP" | grep -Fq "service.sh" || fail "zip missing service.sh"
unzip -l "$ZIP" | grep -Fq "uninstall.sh" || fail "zip missing uninstall.sh"
unzip -l "$ZIP" | grep -Fq "customize.sh" || fail "zip missing customize.sh"
unzip -l "$ZIP" | grep -Fq "README.md" || fail "zip missing README.md"
unzip -l "$ZIP" | grep -Fq "META-INF/com/google/android/update-binary" || fail "zip missing update-binary"

if unzip -l "$ZIP" | grep -Fq "android-swap-management/module.prop"; then
  fail "zip must contain module.prop at archive root, not inside android-swap-management/"
fi

printf 'PASS: module validation succeeded\n'
