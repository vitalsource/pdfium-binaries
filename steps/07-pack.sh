#!/bin/bash -eux

IS_DEBUG=${PDFium_IS_DEBUG:-false}
ENABLE_V8=${PDFium_ENABLE_V8:-false}
OS=${PDFium_TARGET_OS:?}
TARGET_LIBC=${PDFium_TARGET_LIBC:-default}
CPU=${PDFium_TARGET_CPU:?}
VERSION=${PDFium_VERSION:-}
PATCHES="$PWD/patches"

SOURCE=${PDFium_SOURCE_DIR:-pdfium}
BUILD=${PDFium_BUILD_DIR:-pdfium/out}

STAGING="$PWD/staging"
STAGING_BIN="$STAGING/bin"
STAGING_LIB="$STAGING/lib"
STAGING_RES="$STAGING/res"

mkdir -p "$STAGING"
mkdir -p "$STAGING_LIB"

sed "s/#VERSION#/${VERSION:-0.0.0.0}/" <"$PATCHES/PDFiumConfig.cmake" >"$STAGING/PDFiumConfig.cmake"

cp "$SOURCE/LICENSE" "$STAGING"
cp "$BUILD/args.gn" "$STAGING"
cp -R "$SOURCE/public" "$STAGING/include"
rm -f "$STAGING/include/DEPS"
rm -f "$STAGING/include/README"
rm -f "$STAGING/include/PRESUBMIT.py"

case "$OS" in
  android|linux)
    mv "$BUILD/libpdfium.a" "$STAGING_LIB"
    ;;

  mac|ios)
    mv "$BUILD/libpdfium.a" "$STAGING_LIB"
    ;;

  wasm)
    mv "$BUILD/pdfium.html" "$STAGING_LIB"
    mv "$BUILD/pdfium.js" "$STAGING_LIB"
    mv "$BUILD/pdfium.wasm" "$STAGING_LIB"
    rm -rf "$STAGING/include/cpp"
    rm "$STAGING/PDFiumConfig.cmake"
    ;;

  win)
    mv "$BUILD/pdfium.dll.lib" "$STAGING_LIB"
    mkdir -p "$STAGING_BIN"
    mv "$BUILD/pdfium.dll" "$STAGING_BIN"
    [ "$IS_DEBUG" == "true" ] && mv "$BUILD/pdfium.dll.pdb" "$STAGING_BIN"
    ;;
esac

if [ "$ENABLE_V8" == "true" ]; then
  mkdir -p "$STAGING_RES"
  mv "$BUILD/icudtl.dat" "$STAGING_RES"
  mv "$BUILD/snapshot_blob.bin" "$STAGING_RES"
fi

[ -n "$VERSION" ] && cat >"$STAGING/VERSION" <<END
MAJOR=$(echo "$VERSION" | cut -d. -f1)
MINOR=$(echo "$VERSION" | cut -d. -f2)
BUILD=$(echo "$VERSION" | cut -d. -f3)
PATCH=$(echo "$VERSION" | cut -d. -f4)
END

ARTIFACT_BASE="$PWD/pdfium-$OS"
[ "$TARGET_LIBC" != "default" ] && ARTIFACT_BASE="$ARTIFACT_BASE-$TARGET_LIBC"
[ "$OS" != "$CPU" ] && ARTIFACT_BASE="$ARTIFACT_BASE-$CPU"
[ "$ENABLE_V8" == "true" ] && ARTIFACT_BASE="$ARTIFACT_BASE-v8"
[ "$IS_DEBUG" == "true" ] && ARTIFACT_BASE="$ARTIFACT_BASE-debug"
ARTIFACT="$ARTIFACT_BASE.tgz"

pushd "$STAGING"
tar cvzf "$ARTIFACT" -- *
popd