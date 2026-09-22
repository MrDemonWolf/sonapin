#!/bin/zsh
set -euo pipefail

spec="${0:A:h:h}/apps/native/project.yml"
current="$(sed -nE 's/^        CURRENT_PROJECT_VERSION: "([0-9]+)"$/\1/p' "$spec")"
[[ "$current" == <-> ]] || { print -u2 "Expected one numeric CURRENT_PROJECT_VERSION in $spec"; exit 1; }

next=$((current + 1))
temp="$(mktemp "${spec}.XXXXXX")"
trap 'rm -f "$temp"' EXIT
sed -E "s/^(        CURRENT_PROJECT_VERSION: \")[0-9]+(\")$/\1${next}\2/" "$spec" > "$temp"
chmod 644 "$temp"
mv "$temp" "$spec"
print "SonaPin build $next"
