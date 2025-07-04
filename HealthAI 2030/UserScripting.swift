import Foundation

/// User scripting engine for custom automations and analytics pipelines.
public class UserScriptingEngine {
    private let parser = DSLParser()
    private let engine = ScriptingEngine()

    public init() {}

    public func run(script: String) -> String {
        guard let userScript = parser.parse(script) else {
            return "Error: Failed to parse script."
        }
        engine.execute(userScript)
        return "Script executed successfully."
    }
}
