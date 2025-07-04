# Developer Guide: Extending HealthAI 2030

## Adding a New Plugin

1. Create a new class conforming to `HealthAIPlugin`.
2. Implement `pluginName`, `pluginDescription`, and `activate()`.
3. Register your plugin with `PluginManager.shared.register(plugin:)`.

## Adding a New Widget

1. Create a new Swift file in `HealthAI2030Widgets/`.
2. Implement a `TimelineProvider`, `Entry`, and `Widget` struct.
3. Add your widget to the app target and test on device.

## Adding a New Shortcut

1. Create a new AppIntent in `Shortcuts/`.
2. Implement your intent logic and phrases.
3. Test in the Shortcuts app and integrate with your features.

## Contributing to the Scripting DSL

1. Add new actions or conditions to `UserScriptingDSL.swift`.
2. Update the parser and engine to support your new features.
3. Document your changes in `UserScripting/Examples/`.
