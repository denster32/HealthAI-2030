import SwiftUI
import Foundation

// MARK: - Design Asset Management Protocol
protocol DesignAssetManagementProtocol {
    func organizeAssets(_ assets: [DesignAsset]) async throws -> AssetOrganization
    func versionControl(_ asset: DesignAsset) async throws -> AssetVersion
    func createDesignTokens() async throws -> DesignTokenSystem
    func generateIconSystem() async throws -> IconSystem
    func optimizeAssets(_ assets: [DesignAsset]) async throws -> [OptimizedAsset]
}

// MARK: - Design Asset Model
struct DesignAsset: Identifiable, Codable {
    let id: String
    let name: String
    let type: AssetType
    let category: AssetCategory
    let format: AssetFormat
    let size: CGSize
    let fileSize: Int64
    let tags: [String]
    let metadata: [String: String]
    let createdAt: Date
    let updatedAt: Date
    
    init(name: String, type: AssetType, category: AssetCategory, format: AssetFormat, size: CGSize, fileSize: Int64, tags: [String] = [], metadata: [String: String] = [:]) {
        self.id = UUID().uuidString
        self.name = name
        self.type = type
        self.category = category
        self.format = format
        self.size = size
        self.fileSize = fileSize
        self.tags = tags
        self.metadata = metadata
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Asset Organization
struct AssetOrganization: Identifiable, Codable {
    let id: String
    let name: String
    let structure: AssetStructure
    let categories: [AssetCategory]
    let tags: [String]
    let searchIndex: [String: String]
    
    init(name: String, structure: AssetStructure, categories: [AssetCategory], tags: [String], searchIndex: [String: String]) {
        self.id = UUID().uuidString
        self.name = name
        self.structure = structure
        self.categories = categories
        self.tags = tags
        self.searchIndex = searchIndex
    }
}

// MARK: - Asset Structure
struct AssetStructure: Codable {
    let folders: [AssetFolder]
    let namingConvention: String
    let organizationRules: [String]
    
    init(folders: [AssetFolder], namingConvention: String, organizationRules: [String]) {
        self.folders = folders
        self.namingConvention = namingConvention
        self.organizationRules = organizationRules
    }
}

// MARK: - Asset Folder
struct AssetFolder: Identifiable, Codable {
    let id: String
    let name: String
    let path: String
    let description: String
    let assets: [String]
    let subfolders: [AssetFolder]
    
    init(name: String, path: String, description: String, assets: [String] = [], subfolders: [AssetFolder] = []) {
        self.id = UUID().uuidString
        self.name = name
        self.path = path
        self.description = description
        self.assets = assets
        self.subfolders = subfolders
    }
}

// MARK: - Asset Version
struct AssetVersion: Identifiable, Codable {
    let id: String
    let assetID: String
    let version: String
    let changes: [String]
    let author: String
    let timestamp: Date
    let fileHash: String
    
    init(assetID: String, version: String, changes: [String], author: String, fileHash: String) {
        self.id = UUID().uuidString
        self.assetID = assetID
        self.version = version
        self.changes = changes
        self.author = author
        self.timestamp = Date()
        self.fileHash = fileHash
    }
}

// MARK: - Design Token System
struct DesignTokenSystem: Identifiable, Codable {
    let id: String
    let name: String
    let version: String
    let tokens: [DesignToken]
    let categories: [TokenCategory]
    let documentation: String
    
    init(name: String, version: String, tokens: [DesignToken], categories: [TokenCategory], documentation: String) {
        self.id = UUID().uuidString
        self.name = name
        self.version = version
        self.tokens = tokens
        self.categories = categories
        self.documentation = documentation
    }
}

// MARK: - Design Token
struct DesignToken: Identifiable, Codable {
    let id: String
    let name: String
    let value: String
    let type: TokenType
    let category: String
    let description: String
    let usage: [String]
    
    init(name: String, value: String, type: TokenType, category: String, description: String, usage: [String] = []) {
        self.id = UUID().uuidString
        self.name = name
        self.value = value
        self.type = type
        self.category = category
        self.description = description
        self.usage = usage
    }
}

// MARK: - Token Category
struct TokenCategory: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let tokens: [String]
    
    init(name: String, description: String, tokens: [String] = []) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.tokens = tokens
    }
}

// MARK: - Icon System
struct IconSystem: Identifiable, Codable {
    let id: String
    let name: String
    let version: String
    let icons: [IconAsset]
    let styles: [IconStyle]
    let guidelines: [String]
    
    init(name: String, version: String, icons: [IconAsset], styles: [IconStyle], guidelines: [String]) {
        self.id = UUID().uuidString
        self.name = name
        self.version = version
        self.icons = icons
        self.styles = styles
        self.guidelines = guidelines
    }
}

// MARK: - Icon Asset
struct IconAsset: Identifiable, Codable {
    let id: String
    let name: String
    let symbol: String
    let category: IconCategory
    let sizes: [IconSize]
    let styles: [String]
    let accessibility: String
    
    init(name: String, symbol: String, category: IconCategory, sizes: [IconSize], styles: [String], accessibility: String) {
        self.id = UUID().uuidString
        self.name = name
        self.symbol = symbol
        self.category = category
        self.sizes = sizes
        self.styles = styles
        self.accessibility = accessibility
    }
}

// MARK: - Icon Size
struct IconSize: Identifiable, Codable {
    let id: String
    let size: CGSize
    let scale: CGFloat
    let usage: String
    
    init(size: CGSize, scale: CGFloat, usage: String) {
        self.id = UUID().uuidString
        self.size = size
        self.scale = scale
        self.usage = usage
    }
}

// MARK: - Icon Style
struct IconStyle: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let properties: [String: String]
    
    init(name: String, description: String, properties: [String: String]) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.properties = properties
    }
}

// MARK: - Optimized Asset
struct OptimizedAsset: Identifiable, Codable {
    let id: String
    let originalAssetID: String
    let optimizationType: OptimizationType
    let originalSize: Int64
    let optimizedSize: Int64
    let compressionRatio: Double
    let quality: Double
    let format: AssetFormat
    
    init(originalAssetID: String, optimizationType: OptimizationType, originalSize: Int64, optimizedSize: Int64, quality: Double, format: AssetFormat) {
        self.id = UUID().uuidString
        self.originalAssetID = originalAssetID
        self.optimizationType = optimizationType
        self.originalSize = originalSize
        self.optimizedSize = optimizedSize
        self.compressionRatio = Double(optimizedSize) / Double(originalSize)
        self.quality = quality
        self.format = format
    }
}

// MARK: - Enums
enum AssetType: String, Codable, CaseIterable {
    case image = "Image"
    case icon = "Icon"
    case illustration = "Illustration"
    case animation = "Animation"
    case video = "Video"
    case audio = "Audio"
    case document = "Document"
    case font = "Font"
}

enum AssetCategory: String, Codable, CaseIterable {
    case branding = "Branding"
    case ui = "UI"
    case marketing = "Marketing"
    case social = "Social"
    case print = "Print"
    case web = "Web"
    case mobile = "Mobile"
    case accessibility = "Accessibility"
}

enum AssetFormat: String, Codable, CaseIterable {
    case png = "PNG"
    case jpg = "JPG"
    case svg = "SVG"
    case pdf = "PDF"
    case mp4 = "MP4"
    case mov = "MOV"
    case mp3 = "MP3"
    case wav = "WAV"
    case ttf = "TTF"
    case otf = "OTF"
}

enum TokenType: String, Codable, CaseIterable {
    case color = "Color"
    case typography = "Typography"
    case spacing = "Spacing"
    case shadow = "Shadow"
    case border = "Border"
    case radius = "Radius"
    case animation = "Animation"
}

enum IconCategory: String, Codable, CaseIterable {
    case navigation = "Navigation"
    case action = "Action"
    case status = "Status"
    case health = "Health"
    case communication = "Communication"
    case system = "System"
}

enum OptimizationType: String, Codable, CaseIterable {
    case compression = "Compression"
    case resizing = "Resizing"
    case formatConversion = "Format Conversion"
    case qualityReduction = "Quality Reduction"
    case metadataRemoval = "Metadata Removal"
}

// MARK: - Design Asset Management Implementation
actor DesignAssetManagement: DesignAssetManagementProtocol {
    private let assetOrganizer = AssetOrganizer()
    private let versionController = VersionController()
    private let tokenGenerator = TokenGenerator()
    private let iconGenerator = IconGenerator()
    private let assetOptimizer = AssetOptimizer()
    private let logger = Logger(subsystem: "com.healthai2030.design", category: "DesignAssetManagement")
    
    func organizeAssets(_ assets: [DesignAsset]) async throws -> AssetOrganization {
        logger.info("Organizing \(assets.count) design assets")
        return try await assetOrganizer.organize(assets)
    }
    
    func versionControl(_ asset: DesignAsset) async throws -> AssetVersion {
        logger.info("Creating version control for asset: \(asset.name)")
        return try await versionController.createVersion(for: asset)
    }
    
    func createDesignTokens() async throws -> DesignTokenSystem {
        logger.info("Creating design token system")
        return try await tokenGenerator.generate()
    }
    
    func generateIconSystem() async throws -> IconSystem {
        logger.info("Generating icon system")
        return try await iconGenerator.generate()
    }
    
    func optimizeAssets(_ assets: [DesignAsset]) async throws -> [OptimizedAsset] {
        logger.info("Optimizing \(assets.count) assets")
        return try await assetOptimizer.optimize(assets)
    }
}

// MARK: - Asset Organizer
class AssetOrganizer {
    func organize(_ assets: [DesignAsset]) async throws -> AssetOrganization {
        let structure = AssetStructure(
            folders: [
                AssetFolder(
                    name: "Branding",
                    path: "/assets/branding",
                    description: "Brand identity assets",
                    assets: assets.filter { $0.category == .branding }.map { $0.id }
                ),
                AssetFolder(
                    name: "UI",
                    path: "/assets/ui",
                    description: "User interface assets",
                    assets: assets.filter { $0.category == .ui }.map { $0.id }
                ),
                AssetFolder(
                    name: "Icons",
                    path: "/assets/icons",
                    description: "Icon system assets",
                    assets: assets.filter { $0.type == .icon }.map { $0.id }
                )
            ],
            namingConvention: "category-type-name-version",
            organizationRules: [
                "Use consistent naming conventions",
                "Group by category and type",
                "Include version numbers",
                "Add descriptive tags"
            ]
        )
        
        let categories = Array(Set(assets.map { $0.category }))
        let tags = Array(Set(assets.flatMap { $0.tags }))
        let searchIndex = createSearchIndex(from: assets)
        
        return AssetOrganization(
            name: "HealthAI-2030 Assets",
            structure: structure,
            categories: categories,
            tags: tags,
            searchIndex: searchIndex
        )
    }
    
    private func createSearchIndex(from assets: [DesignAsset]) -> [String: String] {
        var index: [String: String] = [:]
        for asset in assets {
            index[asset.name.lowercased()] = asset.id
            for tag in asset.tags {
                index[tag.lowercased()] = asset.id
            }
        }
        return index
    }
}

// MARK: - Version Controller
class VersionController {
    func createVersion(for asset: DesignAsset) async throws -> AssetVersion {
        let version = "1.0.0"
        let changes = ["Initial version", "Asset created"]
        let author = "Design System"
        let fileHash = generateFileHash(for: asset)
        
        return AssetVersion(
            assetID: asset.id,
            version: version,
            changes: changes,
            author: author,
            fileHash: fileHash
        )
    }
    
    private func generateFileHash(for asset: DesignAsset) -> String {
        // Simulate file hash generation
        return "hash_\(asset.id)_\(asset.fileSize)"
    }
}

// MARK: - Token Generator
class TokenGenerator {
    func generate() async throws -> DesignTokenSystem {
        let tokens = [
            DesignToken(
                name: "primary-blue",
                value: "#007AFF",
                type: .color,
                category: "Colors",
                description: "Primary brand color",
                usage: ["Buttons", "Links", "Branding"]
            ),
            DesignToken(
                name: "primary-green",
                value: "#34C759",
                type: .color,
                category: "Colors",
                description: "Success and health indicators",
                usage: ["Success states", "Health metrics", "Positive actions"]
            ),
            DesignToken(
                name: "font-size-large",
                value: "34px",
                type: .typography,
                category: "Typography",
                description: "Large title font size",
                usage: ["Main headings", "Page titles"]
            ),
            DesignToken(
                name: "spacing-base",
                value: "8px",
                type: .spacing,
                category: "Spacing",
                description: "Base spacing unit",
                usage: ["Component spacing", "Layout margins"]
            ),
            DesignToken(
                name: "shadow-default",
                value: "0 2px 8px rgba(0,0,0,0.1)",
                type: .shadow,
                category: "Shadows",
                description: "Default shadow for cards and modals",
                usage: ["Cards", "Modals", "Elevated elements"]
            )
        ]
        
        let categories = [
            TokenCategory(name: "Colors", description: "Color palette tokens", tokens: ["primary-blue", "primary-green"]),
            TokenCategory(name: "Typography", description: "Typography tokens", tokens: ["font-size-large"]),
            TokenCategory(name: "Spacing", description: "Spacing tokens", tokens: ["spacing-base"]),
            TokenCategory(name: "Shadows", description: "Shadow tokens", tokens: ["shadow-default"])
        ]
        
        return DesignTokenSystem(
            name: "HealthAI-2030 Design Tokens",
            version: "1.0.0",
            tokens: tokens,
            categories: categories,
            documentation: "Comprehensive design token system for HealthAI-2030"
        )
    }
}

// MARK: - Icon Generator
class IconGenerator {
    func generate() async throws -> IconSystem {
        let icons = [
            IconAsset(
                name: "heart",
                symbol: "heart.fill",
                category: .health,
                sizes: [
                    IconSize(size: CGSize(width: 16, height: 16), scale: 1.0, usage: "Small icons"),
                    IconSize(size: CGSize(width: 24, height: 24), scale: 1.0, usage: "Standard icons"),
                    IconSize(size: CGSize(width: 32, height: 32), scale: 1.0, usage: "Large icons")
                ],
                styles: ["filled", "outlined"],
                accessibility: "Heart icon for health metrics"
            ),
            IconAsset(
                name: "activity",
                symbol: "activity",
                category: .health,
                sizes: [
                    IconSize(size: CGSize(width: 16, height: 16), scale: 1.0, usage: "Small icons"),
                    IconSize(size: CGSize(width: 24, height: 24), scale: 1.0, usage: "Standard icons")
                ],
                styles: ["filled", "outlined"],
                accessibility: "Activity icon for fitness tracking"
            ),
            IconAsset(
                name: "settings",
                symbol: "gearshape.fill",
                category: .system,
                sizes: [
                    IconSize(size: CGSize(width: 16, height: 16), scale: 1.0, usage: "Small icons"),
                    IconSize(size: CGSize(width: 24, height: 24), scale: 1.0, usage: "Standard icons")
                ],
                styles: ["filled", "outlined"],
                accessibility: "Settings icon for app configuration"
            )
        ]
        
        let styles = [
            IconStyle(
                name: "Filled",
                description: "Solid filled icon style",
                properties: ["fill": "solid", "stroke": "none"]
            ),
            IconStyle(
                name: "Outlined",
                description: "Outlined icon style",
                properties: ["fill": "none", "stroke": "1px"]
            )
        ]
        
        let guidelines = [
            "Use consistent sizing across the app",
            "Ensure proper contrast ratios",
            "Provide accessibility labels",
            "Maintain visual hierarchy"
        ]
        
        return IconSystem(
            name: "HealthAI-2030 Icon System",
            version: "1.0.0",
            icons: icons,
            styles: styles,
            guidelines: guidelines
        )
    }
}

// MARK: - Asset Optimizer
class AssetOptimizer {
    func optimize(_ assets: [DesignAsset]) async throws -> [OptimizedAsset] {
        var optimizedAssets: [OptimizedAsset] = []
        
        for asset in assets {
            let optimizationType: OptimizationType = asset.format == .png ? .compression : .formatConversion
            let originalSize = asset.fileSize
            let optimizedSize = Int64(Double(originalSize) * 0.7) // 30% reduction
            let quality = 0.9
            
            let optimizedAsset = OptimizedAsset(
                originalAssetID: asset.id,
                optimizationType: optimizationType,
                originalSize: originalSize,
                optimizedSize: optimizedSize,
                quality: quality,
                format: asset.format
            )
            
            optimizedAssets.append(optimizedAsset)
        }
        
        return optimizedAssets
    }
}

// MARK: - SwiftUI Views for Design Asset Management
struct DesignAssetManagementView: View {
    @State private var assets: [DesignAsset] = []
    @State private var organization: AssetOrganization?
    @State private var selectedCategory: AssetCategory?
    
    var body: some View {
        NavigationView {
            VStack {
                if let organization = organization {
                    AssetOrganizationView(organization: organization)
                } else {
                    ProgressView("Loading assets...")
                }
            }
            .navigationTitle("Design Assets")
            .onAppear {
                loadAssets()
            }
        }
    }
    
    private func loadAssets() {
        // Load design assets
        assets = [
            DesignAsset(
                name: "logo-primary",
                type: .image,
                category: .branding,
                format: .png,
                size: CGSize(width: 200, height: 60),
                fileSize: 15000,
                tags: ["logo", "brand", "primary"]
            ),
            DesignAsset(
                name: "heart-icon",
                type: .icon,
                category: .ui,
                format: .svg,
                size: CGSize(width: 24, height: 24),
                fileSize: 2000,
                tags: ["icon", "health", "heart"]
            )
        ]
    }
}

struct AssetOrganizationView: View {
    let organization: AssetOrganization
    
    var body: some View {
        List {
            ForEach(organization.structure.folders) { folder in
                Section(header: Text(folder.name)) {
                    Text(folder.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(folder.assets.count) assets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct DesignTokenView: View {
    @State private var tokenSystem: DesignTokenSystem?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let tokens = tokenSystem {
                    ForEach(tokens.categories) { category in
                        VStack(alignment: .leading) {
                            Text(category.name)
                                .font(.headline)
                            
                            ForEach(tokens.tokens.filter { $0.category == category.name }) { token in
                                TokenCard(token: token)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                } else {
                    ProgressView("Loading design tokens...")
                }
            }
            .padding()
        }
        .navigationTitle("Design Tokens")
        .onAppear {
            loadDesignTokens()
        }
    }
    
    private func loadDesignTokens() {
        // Load design token system
    }
}

struct TokenCard: View {
    let token: DesignToken
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(token.name)
                    .font(.subheadline.bold())
                Spacer()
                Text(token.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(token.value)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(token.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

struct IconSystemView: View {
    @State private var iconSystem: IconSystem?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                if let icons = iconSystem {
                    ForEach(icons.icons) { icon in
                        IconCard(icon: icon)
                    }
                } else {
                    ProgressView("Loading icons...")
                }
            }
            .padding()
        }
        .navigationTitle("Icon System")
        .onAppear {
            loadIconSystem()
        }
    }
    
    private func loadIconSystem() {
        // Load icon system
    }
}

struct IconCard: View {
    let icon: IconAsset
    
    var body: some View {
        VStack {
            Image(systemName: icon.symbol)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(icon.name)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(height: 80)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview
struct DesignAssetManagement_Previews: PreviewProvider {
    static var previews: some View {
        DesignAssetManagementView()
            .previewDevice("iPhone 15 Pro")
    }
} 