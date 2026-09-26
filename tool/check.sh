#!/bin/bash
# Baut und prüft das Projekt; die Ausgabe landet in build_log.txt,
# damit Claude sie lesen und Fehler beheben kann.
cd "$(dirname "$0")/.."
{
  echo "=== $(date) ==="
  flutter --version
  flutter clean
  flutter pub get
  echo "=== ANALYZE ==="
  flutter analyze
  echo "=== TEST ==="
  flutter test
  echo "=== BUILD ANDROID (debug) ==="
  flutter build apk --debug
  echo "=== BUILD iOS (no codesign) ==="
  flutter build ios --debug --no-codesign
  echo "=== FERTIG ==="
} 2>&1 | tee build_log.txt
