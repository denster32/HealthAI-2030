all: build

build:
	xcodebuild -scheme "HealthAI 2030" -destination 'platform=iOS Simulator,name=iPhone 15' build

test:
	xcodebuild test -scheme "HealthAI 2030" -destination 'platform=iOS Simulator,name=iPhone 15'

lint:
	swiftlint

format:
	swiftformat .

docs:
	xcodebuild docbuild -scheme "HealthAI 2030" -destination 'platform=iOS Simulator,name=iPhone 15'
