import SwiftUI
import Foundation

// MARK: - Brand Identity System Protocol
protocol BrandIdentitySystemProtocol {
    func createBrandGuidelines() async throws -> BrandGuidelines
    func createLogoSystem() async throws -> LogoSystem
    func createBrandVoice() async throws -> BrandVoice
    func createMessagingFramework() async throws -> MessagingFramework
    func createBrandAssets() async throws -> [BrandAsset]
}

// MARK: - Brand Guidelines
struct BrandGuidelines: Identifiable, Codable {
    let id: String
    let name: String
    let version: String
    let mission: String
    let vision: String
    let values: [BrandValue]
    let personality: BrandPersonality
    let principles: [String]
    let guidelines: [String]
    
    init(name: String, version: String, mission: String, vision: String, values: [BrandValue], personality: BrandPersonality, principles: [String], guidelines: [String]) {
        self.id = UUID().uuidString
        self.name = name
        self.version = version
        self.mission = mission
        self.vision = vision
        self.values = values
        self.personality = personality
        self.principles = principles
        self.guidelines = guidelines
    }
}

// MARK: - Brand Value
struct BrandValue: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let examples: [String]
    
    init(name: String, description: String, examples: [String]) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.examples = examples
    }
}

// MARK: - Brand Personality
struct BrandPersonality: Codable {
    let traits: [BrandTrait]
    let tone: BrandTone
    let characteristics: [String]
    
    init(traits: [BrandTrait], tone: BrandTone, characteristics: [String]) {
        self.traits = traits
        self.tone = tone
        self.characteristics = characteristics
    }
}

// MARK: - Brand Trait
struct BrandTrait: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let intensity: Int // 1-10 scale
    
    init(name: String, description: String, intensity: Int) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.intensity = max(1, min(10, intensity))
    }
}

// MARK: - Brand Tone
struct BrandTone: Codable {
    let primary: String
    let secondary: String
    let examples: [String]
    
    init(primary: String, secondary: String, examples: [String]) {
        self.primary = primary
        self.secondary = secondary
        self.examples = examples
    }
}

// MARK: - Logo System
struct LogoSystem: Identifiable, Codable {
    let id: String
    let name: String
    let version: String
    let primaryLogo: LogoAsset
    let secondaryLogos: [LogoAsset]
    let logoVariations: [LogoVariation]
    let usageGuidelines: [String]
    let restrictions: [String]
    
    init(name: String, version: String, primaryLogo: LogoAsset, secondaryLogos: [LogoAsset], logoVariations: [LogoVariation], usageGuidelines: [String], restrictions: [String]) {
        self.id = UUID().uuidString
        self.name = name
        self.version = version
        self.primaryLogo = primaryLogo
        self.secondaryLogos = secondaryLogos
        self.logoVariations = logoVariations
        self.usageGuidelines = usageGuidelines
        self.restrictions = restrictions
    }
}

// MARK: - Logo Asset
struct LogoAsset: Identifiable, Codable {
    let id: String
    let name: String
    let type: LogoType
    let format: AssetFormat
    let size: CGSize
    let color: String
    let usage: String
    let accessibility: String
    
    init(name: String, type: LogoType, format: AssetFormat, size: CGSize, color: String, usage: String, accessibility: String) {
        self.id = UUID().uuidString
        self.name = name
        self.type = type
        self.format = format
        self.size = size
        self.color = color
        self.usage = usage
        self.accessibility = accessibility
    }
}

// MARK: - Logo Variation
struct LogoVariation: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let useCase: String
    let specifications: [String]
    
    init(name: String, description: String, useCase: String, specifications: [String]) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.useCase = useCase
        self.specifications = specifications
    }
}

// MARK: - Brand Voice
struct BrandVoice: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let characteristics: [VoiceCharacteristic]
    let toneGuidelines: [ToneGuideline]
    let examples: [VoiceExample]
    
    init(name: String, description: String, characteristics: [VoiceCharacteristic], toneGuidelines: [ToneGuideline], examples: [VoiceExample]) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.characteristics = characteristics
        self.toneGuidelines = toneGuidelines
        self.examples = examples
    }
}

// MARK: - Voice Characteristic
struct VoiceCharacteristic: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let examples: [String]
    
    init(name: String, description: String, examples: [String]) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.examples = examples
    }
}

// MARK: - Tone Guideline
struct ToneGuideline: Identifiable, Codable {
    let id: String
    let context: String
    let tone: String
    let description: String
    let examples: [String]
    
    init(context: String, tone: String, description: String, examples: [String]) {
        self.id = UUID().uuidString
        self.context = context
        self.tone = tone
        self.description = description
        self.examples = examples
    }
}

// MARK: - Voice Example
struct VoiceExample: Identifiable, Codable {
    let id: String
    let context: String
    let goodExample: String
    let badExample: String
    let explanation: String
    
    init(context: String, goodExample: String, badExample: String, explanation: String) {
        self.id = UUID().uuidString
        self.context = context
        self.goodExample = goodExample
        self.badExample = badExample
        self.explanation = explanation
    }
}

// MARK: - Messaging Framework
struct MessagingFramework: Identifiable, Codable {
    let id: String
    let name: String
    let version: String
    let keyMessages: [KeyMessage]
    let valuePropositions: [ValueProposition]
    let messagingHierarchy: [MessagingHierarchy]
    let communicationChannels: [CommunicationChannel]
    
    init(name: String, version: String, keyMessages: [KeyMessage], valuePropositions: [ValueProposition], messagingHierarchy: [MessagingHierarchy], communicationChannels: [CommunicationChannel]) {
        self.id = UUID().uuidString
        self.name = name
        self.version = version
        self.keyMessages = keyMessages
        self.valuePropositions = valuePropositions
        self.messagingHierarchy = messagingHierarchy
        self.communicationChannels = communicationChannels
    }
}

// MARK: - Key Message
struct KeyMessage: Identifiable, Codable {
    let id: String
    let message: String
    let audience: String
    let channel: String
    let supportingPoints: [String]
    
    init(message: String, audience: String, channel: String, supportingPoints: [String]) {
        self.id = UUID().uuidString
        self.message = message
        self.audience = audience
        self.channel = channel
        self.supportingPoints = supportingPoints
    }
}

// MARK: - Value Proposition
struct ValueProposition: Identifiable, Codable {
    let id: String
    let headline: String
    let description: String
    let benefits: [String]
    let proofPoints: [String]
    
    init(headline: String, description: String, benefits: [String], proofPoints: [String]) {
        self.id = UUID().uuidString
        self.headline = headline
        self.description = description
        self.benefits = benefits
        self.proofPoints = proofPoints
    }
}

// MARK: - Messaging Hierarchy
struct MessagingHierarchy: Identifiable, Codable {
    let id: String
    let level: Int
    let message: String
    let purpose: String
    let usage: String
    
    init(level: Int, message: String, purpose: String, usage: String) {
        self.id = UUID().uuidString
        self.level = level
        self.message = message
        self.purpose = purpose
        self.usage = usage
    }
}

// MARK: - Communication Channel
struct CommunicationChannel: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let tone: String
    let guidelines: [String]
    
    init(name: String, description: String, tone: String, guidelines: [String]) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.tone = tone
        self.guidelines = guidelines
    }
}

// MARK: - Brand Asset
struct BrandAsset: Identifiable, Codable {
    let id: String
    let name: String
    let type: BrandAssetType
    let category: AssetCategory
    let format: AssetFormat
    let size: CGSize
    let usage: String
    let restrictions: [String]
    
    init(name: String, type: BrandAssetType, category: AssetCategory, format: AssetFormat, size: CGSize, usage: String, restrictions: [String] = []) {
        self.id = UUID().uuidString
        self.name = name
        self.type = type
        self.category = category
        self.format = format
        self.size = size
        self.usage = usage
        self.restrictions = restrictions
    }
}

// MARK: - Enums
enum LogoType: String, Codable, CaseIterable {
    case primary = "Primary"
    case secondary = "Secondary"
    case horizontal = "Horizontal"
    case vertical = "Vertical"
    case icon = "Icon"
    case monogram = "Monogram"
}

enum BrandAssetType: String, Codable, CaseIterable {
    case logo = "Logo"
    case icon = "Icon"
    case illustration = "Illustration"
    case pattern = "Pattern"
    case texture = "Texture"
    case photography = "Photography"
}

// MARK: - Brand Identity System Implementation
actor BrandIdentitySystem: BrandIdentitySystemProtocol {
    private let guidelinesGenerator = GuidelinesGenerator()
    private let logoGenerator = LogoGenerator()
    private let voiceGenerator = VoiceGenerator()
    private let messagingGenerator = MessagingGenerator()
    private let assetGenerator = AssetGenerator()
    private let logger = Logger(subsystem: "com.healthai2030.design", category: "BrandIdentitySystem")
    
    func createBrandGuidelines() async throws -> BrandGuidelines {
        logger.info("Creating brand guidelines")
        return try await guidelinesGenerator.generate()
    }
    
    func createLogoSystem() async throws -> LogoSystem {
        logger.info("Creating logo system")
        return try await logoGenerator.generate()
    }
    
    func createBrandVoice() async throws -> BrandVoice {
        logger.info("Creating brand voice")
        return try await voiceGenerator.generate()
    }
    
    func createMessagingFramework() async throws -> MessagingFramework {
        logger.info("Creating messaging framework")
        return try await messagingGenerator.generate()
    }
    
    func createBrandAssets() async throws -> [BrandAsset] {
        logger.info("Creating brand assets")
        return try await assetGenerator.generate()
    }
}

// MARK: - Guidelines Generator
class GuidelinesGenerator {
    func generate() async throws -> BrandGuidelines {
        let values = [
            BrandValue(
                name: "Innovation",
                description: "Pioneering healthcare technology solutions",
                examples: ["AI-powered diagnostics", "Predictive health analytics", "Advanced biometric fusion"]
            ),
            BrandValue(
                name: "Trust",
                description: "Building reliable and secure healthcare experiences",
                examples: ["HIPAA compliance", "Data encryption", "Transparent privacy policies"]
            ),
            BrandValue(
                name: "Empowerment",
                description: "Enabling users to take control of their health",
                examples: ["Personalized insights", "Actionable recommendations", "Educational content"]
            ),
            BrandValue(
                name: "Accessibility",
                description: "Making healthcare technology available to everyone",
                examples: ["Universal design", "Multi-language support", "Assistive technology integration"]
            )
        ]
        
        let personality = BrandPersonality(
            traits: [
                BrandTrait(name: "Professional", description: "Expert and trustworthy", intensity: 9),
                BrandTrait(name: "Innovative", description: "Forward-thinking and cutting-edge", intensity: 8),
                BrandTrait(name: "Caring", description: "Compassionate and supportive", intensity: 7),
                BrandTrait(name: "Accessible", description: "Approachable and inclusive", intensity: 8)
            ],
            tone: BrandTone(
                primary: "Professional yet approachable",
                secondary: "Innovative and caring",
                examples: ["Clear and concise", "Technically accurate", "Warm and supportive"]
            ),
            characteristics: [
                "Expert knowledge with approachable delivery",
                "Innovation balanced with reliability",
                "Professional authority with human empathy",
                "Technical precision with clear communication"
            ]
        )
        
        let principles = [
            "Always prioritize user health and safety",
            "Maintain the highest standards of data security and privacy",
            "Design for accessibility and inclusivity",
            "Provide clear, actionable health insights",
            "Foster trust through transparency and reliability"
        ]
        
        let guidelines = [
            "Use clear, professional language that builds trust",
            "Maintain consistency across all touchpoints",
            "Prioritize accessibility in all communications",
            "Focus on user empowerment and positive outcomes",
            "Demonstrate expertise while remaining approachable"
        ]
        
        return BrandGuidelines(
            name: "HealthAI-2030 Brand Guidelines",
            version: "1.0.0",
            mission: "To revolutionize healthcare through intelligent, accessible, and personalized technology that empowers individuals to take control of their health journey.",
            vision: "A world where advanced AI technology makes healthcare more accessible, personalized, and effective for everyone.",
            values: values,
            personality: personality,
            principles: principles,
            guidelines: guidelines
        )
    }
}

// MARK: - Logo Generator
class LogoGenerator {
    func generate() async throws -> LogoSystem {
        let primaryLogo = LogoAsset(
            name: "HealthAI-2030 Primary Logo",
            type: .primary,
            format: .svg,
            size: CGSize(width: 200, height: 60),
            color: "#007AFF",
            usage: "Primary brand representation",
            accessibility: "High contrast, scalable vector format"
        )
        
        let secondaryLogos = [
            LogoAsset(
                name: "HealthAI-2030 Icon",
                type: .icon,
                format: .svg,
                size: CGSize(width: 32, height: 32),
                color: "#007AFF",
                usage: "App icons and small spaces",
                accessibility: "Simple, recognizable design"
            ),
            LogoAsset(
                name: "HealthAI-2030 Monogram",
                type: .monogram,
                format: .svg,
                size: CGSize(width: 40, height: 40),
                color: "#007AFF",
                usage: "Favicon and compact branding",
                accessibility: "Clear letterforms, good contrast"
            )
        ]
        
        let logoVariations = [
            LogoVariation(
                name: "Full Color",
                description: "Primary logo in brand colors",
                useCase: "Digital applications, marketing materials",
                specifications: ["Blue primary color", "White background", "Minimum size 120px width"]
            ),
            LogoVariation(
                name: "Monochrome",
                description: "Single color version",
                useCase: "Print materials, limited color applications",
                specifications: ["Black or white only", "High contrast", "Scalable to any size"]
            ),
            LogoVariation(
                name: "Reversed",
                description: "White logo on dark backgrounds",
                useCase: "Dark mode, dark backgrounds",
                specifications: ["White logo", "Dark background", "Maintain contrast ratio"]
            )
        ]
        
        let usageGuidelines = [
            "Always maintain clear space around the logo",
            "Use the logo at appropriate sizes for each context",
            "Maintain proper contrast ratios for accessibility",
            "Do not modify, distort, or add effects to the logo",
            "Use approved color variations only"
        ]
        
        let restrictions = [
            "Do not change the logo colors",
            "Do not stretch or distort the logo",
            "Do not add shadows or effects",
            "Do not place on busy backgrounds",
            "Do not use below minimum size requirements"
        ]
        
        return LogoSystem(
            name: "HealthAI-2030 Logo System",
            version: "1.0.0",
            primaryLogo: primaryLogo,
            secondaryLogos: secondaryLogos,
            logoVariations: logoVariations,
            usageGuidelines: usageGuidelines,
            restrictions: restrictions
        )
    }
}

// MARK: - Voice Generator
class VoiceGenerator {
    func generate() async throws -> BrandVoice {
        let characteristics = [
            VoiceCharacteristic(
                name: "Expert",
                description: "Demonstrates deep knowledge and authority in healthcare technology",
                examples: ["Advanced AI algorithms", "Clinical-grade accuracy", "Evidence-based insights"]
            ),
            VoiceCharacteristic(
                name: "Approachable",
                description: "Makes complex technology accessible and understandable",
                examples: ["Easy-to-understand explanations", "Clear step-by-step guidance", "Friendly interface language"]
            ),
            VoiceCharacteristic(
                name: "Supportive",
                description: "Encourages and empowers users in their health journey",
                examples: ["You're making great progress", "We're here to help", "Small steps lead to big changes"]
            ),
            VoiceCharacteristic(
                name: "Trustworthy",
                description: "Builds confidence through reliability and transparency",
                examples: ["Your data is secure", "Backed by medical research", "HIPAA compliant"]
            )
        ]
        
        let toneGuidelines = [
            ToneGuideline(
                context: "Health Alerts",
                tone: "Urgent but calm",
                description: "Convey importance without causing panic",
                examples: ["Important health update", "Please review your data", "Consider consulting your doctor"]
            ),
            ToneGuideline(
                context: "Educational Content",
                tone: "Informative and encouraging",
                description: "Teach while motivating continued engagement",
                examples: ["Learn how this affects your health", "Understanding your metrics", "Tips for improvement"]
            ),
            ToneGuideline(
                context: "Success Messages",
                tone: "Celebratory and supportive",
                description: "Acknowledge achievements and encourage continued progress",
                examples: ["Great job on your progress", "You've reached a milestone", "Keep up the excellent work"]
            )
        ]
        
        let examples = [
            VoiceExample(
                context: "Health Alert",
                goodExample: "Your heart rate pattern shows some changes. Consider reviewing with your healthcare provider.",
                badExample: "WARNING: Your heart rate is ABNORMAL! This is SERIOUS!",
                explanation: "The good example is informative and calm, while the bad example is alarming and unprofessional."
            ),
            VoiceExample(
                context: "Feature Introduction",
                goodExample: "Discover how AI can help you understand your sleep patterns better.",
                badExample: "Our revolutionary AI technology will completely transform your sleep experience!",
                explanation: "The good example is informative and realistic, while the bad example is overly promotional."
            )
        ]
        
        return BrandVoice(
            name: "HealthAI-2030 Brand Voice",
            description: "Professional, approachable, and trustworthy voice that empowers users through intelligent healthcare technology",
            characteristics: characteristics,
            toneGuidelines: toneGuidelines,
            examples: examples
        )
    }
}

// MARK: - Messaging Generator
class MessagingGenerator {
    func generate() async throws -> MessagingFramework {
        let keyMessages = [
            KeyMessage(
                message: "Your health, intelligently personalized",
                audience: "General users",
                channel: "All channels",
                supportingPoints: ["AI-powered insights", "Personalized recommendations", "Comprehensive health tracking"]
            ),
            KeyMessage(
                message: "Advanced healthcare technology made accessible",
                audience: "Tech-savvy users",
                channel: "Digital marketing",
                supportingPoints: ["Cutting-edge AI", "Clinical-grade accuracy", "User-friendly interface"]
            ),
            KeyMessage(
                message: "Empowering your health journey with intelligent insights",
                audience: "Health-conscious users",
                channel: "Health platforms",
                supportingPoints: ["Actionable insights", "Progress tracking", "Educational content"]
            )
        ]
        
        let valuePropositions = [
            ValueProposition(
                headline: "AI-Powered Health Intelligence",
                description: "Advanced artificial intelligence that understands your unique health patterns and provides personalized insights.",
                benefits: ["Personalized health insights", "Predictive health analytics", "Actionable recommendations"],
                proofPoints: ["Clinical-grade accuracy", "FDA-cleared algorithms", "Peer-reviewed research"]
            ),
            ValueProposition(
                headline: "Comprehensive Health Ecosystem",
                description: "Complete health tracking across all aspects of wellness with seamless integration.",
                benefits: ["All-in-one health platform", "Cross-device synchronization", "Comprehensive data analysis"],
                proofPoints: ["Multiple device support", "Real-time data sync", "Comprehensive health metrics"]
            )
        ]
        
        let messagingHierarchy = [
            MessagingHierarchy(
                level: 1,
                message: "Your health, intelligently personalized",
                purpose: "Primary brand message",
                usage: "Main headlines, brand communications"
            ),
            MessagingHierarchy(
                level: 2,
                message: "AI-powered insights for better health",
                purpose: "Secondary supporting message",
                usage: "Feature descriptions, marketing materials"
            ),
            MessagingHierarchy(
                level: 3,
                message: "Advanced technology, accessible design",
                purpose: "Tertiary supporting message",
                usage: "Detailed explanations, technical content"
            )
        ]
        
        let communicationChannels = [
            CommunicationChannel(
                name: "In-App Messaging",
                description: "Direct communication within the app",
                tone: "Helpful and encouraging",
                guidelines: ["Keep messages concise", "Use clear action words", "Provide immediate value"]
            ),
            CommunicationChannel(
                name: "Email Communications",
                description: "Regular updates and educational content",
                tone: "Informative and engaging",
                guidelines: ["Personalize content", "Include clear CTAs", "Provide valuable insights"]
            ),
            CommunicationChannel(
                name: "Social Media",
                description: "Community engagement and brand awareness",
                tone: "Engaging and educational",
                guidelines: ["Share user success stories", "Provide health tips", "Engage with community"]
            )
        ]
        
        return MessagingFramework(
            name: "HealthAI-2030 Messaging Framework",
            version: "1.0.0",
            keyMessages: keyMessages,
            valuePropositions: valuePropositions,
            messagingHierarchy: messagingHierarchy,
            communicationChannels: communicationChannels
        )
    }
}

// MARK: - Asset Generator
class AssetGenerator {
    func generate() async throws -> [BrandAsset] {
        return [
            BrandAsset(
                name: "HealthAI-2030 Primary Logo",
                type: .logo,
                category: .branding,
                format: .svg,
                size: CGSize(width: 200, height: 60),
                usage: "Primary brand representation",
                restrictions: ["Do not modify colors", "Maintain aspect ratio"]
            ),
            BrandAsset(
                name: "HealthAI-2030 Icon",
                type: .icon,
                category: .branding,
                format: .svg,
                size: CGSize(width: 32, height: 32),
                usage: "App icons and small spaces",
                restrictions: ["Use at specified sizes only"]
            ),
            BrandAsset(
                name: "Health Pattern",
                type: .pattern,
                category: .ui,
                format: .svg,
                size: CGSize(width: 100, height: 100),
                usage: "Background patterns and textures",
                restrictions: ["Use as repeating pattern only"]
            ),
            BrandAsset(
                name: "Health Illustration Set",
                type: .illustration,
                category: .marketing,
                format: .svg,
                size: CGSize(width: 400, height: 300),
                usage: "Marketing materials and presentations",
                restrictions: ["Do not modify illustrations", "Maintain brand colors"]
            )
        ]
    }
}

// MARK: - SwiftUI Views for Brand Identity System
struct BrandIdentitySystemView: View {
    @State private var brandGuidelines: BrandGuidelines?
    @State private var logoSystem: LogoSystem?
    @State private var brandVoice: BrandVoice?
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            BrandGuidelinesView(brandGuidelines: $brandGuidelines)
                .tabItem {
                    Image(systemName: "book")
                    Text("Guidelines")
                }
                .tag(0)
            
            LogoSystemView(logoSystem: $logoSystem)
                .tabItem {
                    Image(systemName: "paintbrush")
                    Text("Logo System")
                }
                .tag(1)
            
            BrandVoiceView(brandVoice: $brandVoice)
                .tabItem {
                    Image(systemName: "message")
                    Text("Brand Voice")
                }
                .tag(2)
        }
        .navigationTitle("Brand Identity")
        .onAppear {
            loadBrandIdentity()
        }
    }
    
    private func loadBrandIdentity() {
        // Load brand identity components
    }
}

struct BrandGuidelinesView: View {
    @Binding var brandGuidelines: BrandGuidelines?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let guidelines = brandGuidelines {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Mission")
                            .font(.headline)
                        Text(guidelines.mission)
                            .font(.body)
                        
                        Text("Vision")
                            .font(.headline)
                        Text(guidelines.vision)
                            .font(.body)
                        
                        Text("Values")
                            .font(.headline)
                        ForEach(guidelines.values) { value in
                            VStack(alignment: .leading) {
                                Text(value.name)
                                    .font(.subheadline.bold())
                                Text(value.description)
                                    .font(.caption)
                            }
                            .padding(.leading)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    ProgressView("Loading brand guidelines...")
                }
            }
            .padding()
        }
    }
}

struct LogoSystemView: View {
    @Binding var logoSystem: LogoSystem?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let logos = logoSystem {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Primary Logo")
                            .font(.headline)
                        LogoCard(logo: logos.primaryLogo)
                        
                        Text("Secondary Logos")
                            .font(.headline)
                        ForEach(logos.secondaryLogos) { logo in
                            LogoCard(logo: logo)
                        }
                        
                        Text("Usage Guidelines")
                            .font(.headline)
                        ForEach(logos.usageGuidelines, id: \.self) { guideline in
                            Text("• \(guideline)")
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    ProgressView("Loading logo system...")
                }
            }
            .padding()
        }
    }
}

struct LogoCard: View {
    let logo: LogoAsset
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(logo.name)
                .font(.subheadline.bold())
            
            Text("Type: \(logo.type.rawValue)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Usage: \(logo.usage)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

struct BrandVoiceView: View {
    @Binding var brandVoice: BrandVoice?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let voice = brandVoice {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Characteristics")
                            .font(.headline)
                        ForEach(voice.characteristics) { characteristic in
                            VStack(alignment: .leading) {
                                Text(characteristic.name)
                                    .font(.subheadline.bold())
                                Text(characteristic.description)
                                    .font(.caption)
                            }
                            .padding(.leading)
                        }
                        
                        Text("Tone Guidelines")
                            .font(.headline)
                        ForEach(voice.toneGuidelines) { guideline in
                            VStack(alignment: .leading) {
                                Text(guideline.context)
                                    .font(.subheadline.bold())
                                Text(guideline.tone)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    ProgressView("Loading brand voice...")
                }
            }
            .padding()
        }
    }
}

// MARK: - Preview
struct BrandIdentitySystem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BrandIdentitySystemView()
        }
        .previewDevice("iPhone 15 Pro")
    }
} 