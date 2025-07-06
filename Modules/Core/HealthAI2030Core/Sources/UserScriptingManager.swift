import Foundation
import Combine

@MainActor
class UserScriptingManager: ObservableObject {
    static let shared = UserScriptingManager()
    @Published var scripts: [UserScript] = []
    
    private init() {}
    
    func addScript(_ script: UserScript) {
        scripts.append(script)
        saveScripts()
    }
    
    func runScript(_ script: UserScript) {
        let dslParser = DSLParser()
        let scriptingEngine = ScriptingEngine()
        if let parsedScript = dslParser.parse(script.code) {
            scriptingEngine.execute(parsedScript)
        } else {
            print("Error: Could not parse script: \(script.name)")
        }
    }

    func deleteScript(id: UUID) {
        scripts.removeAll { $0.id == id }
        saveScripts()
    }

    private func saveScripts() {
        if let encoded = try? JSONEncoder().encode(scripts) {
            UserDefaults.standard.set(encoded, forKey: "userScripts")
        }
    }

    private func loadScripts() {
        if let savedScripts = UserDefaults.standard.data(forKey: "userScripts"),
           let decodedScripts = try? JSONDecoder().decode([UserScript].self, from: savedScripts) {
            scripts = decodedScripts
        }
    }
}

struct UserScript: Identifiable, Codable {
    let id: UUID
    var name: String
    var code: String
    let created: Date
    var modified: Date

    // For UI representation in UserScriptingView
    var condition: DSLCondition {
        let parser = DSLParser()
        return parser.parse(code)?.condition ?? DSLCondition(metric: "unknown", comparison: "==", value: 0.0)
    }

    var actions: [DSLAction] {
        let parser = DSLParser()
        return parser.parse(code)?.actions ?? []
    }
}
