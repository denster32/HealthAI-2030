import Foundation
import Combine

@available(iOS 17.0, *)
@available(macOS 14.0, *)
class RemoteSkillProvider: ObservableObject {
    @Published var manifests: [HealthCopilotSkillManifest] = []
    private var cancellable: AnyCancellable?
    private let marketplaceURL = URL(string: "https://raw.githubusercontent.com/health-ai-2030/skills-marketplace/main/manifest.json")!

    init() {
        fetchManifests()
    }

    func fetchManifests() {
        cancellable = URLSession.shared.dataTaskPublisher(for: marketplaceURL)
            .map { $0.data }
            .decode(type: SkillMarketplaceManifest.self, decoder: JSONDecoder())
            .map { $0.skills }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: \.manifests, on: self)
    }
}
