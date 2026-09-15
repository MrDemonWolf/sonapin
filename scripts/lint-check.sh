#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
native_dir="$repo_root/apps/native"

forbidden='@unchecked[[:space:]]+Sendable|nonisolated\(unsafe\)|@preconcurrency|Task\.detached|DispatchSemaphore'
if rg -n "$forbidden" "$native_dir/SonaPin" "$native_dir/SonaPinTests" "$native_dir/SonaPinUITests"; then
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
