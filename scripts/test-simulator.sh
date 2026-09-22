#!/bin/zsh
set -euo pipefail

mode="${1:-all}"
case "$mode" in
  unit) only_testing="-only-testing:SonaPinTests"; result_name="unit-tests" ;;
  ui) only_testing="-only-testing:SonaPinUITests"; result_name="ui-tests" ;;
  all) only_testing=""; result_name="all-tests" ;;
  *) print -u2 "Usage: $0 [unit|ui|all]"; exit 64 ;;
esac

repo_root="${0:A:h:h}"
native_dir="$repo_root/apps/native"
artifacts_dir="$repo_root/artifacts"
derived_data="$native_dir/.derived-data"
mkdir -p "$artifacts_dir"

command -v xcodebuild >/dev/null || { print -u2 "xcodebuild is required. Install Xcode."; exit 1; }
IFS=$'\t' read -r simulator_udid simulator_name runtime_id simulator_state <<< "$($repo_root/scripts/simulator-device.sh)"

if [[ "$simulator_state" != "Booted" ]]; then
  xcrun simctl boot "$simulator_udid"
fi
xcrun simctl bootstatus "$simulator_udid" -b

make -C "$repo_root" bump-build resolve
result_bundle="$artifacts_dir/$result_name.xcresult"
[[ ! -e "$result_bundle" ]] || rm -rf "$result_bundle"

build_command=(
  xcodebuild
  -project "$native_dir/SonaPin.xcodeproj"
  -scheme SonaPin
  -configuration Debug
  -destination "platform=iOS Simulator,id=$simulator_udid"
  -derivedDataPath "$derived_data"
  -resultBundlePath "$result_bundle"
  -parallel-testing-enabled NO
  CODE_SIGNING_ALLOWED=NO
  test
)
if [[ -n "$only_testing" ]]; then
  build_command+=("$only_testing")
fi

print -r -- "Simulator: $simulator_name ($runtime_id, $simulator_udid)" | tee "$artifacts_dir/$result_name.log"
"${build_command[@]}" 2>&1 | tee -a "$artifacts_dir/$result_name.log"
