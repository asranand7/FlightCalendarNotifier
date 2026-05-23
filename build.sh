#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

APP_NAME="Flyby"
BUILD_DIR="build"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"

echo "🧹 Cleaning previous builds..."
rm -rf "$BUILD_DIR"

echo "📂 Creating bundle directory structure..."
mkdir -p "$MACOS_DIR"

echo "🚀 Compiling Swift application..."
swiftc \
  src/main.swift \
  src/AppDelegate.swift \
  src/CalendarManager.swift \
  src/SettingsManager.swift \
  src/TodoistManager.swift \
  src/FlightOverlayPanel.swift \
  src/FlightAnimationView.swift \
  src/SetupView.swift \
  -o "${MACOS_DIR}/${APP_NAME}" \
  -sdk "$(xcrun --show-sdk-path)" \
  -O

echo "📄 Copying Info.plist and Resources..."
cp Info.plist "${CONTENTS_DIR}/Info.plist"

RESOURCES_DIR="${CONTENTS_DIR}/Resources"
mkdir -p "$RESOURCES_DIR"
cp fetch_calendar.py "${RESOURCES_DIR}/"
chmod +x "${RESOURCES_DIR}/fetch_calendar.py"
if [ -f AppIcon.icns ]; then
  cp AppIcon.icns "${RESOURCES_DIR}/"
fi

# Copy theme image assets
for f in assets/*.png; do
  [ -f "$f" ] && cp "$f" "${RESOURCES_DIR}/"
done

echo "🔏 Performing ad-hoc code signing..."
codesign --force --deep --sign - "${APP_DIR}"

echo "✅ Success! Built ${APP_DIR} successfully."

# Optional install step: ./build.sh install  → copies the app into /Applications
if [ "$1" == "install" ]; then
  echo "📦 Installing to /Applications/${APP_NAME}.app ..."
  # Quit any running instance so the bundle can be replaced cleanly
  pkill -x "${APP_NAME}" 2>/dev/null || true
  rm -rf "/Applications/${APP_NAME}.app"
  cp -R "$APP_DIR" "/Applications/"
  echo "✅ Installed. Launching..."
  open "/Applications/${APP_NAME}.app"
else
  echo "You can launch the app by double-clicking it in Finder or running:"
  echo "open ${APP_DIR}"
  echo "Or install it permanently with: ./build.sh install"
fi
