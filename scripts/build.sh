#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MODDIR="$ROOT/oneplus15-zram-8gb"
PROP="$MODDIR/module.prop"
DIST="$ROOT/dist"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

command -v zip >/dev/null 2>&1 || fail "zip command not found"
[ -f "$PROP" ] || fail "missing module.prop: $PROP"

VERSION=$(awk -F= '$1 == "version" { print $2; exit }' "$PROP")
[ -n "$VERSION" ] || fail "missing version in module.prop"

OUT="$DIST/oneplus15-zram-8gb-$VERSION.zip"

mkdir -p "$DIST"
rm -f "$OUT"

(
  cd "$MODDIR"
  zip -qr "$OUT" . \
    -x '.DS_Store' \
    -x '__MACOSX/*'
)

printf 'Built %s\n' "$OUT"
