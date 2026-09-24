#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
native_dir="$repo_root/apps/native"
artifacts_dir="$repo_root/artifacts"
derived_data="$native_dir/.derived-data"
bundle_id="com.mrdemonwolf.sonapin.dev"
mkdir -p "$artifacts_dir"

command -v xcodebuild >/dev/null || { print -u2 "xcodebuild is required. Install Xcode."; exit 1; }
command -v xcrun >/dev/null || { print -u2 "xcrun is required. Install Xcode."; exit 1; }

IFS=$'\t' read -r simulator_udid simulator_name runtime_id simulator_state <<< "$($repo_root/scripts/simulator-device.sh)"
if [[ "$simulator_state" != "Booted" ]]; then
  xcrun simctl boot "$simulator_udid"
fi
xcrun simctl bootstatus "$simulator_udid" -b

make -C "$repo_root" project resolve

build_command=(
  xcodebuild
  -project "$native_dir/SonaPin.xcodeproj"
  -scheme SonaPin
  -configuration Debug
  -destination "platform=iOS Simulator,id=$simulator_udid"
  -derivedDataPath "$derived_data"
  CODE_SIGNING_ALLOWED=NO
  build
)
"${build_command[@]}" 2>&1 | tee "$artifacts_dir/simulator-build.log"

app_path="$derived_data/Build/Products/Debug-iphonesimulator/SonaPin.app"
[[ -d "$app_path" ]] || { print -u2 "Built app not found at $app_path"; exit 1; }

xcrun simctl install "$simulator_udid" "$app_path"
xcrun simctl terminate "$simulator_udid" "$bundle_id" >/dev/null 2>&1 || true
launch_result="$(xcrun simctl launch "$simulator_udid" "$bundle_id" --ui-testing --reset-app-state --use-demo-avatar)"
sleep 3
xcrun simctl io "$simulator_udid" screenshot "$artifacts_dir/simulator-home.png"
xcrun simctl spawn "$simulator_udid" log show --last 2m --style compact --predicate 'process == "SonaPin"' > "$artifacts_dir/simulator.log"

{
  print "timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  print "xcode: $(xcodebuild -version | tr '\n' ' ')"
  print "runtime: $runtime_id"
  print "device: $simulator_name"
  print "udid: $simulator_udid"
  print "build-command: ${(q-)build_command}"
  print "app-path: $app_path"
  print "install-result: success"
  print "launch-result: $launch_result"
  print "screenshot: $artifacts_dir/simulator-home.png"
} > "$artifacts_dir/simulator-run.txt"

open -a Simulator --args -CurrentDeviceUDID "$simulator_udid" >/dev/null 2>&1 || true
print -r -- "$launch_result"
print -r -- "Screenshot: $artifacts_dir/simulator-home.png"
