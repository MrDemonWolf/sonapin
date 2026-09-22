NATIVE_DIR := apps/native
PROJECT := $(NATIVE_DIR)/SonaPin.xcodeproj
SCHEME := SonaPin
DERIVED_DATA := $(NATIVE_DIR)/.derived-data
ARCHIVE_PATH := artifacts/release/SonaPin.xcarchive
EXPORT_PATH := artifacts/release/export

.PHONY: project resolve bump-build build test ui-test sim archive export clean lint-check docs-build

project:
	cd $(NATIVE_DIR) && xcodegen generate

resolve: project
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -resolvePackageDependencies

bump-build:
	./scripts/bump-build-number.sh

build: bump-build
	$(MAKE) resolve
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath $(DERIVED_DATA) CODE_SIGNING_ALLOWED=NO build

test:
	./scripts/test-simulator.sh unit

ui-test:
	./scripts/test-simulator.sh ui

sim:
	./scripts/run-simulator.sh

archive: bump-build
	$(MAKE) project
	mkdir -p artifacts/release
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release -destination 'generic/platform=iOS' -archivePath $(ARCHIVE_PATH) -allowProvisioningUpdates archive

export: archive
	rm -rf $(EXPORT_PATH)
	xcodebuild -exportArchive -archivePath $(ARCHIVE_PATH) -exportPath $(EXPORT_PATH) -exportOptionsPlist $(NATIVE_DIR)/ExportOptions.plist -allowProvisioningUpdates

lint-check: bump-build
	$(MAKE) project
	./scripts/lint-check.sh

docs-build:
	bun run --cwd apps/docs build

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
	rm -rf $(DERIVED_DATA) apps/docs/dist artifacts/release
