#!/bin/bash

# Configuration
APP_NAME="nettrack"
BUNDLE_APP_EXECUTABLE="net_track"
VERSION="1.1.0"
ARCH="amd64"
DEB_NAME="${APP_NAME}_${VERSION}_${ARCH}"

# Directories
BUILD_BUNDLE_DIR="build/linux/x64/release/bundle"
DEB_STAGE_DIR="build/linux/${DEB_NAME}"

if [ ! -d "$BUILD_BUNDLE_DIR" ]; then
    echo "Error: Release bundle not found! Please run 'flutter build linux' first."
    exit 1
fi

echo "Cleaning old packaging directories..."
rm -rf "$DEB_STAGE_DIR"
rm -f "build/linux/${DEB_NAME}.deb"

echo "Creating directory structure..."
mkdir -p "${DEB_STAGE_DIR}/DEBIAN"
mkdir -p "${DEB_STAGE_DIR}/opt/${APP_NAME}"
mkdir -p "${DEB_STAGE_DIR}/usr/share/applications"
mkdir -p "${DEB_STAGE_DIR}/usr/share/pixmaps"
mkdir -p "${DEB_STAGE_DIR}/usr/bin"

echo "Copying release bundle to /opt/${APP_NAME}..."
cp -r ${BUILD_BUNDLE_DIR}/* "${DEB_STAGE_DIR}/opt/${APP_NAME}/"

echo "Creating executable symlink in /usr/bin..."
ln -s "/opt/${APP_NAME}/${BUNDLE_APP_EXECUTABLE}" "${DEB_STAGE_DIR}/usr/bin/${APP_NAME}"

echo "Copying application icon..."
# Flutter's default linux icon is usually in the bundle or assets. We'll use assets/icon.png if it exists.
if [ -f "assets/icon.png" ]; then
    cp "assets/icon.png" "${DEB_STAGE_DIR}/usr/share/pixmaps/${APP_NAME}.png"
else
    echo "Warning: assets/icon.png not found, using a placeholder icon or skipping."
fi

echo "Generating control file..."
cat <<EOF > "${DEB_STAGE_DIR}/DEBIAN/control"
Package: ${APP_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Depends: libayatana-appindicator3-1 | libappindicator3-1, iproute2
Maintainer: Nisarg <nisarg0077@github.com>
Description: A real-time background network data usage tracker.
EOF

echo "Generating desktop shortcut file..."
cat <<EOF > "${DEB_STAGE_DIR}/usr/share/applications/${APP_NAME}.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=NetTrack
Comment=Real-Time Data Usage Tracker
Exec=/opt/${APP_NAME}/${BUNDLE_APP_EXECUTABLE}
Icon=${APP_NAME}
Terminal=false
Categories=Utility;Network;
EOF

echo "Setting permissions..."
chmod -R 755 "${DEB_STAGE_DIR}/opt/${APP_NAME}"
chmod 755 "${DEB_STAGE_DIR}/DEBIAN"

echo "Building the .deb package in /tmp to avoid NTFS permission errors..."
# Move to a native Linux filesystem (/tmp) to ensure dpkg-deb accepts the permissions
TMP_STAGE="/tmp/nettrack_deb_build"
mkdir -p "$TMP_STAGE"
rm -rf "$TMP_STAGE"/*
cp -r "$DEB_STAGE_DIR" "$TMP_STAGE/"
chmod -R 755 "$TMP_STAGE/${DEB_NAME}"

dpkg-deb --build "$TMP_STAGE/${DEB_NAME}" "build/linux/"

echo "Cleaning up..."
rm -rf "$TMP_STAGE"

echo "Success! The installer is located at: build/linux/${DEB_NAME}.deb"
