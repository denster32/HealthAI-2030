# Build Phase Setup Instructions

## SwiftLint Integration

To add SwiftLint to your Xcode build process:

1. Open your Xcode project
2. Select your target in the Project Navigator
3. Go to the "Build Phases" tab
4. Click the "+" button and select "New Run Script Phase"
5. Name the phase "SwiftLint"
6. Add this script content:

```bash
if which swiftlint >/dev/null; then
    swiftlint
else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
```

Alternatively, you can reference the script file:
```bash
"${SRCROOT}/Scripts/swiftlint.sh"
```

## Installation

Install SwiftLint via Homebrew:
```bash
brew install swiftlint
```

Or download from: https://github.com/realm/SwiftLint

## Configuration

The SwiftLint configuration is in `.swiftlint.yml` at the project root.