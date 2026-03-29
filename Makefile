.PHONY: build run clean test lint format generate open

SCHEME = Transy
DESTINATION = platform=macOS
DERIVED_DATA = .build
APP = $(DERIVED_DATA)/Build/Products/Debug/Transy.app

# Build the app
build:
	xcodebuild build -scheme $(SCHEME) -destination '$(DESTINATION)' -derivedDataPath $(DERIVED_DATA) -quiet

# Build and run the app
run: build
	@echo "Launching $(APP)..."
	@open $(APP)

# Clean build artifacts
clean:
	xcodebuild clean -scheme $(SCHEME) -destination '$(DESTINATION)' -derivedDataPath $(DERIVED_DATA) -quiet
	rm -rf $(DERIVED_DATA)

# Run tests
test:
	xcodebuild test -scheme $(SCHEME) -destination '$(DESTINATION)' -derivedDataPath $(DERIVED_DATA) -quiet

# Run SwiftLint
lint:
	swiftlint lint --quiet

# Run SwiftFormat (check only)
format-check:
	swiftformat --lint .

# Run SwiftFormat (auto-fix)
format:
	swiftformat .

# Regenerate Xcode project from project.yml
generate:
	xcodegen generate

# Open project in Xcode
open:
	open Transy.xcodeproj

# Build Release configuration
release:
	xcodebuild build -scheme $(SCHEME) -destination '$(DESTINATION)' -configuration Release -derivedDataPath $(DERIVED_DATA) -quiet

# Full CI check (lint + build + test)
ci: lint build test
	@echo "✅ All CI checks passed"
