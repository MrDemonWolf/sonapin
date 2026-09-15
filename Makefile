NATIVE_DIR := apps/native
PROJECT := $(NATIVE_DIR)/SonaPin.xcodeproj
SCHEME := SonaPin
DERIVED_DATA := $(NATIVE_DIR)/.derived-data

.PHONY: project resolve build test ui-test sim clean lint-check docs-build

project:
	cd $(NATIVE_DIR) && xcodegen generate

resolve: project
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -resolvePackageDependencies

build: resolve
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath $(DERIVED_DATA) CODE_SIGNING_ALLOWED=NO build

test:
	./scripts/test-simulator.sh unit

ui-test:
	./scripts/test-simulator.sh ui

sim:
	./scripts/run-simulator.sh

lint-check: project
	./scripts/lint-check.sh

docs-build:
	bun run --cwd apps/docs build

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
	rm -rf $(DERIVED_DATA) apps/docs/dist

