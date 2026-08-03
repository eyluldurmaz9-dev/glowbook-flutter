#!/usr/bin/env bash
set -euo pipefail

FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"

if [ -z "${API_BASE_URL:-}" ]; then
  echo "ERROR: API_BASE_URL is required for production web builds."
  echo "Set it in Vercel Project Settings > Environment Variables."
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK not found. Installing Flutter ${FLUTTER_CHANNEL} into ${FLUTTER_HOME}..."
  git clone --depth 1 --branch "${FLUTTER_CHANNEL}" https://github.com/flutter/flutter.git "${FLUTTER_HOME}"
  export PATH="${FLUTTER_HOME}/bin:${PATH}"
else
  echo "Using Flutter SDK from $(command -v flutter)"
fi

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release --pwa-strategy=none --dart-define=API_BASE_URL="${API_BASE_URL}" --base-href=/
