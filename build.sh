#!/bin/bash
set -e

# Install Flutter
echo "Installing Flutter..."
FLUTTER_VERSION=${FLUTTER_VERSION:-"3.24.5"}
echo "Using Flutter version: $FLUTTER_VERSION"
wget -O flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz
tar xf flutter.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# Create .env file from environment variables
echo "Creating .env file..."
echo "API_BASE_URL=${API_BASE_URL}" > .env
echo "STRIPE_PUBLISHABLE_KEY=${STRIPE_PUBLISHABLE_KEY}" >> .env
echo "ENVIRONMENT=${ENVIRONMENT}" >> .env
echo "Created .env file with:"
cat .env

# Install dependencies
echo "Installing dependencies..."
flutter pub get

# Build for web
echo "Building for web..."
flutter build web --release --web-renderer html

echo "Build completed successfully!"