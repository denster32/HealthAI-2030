#!/bin/bash
# feature_scaffold.sh
# Usage: ./feature_scaffold.sh FeatureName

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 FeatureName"
  exit 1
fi

FEATURE_NAME="$1"
MODULE_DIR="Modules/Features/$FEATURE_NAME/$FEATURE_NAME"

mkdir -p "$MODULE_DIR/Models" "$MODULE_DIR/ViewModels" "$MODULE_DIR/Views" "$MODULE_DIR/Managers" "$MODULE_DIR/Services" "$MODULE_DIR/Shortcuts"

touch "$MODULE_DIR/Models/${FEATURE_NAME}Model.swift"
touch "$MODULE_DIR/ViewModels/${FEATURE_NAME}ViewModel.swift"
touch "$MODULE_DIR/Views/${FEATURE_NAME}View.swift"
touch "$MODULE_DIR/Managers/${FEATURE_NAME}Manager.swift"
touch "$MODULE_DIR/Services/${FEATURE_NAME}Service.swift"
touch "$MODULE_DIR/Shortcuts/${FEATURE_NAME}Shortcuts.swift"

echo "// Swift Package manifest" > "Modules/Features/$FEATURE_NAME/Package.swift"

echo "Feature module '$FEATURE_NAME' scaffolded successfully." 