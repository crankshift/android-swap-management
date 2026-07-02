#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MODDIR="$ROOT/oneplus15-zram-8gb"
VERSION=$(awk -F= '$1 == "version" { print $2; exit }' "$MODDIR/module.prop")
ZIP="$ROOT/dist/oneplus15-zram-8gb-$VERSION.zip"
WORKFLOW="$ROOT/.github/workflows/release.yml"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_file() {
  [ -f "$1" ] || fail "missing file: $1"
}

assert_executable() {
  [ -x "$1" ] || fail "file is not executable: $1"
}

assert_contains() {
  file=$1
  pattern=$2
  grep -Fq -- "$pattern" "$file" || fail "$file does not contain: $pattern"
}

assert_file "$ROOT/.gitignore"
assert_file "$ROOT/LICENSE"
assert_file "$ROOT/README.md"
assert_file "$ROOT/CONTRIBUTING.md"
assert_file "$ROOT/SECURITY.md"
assert_file "$ROOT/scripts/build.sh"
assert_executable "$ROOT/scripts/build.sh"
assert_file "$WORKFLOW"

assert_contains "$ROOT/.gitignore" "docs/superpowers/"
assert_contains "$ROOT/LICENSE" "MIT License"
assert_contains "$ROOT/README.md" "OnePlus 15 ZRAM 8GB"
assert_contains "$ROOT/README.md" "./scripts/build.sh"
assert_contains "$ROOT/CONTRIBUTING.md" "./tests/validate_module.sh"
assert_contains "$ROOT/SECURITY.md" "security vulnerability"
assert_contains "$ROOT/scripts/build.sh" 'oneplus15-zram-8gb-$VERSION.zip'
assert_contains "$WORKFLOW" "tags:"
assert_contains "$WORKFLOW" "'v*'"
assert_contains "$WORKFLOW" "./scripts/build.sh"
assert_contains "$WORKFLOW" "./tests/validate_module.sh"
assert_contains "$WORKFLOW" "gh release"
assert_contains "$WORKFLOW" "--clobber"

assert_file "$MODDIR/module.prop"
assert_file "$MODDIR/skip_mount"
assert_file "$MODDIR/service.sh"
assert_file "$MODDIR/uninstall.sh"
assert_file "$MODDIR/README.md"
assert_file "$MODDIR/META-INF/com/google/android/update-binary"
assert_file "$MODDIR/META-INF/com/google/android/updater-script"

assert_contains "$MODDIR/module.prop" "id=oneplus15-zram-8gb"
assert_contains "$MODDIR/module.prop" "author=crankshift"
assert_contains "$MODDIR/module.prop" "version=v1.0"
assert_contains "$MODDIR/service.sh" "SIZE_BYTES=8589934592"
assert_contains "$MODDIR/service.sh" "SWAPPINESS=100"
assert_contains "$MODDIR/service.sh" "grep -qw lz4"
assert_contains "$MODDIR/service.sh" "swapon -p 32767"
assert_contains "$MODDIR/service.sh" "/data/local/tmp/oneplus15-zram-8gb.log"
assert_contains "$MODDIR/META-INF/com/google/android/update-binary" "MODID=oneplus15-zram-8gb"
assert_contains "$MODDIR/META-INF/com/google/android/update-binary" "Author: crankshift"
assert_contains "$MODDIR/README.md" "cat /proc/swaps"

sh -n "$ROOT/scripts/build.sh"
sh -n "$MODDIR/service.sh"
sh -n "$MODDIR/uninstall.sh"
sh -n "$MODDIR/META-INF/com/google/android/update-binary"

assert_file "$ZIP"
unzip -l "$ZIP" | grep -Fq "module.prop" || fail "zip missing module.prop"
unzip -l "$ZIP" | grep -Fq "service.sh" || fail "zip missing service.sh"
unzip -l "$ZIP" | grep -Fq "uninstall.sh" || fail "zip missing uninstall.sh"
unzip -l "$ZIP" | grep -Fq "README.md" || fail "zip missing README.md"
unzip -l "$ZIP" | grep -Fq "META-INF/com/google/android/update-binary" || fail "zip missing update-binary"

if unzip -l "$ZIP" | grep -Fq "oneplus15-zram-8gb/module.prop"; then
  fail "zip must contain module.prop at archive root, not inside oneplus15-zram-8gb/"
fi

printf 'PASS: module validation succeeded\n'
