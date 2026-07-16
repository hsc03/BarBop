#!/bin/sh

set -eu

if [ "$#" -ne 2 ]; then
    echo "Usage: SPARKLE_BIN_DIR=/path/to/Sparkle/bin $0 VERSION ARCHIVES_DIR" >&2
    exit 1
fi

: "${SPARKLE_BIN_DIR:?Set SPARKLE_BIN_DIR to the Sparkle bin directory}"

VERSION="$1"
ARCHIVES_DIR="$2"
GENERATE_APPCAST="${SPARKLE_BIN_DIR}/generate_appcast"
ARCHIVE_PATH="${ARCHIVES_DIR}/BarBop.zip"
APPCAST_PATH="${ARCHIVES_DIR}/appcast.xml"

if [ ! -x "${GENERATE_APPCAST}" ]; then
    echo "generate_appcast was not found: ${GENERATE_APPCAST}" >&2
    exit 1
fi

if [ ! -f "${ARCHIVE_PATH}" ]; then
    echo "Expected notarized update archive: ${ARCHIVE_PATH}" >&2
    exit 1
fi

"${GENERATE_APPCAST}" \
    --account io.github.hsc03.BarBop \
    --download-url-prefix "https://github.com/hsc03/BarBop/releases/download/v${VERSION}/" \
    --link "https://github.com/hsc03/BarBop" \
    --maximum-versions 3 \
    -o "${APPCAST_PATH}" \
    "${ARCHIVES_DIR}"

echo "Generated signed appcast: ${APPCAST_PATH}"
