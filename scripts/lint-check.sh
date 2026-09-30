#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
native_dir="$repo_root/apps/native"

"$repo_root/scripts/test-bump-build-number.sh"

forbidden='@unchecked[[:space:]]+Sendable|nonisolated\(unsafe\)|@preconcurrency|Task\.detached|DispatchSemaphore'
if rg -n "$forbidden" "$native_dir/SonaPin" "$native_dir/SonaPinTests" "$native_dir/SonaPinUITests" \
  | rg -v '/QRCodeView.swift:[0-9]+:.*Task\.detached\(priority: \.userInitiated\).*concurrency-reviewed: Core Image rendering stays off the main actor\.$'; then
  print -u2 "Forbidden concurrency escape found. Document and narrow it before use."
  exit 1
fi

xcodebuild \
  -project "$native_dir/SonaPin.xcodeproj" \
  -scheme SonaPin \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$native_dir/.derived-data" \
  CODE_SIGNING_ALLOWED=NO \
  build
