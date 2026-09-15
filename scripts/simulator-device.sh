#!/bin/zsh
set -euo pipefail

command -v xcrun >/dev/null || { print -u2 "xcrun is required. Install Xcode."; exit 1; }

devices_json="$(xcrun simctl list devices available -j)"
selection="$(SONAPIN_SIMULATOR_UDID="${SONAPIN_SIMULATOR_UDID:-}" SONAPIN_SIMULATOR_NAME="${SONAPIN_SIMULATOR_NAME:-}" /usr/bin/python3 -c '
import json, os, re, sys

payload = json.load(sys.stdin)
udid_override = os.environ.get("SONAPIN_SIMULATOR_UDID")
name_override = os.environ.get("SONAPIN_SIMULATOR_NAME")
candidates = []

for runtime, devices in payload.get("devices", {}).items():
    if "SimRuntime.iOS-" not in runtime:
        continue
    version = tuple(int(part) for part in re.findall(r"iOS-([0-9-]+)$", runtime)[0].split("-"))
    for order, device in enumerate(devices):
        if device.get("isAvailable") and "iPhone" in device.get("deviceTypeIdentifier", ""):
            candidates.append((version, device.get("state") == "Booted", -order, runtime, device))

if udid_override:
    candidates = [item for item in candidates if item[4].get("udid") == udid_override]
elif name_override:
    candidates = [item for item in candidates if item[4].get("name") == name_override]

if not candidates:
    requested = udid_override or name_override
    suffix = f" matching {requested!r}" if requested else ""
    raise SystemExit(f"No available iPhone Simulator{suffix}. Install an iOS runtime in Xcode Settings > Components.")

_, _, _, runtime, device = max(candidates, key=lambda item: item[:3])
print("\t".join((device["udid"], device["name"], runtime, device.get("state", "Unknown"))))
' <<< "$devices_json")"

print -r -- "$selection"

