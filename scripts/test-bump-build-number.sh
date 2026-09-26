#!/bin/zsh
set -euo pipefail

repo="${0:A:h:h}"
temp="$(mktemp -d)"
trap 'rm -rf "$temp"' EXIT

mkdir -p "$temp/scripts" "$temp/apps/native"
cp "$repo/scripts/bump-build-number.sh" "$temp/scripts/"
print 'CURRENT_PROJECT_VERSION = 21' > "$temp/apps/native/BuildNumber.xcconfig"

CONFIGURATION=Debug "$temp/scripts/bump-build-number.sh"
[[ "$(<"$temp/apps/native/BuildNumber.xcconfig")" == 'CURRENT_PROJECT_VERSION = 21' ]]

CONFIGURATION=Release "$temp/scripts/bump-build-number.sh"
[[ "$(<"$temp/apps/native/BuildNumber.xcconfig")" == 'CURRENT_PROJECT_VERSION = 22' ]]

print 'Build number configuration check passed'
