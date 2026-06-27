SWIFT := "/usr/bin/swift"

check:
	@$(SWIFT) format \
		lint \
		--strict \
		--parallel \
		--recursive \
		./Helsinki

format:
	@$(SWIFT) format \
		--ignore-unparsable-files \
		--in-place \
		--parallel \
		--recursive \
		./Helsinki

build:
	@echo "Building Helsinki for iOS..."
	@xcodebuild build \
		CODE_SIGN_IDENTITY='' \
		CODE_SIGN_STYLE='Automatic' \
		-project Helsinki.xcodeproj \
		-scheme Helsinki \
		-destination 'generic/platform=iOS Simulator' \
		| xcbeautify

.PHONY: check format build
