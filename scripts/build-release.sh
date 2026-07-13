#!/bin/sh

set -eu

SCHEME="${SCHEME:-BarBop}"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/BarBopReleaseDerivedData}"
RELEASE_ROOT="${RELEASE_ROOT:-build/release}"
APP_NAME="${APP_NAME:-BarBop}"

APP_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"
ZIP_PATH="${RELEASE_ROOT}/${APP_NAME}.zip"
CHECKSUM_PATH="${ZIP_PATH}.sha256"

mkdir -p "${RELEASE_ROOT}"

xcodebuild \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -destination "platform=macOS" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    build

if [ ! -d "${APP_PATH}" ]; then
    echo "Expected app bundle was not found: ${APP_PATH}" >&2
    exit 1
fi

rm -f "${ZIP_PATH}" "${CHECKSUM_PATH}"
/usr/bin/ditto -c -k --keepParent "${APP_PATH}" "${ZIP_PATH}"
/usr/bin/shasum -a 256 "${ZIP_PATH}" > "${CHECKSUM_PATH}"

echo "Release artifact: ${ZIP_PATH}"
echo "Checksum: ${CHECKSUM_PATH}"
