#!/bin/bash
set -e

# Install Flutter
echo "Installing Flutter..."
wget -O flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz
tar xf flutter.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# Install dependencies
echo "Installing dependencies..."
flutter pub get

# Build for web
echo "Building for web..."
flutter build web --release --web-renderer html

echo "Build completed successfully!"