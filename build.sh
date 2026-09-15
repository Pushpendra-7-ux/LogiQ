#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_DIR="$ROOT_DIR/logiq"
BACKEND_DIR="$ROOT_DIR/backend"

TARGET="${1:-apk-debug}"

usage() {
    echo "============================================================"
    echo "              LogiQ Build Automation Script"
    echo "============================================================"
    echo "Usage: $0 [apk-debug|apk-release|web|backend|clean|all]"
    echo ""
    echo "Targets:"
    echo "  apk-debug    Build Android Debug APK (default)"
    echo "  apk-release  Build Android Release APK"
    echo "  web          Build Flutter Web production bundle"
    echo "  backend      Verify backend dependencies and run tests"
    echo "  clean        Clean Flutter and Python cache"
    echo "  all          Build Web, Debug APK, and verify backend"
    echo "============================================================"
    exit 1
}

clean_all() {
    echo ">>> Cleaning Flutter build cache..."
    cd "$FLUTTER_DIR" && flutter clean
    echo ">>> Cleaning Python cache..."
    cd "$BACKEND_DIR" && find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    echo ">>> Clean completed."
}

build_apk_debug() {
    echo ">>> Building Flutter Android Debug APK..."
    cd "$FLUTTER_DIR"
    flutter pub get
    flutter build apk --debug
    echo ">>> Debug APK generated at:"
    echo "    $FLUTTER_DIR/build/app/outputs/flutter-apk/app-debug.apk"
}

build_apk_release() {
    echo ">>> Building Flutter Android Release APK..."
    cd "$FLUTTER_DIR"
    flutter pub get
    flutter build apk --release
    echo ">>> Release APK generated at:"
    echo "    $FLUTTER_DIR/build/app/outputs/flutter-apk/app-release.apk"
}

build_web() {
    echo ">>> Building Flutter Web bundle..."
    cd "$FLUTTER_DIR"
    flutter pub get
    flutter build web
    echo ">>> Web bundle generated at:"
    echo "    $FLUTTER_DIR/build/web"
}

build_backend() {
    echo ">>> Verifying backend..."
    cd "$BACKEND_DIR"
    /Library/Frameworks/Python.framework/Versions/3.14/bin/python3 -m pip install -r requirements.txt
    /Library/Frameworks/Python.framework/Versions/3.14/bin/python3 /Users/pushpendrasuryawanshi/.gemini/antigravity/brain/3c0a0b32-1159-49bc-b7d4-95577e40e58a/scratch/verify_e2e.py
    echo ">>> Backend verified successfully."
}

case "$TARGET" in
    apk-debug)
        build_apk_debug
        ;;
    apk-release)
        build_apk_release
        ;;
    web)
        build_web
        ;;
    backend)
        build_backend
        ;;
    clean)
        clean_all
        ;;
    all)
        build_web
        build_apk_debug
        build_backend
        ;;
    *)
        usage
        ;;
esac

echo ""
echo "============================================================"
echo "          LogiQ Build Finished Successfully!"
echo "============================================================"
