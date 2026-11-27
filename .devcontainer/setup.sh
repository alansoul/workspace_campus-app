#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR="/usr/local/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Installing Flutter SDK (stable)..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq curl git unzip xz-utils zip libglu1-mesa >/dev/null
  sudo git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
  sudo chown -R "$(id -u):$(id -g)" "$FLUTTER_DIR"
fi

if ! grep -q "$FLUTTER_DIR/bin" "$HOME/.bashrc" 2>/dev/null; then
  echo "export PATH=\"$FLUTTER_DIR/bin:\$PATH\"" >> "$HOME/.bashrc"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter config --enable-web
flutter precache --web
flutter pub get

echo ""
echo "Ready! Run live preview (works on Laptop Chrome/Edge AND Mobile browser):"
echo "  flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080"
