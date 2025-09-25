#!/bin/bash
set -e

# Install Flutter
echo "Installing Flutter..."
FLUTTER_VERSION=${FLUTTER_VERSION:-"3.24.5"}
echo "Using Flutter version: $FLUTTER_VERSION"
wget -O flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
tar xf flutter.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# Note: Environment variables are handled directly by Flutter web
# No need to create .env file as we use environment variables directly
echo "Using environment variables:"
echo "API_BASE_URL=${API_BASE_URL}"
echo "STRIPE_PUBLISHABLE_KEY=${STRIPE_PUBLISHABLE_KEY}"
echo "ENVIRONMENT=${ENVIRONMENT}"

# Install dependencies
echo "Installing dependencies..."
flutter pub get

# Build for web
echo "Building for web..."
flutter build web --release --web-renderer html \
  --dart-define=API_BASE_URL="${API_BASE_URL}" \
  --dart-define=STRIPE_PUBLISHABLE_KEY="${STRIPE_PUBLISHABLE_KEY}" \
  --dart-define=ENVIRONMENT="${ENVIRONMENT}"

echo "Build completed successfully!"