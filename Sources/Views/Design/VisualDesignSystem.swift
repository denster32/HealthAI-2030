import SwiftUI
import Foundation

// MARK: - Visual Design System Protocol
protocol VisualDesignSystemProtocol {
    func createColorSystem() async throws -> ColorSystem
    func createTypographySystem() async throws -> TypographySystem
    func createLayoutSystem() async throws -> LayoutSystem
    func createVisualHierarchy() async throws -> VisualHierarchy
    func createDesignPatterns() async throws -> [DesignPattern]
}

// MARK: - Color System
struct ColorSystem: Identifiable, Codable {
    let id: String
    let name: String
    let version: String
    let primary: ColorPalette
    let secondary: ColorPalette
    let neutral: ColorPalette
    let semantic: ColorPalette
    let gradients: [GradientDefinition]
    let accessibility: AccessibilityColors
    
    init(name: String, version: String, primary: ColorPalette, secondary: ColorPalette, neutral: ColorPalette, semantic: ColorPalette, gradients: [GradientDefinition], accessibility: AccessibilityColors) {
        self.id = UUID().uuidString
        self.name = name
        self.version = version
        self.primary = primary
        self.secondary = secondary
        self.neutral = neutral
        self.semantic = semantic
        self.gradients = gradients
        self.accessibility = accessibility
    }
}

// MARK: - Color Palette
struct ColorPalette: Codable {
    let name: String
    let colors: [ColorDefinition]
    let usage: String
    
    init(name: String, colors: [ColorDefinition], usage: String) {
        self.name = name
        self.colors = colors
        self.usage = usage
    }
}

// MARK: - Color Definition
struct ColorDefinition: Identifiable, Codable {
    let id: String
    let name: String
    let hex: String
    let rgb: String
    let hsl: String
    let alpha: Double
    let usage: String
    let accessibility: ColorAccessibility
    
    init(name: String, hex: String, rgb: String, hsl: String, alpha: Double = 1.0, usage: String, accessibility: ColorAccessibility) {
        self.id = UUID().uuidString
        self.name = name
        self.hex = hex
        self.rgb = rgb
        self.hsl = hsl
        self.alpha = alpha
        self.usage = usage
        self.accessibility = accessibility
    }
}

// MARK: - Color Accessibility
struct ColorAccessibility: Codable {
    let contrastRatio: Double
    let wcagLevel: WCAGLevel
    let recommendations: [String]
    
    init(contrastRatio: Double, wcagLevel: WCAGLevel, recommendations: [String]) {
        self.contrastRatio = contrastRatio
        self.wcagLevel = wcagLevel
        self.recommendations = recommendations
    }
}

// MARK: - Gradient Definition
struct GradientDefinition: Identifiable, Codable {
    let id: String
    let name: String
    let colors: [String]
    let direction: GradientDirection
    let stops: [Double]
    let usage: String
    
    init(name: String, colors: [String], direction: GradientDirection, stops: [Double], usage: String) {
        self.id = UUID().uuidString
        self.name = name
        self.colors = colors
        self.direction = direction
        self.stops = stops
        self.usage = usage
    }
}

// MARK: - Accessibility Colors
struct AccessibilityColors: Codable {
    let highContrast: [String]
    let colorBlindFriendly: [String]
    let darkMode: [String]
    let lightMode: [String]
    
    init(highContrast: [String], colorBlindFriendly: [String], darkMode: [String], lightMode: [String]) {
        self.highContrast = highContrast
        self.colorBlindFriendly = colorBlindFriendly
        self.darkMode = darkMode
        self.lightMode = lightMode
    }
}

// MARK: - Typography System
struct TypographySystem: Identifiable, Codable {
    let id: String
    let name: String
    let version: String
    let fonts: [FontDefinition]
    let scales: [TypeScale]
    let weights: [FontWeight]
    let lineHeights: [LineHeight]
    let letterSpacing: [LetterSpacing]
    
    init(name: String, version: String, fonts: [FontDefinition], scales: [TypeScale], weights: [FontWeight], lineHeights: [LineHeight], letterSpacing: [LetterSpacing]) {
        self.id = UUID().uuidString
        self.name = name
        self.version = version
        self.fonts = fonts
        self.scales = scales
        self.weights = weights
        self.lineHeights = lineHeights
        self.letterSpacing = letterSpacing
    }
}

// MARK: - Font Definition
struct FontDefinition: Identifiable, Codable {
    let id: String
    let name: String
    let family: String
    let style: FontStyle
    let weight: String
    let size: Double
    let usage: String
    
    init(name: String, family: String, style: FontStyle, weight: String, size: Double, usage: String) {
        self.id = UUID().uuidString
        self.name = name
        self.family = family
        self.style = style
        self.weight = weight
        self.size = size
        self.usage = usage
    }
}

// MARK: - Type Scale
struct TypeScale: Identifiable, Codable {
    let id: String
    let name: String
    let size: Double
    let ratio: Double
    let usage: String
    
    init(name: String, size: Double, ratio: Double, usage: String) {
        self.id = UUID().uuidString
        self.name = name
        self.size = size
        self.ratio = ratio
        self.usage = usage
    }
}

// MARK: - Font Weight
struct FontWeight: Identifiable, Codable {
    let id: String
    let name: String
    let weight: String
    let value: Int
    let usage: String
    
    init(name: String, weight: String, value: Int, usage: String) {
        self.id = UUID().uuidString
        self.name = name
        self.weight = weight
        self.value = value
        self.usage = usage
    }
}

// MARK: - Line Height
struct LineHeight: Identifiable, Codable {
    let id: String
    let name: String
    let height: Double
    let unit: LineHeightUnit
    let usage: String
    
    init(name: String, height: Double, unit: LineHeightUnit, usage: String) {
        self.id = UUID().uuidString
        self.name = name
        self.height = height
        self.unit = unit
        self.usage = usage
    }
}

// MARK: - Letter Spacing
struct LetterSpacing: Identifiable, Codable {
    let id: String
    let name: String
    let spacing: Double
    let usage: String
    
    init(name: String, spacing: Double, usage: String) {
        self.id = UUID().uuidString
        self.name = name
        self.spacing = spacing
        self.usage = usage
    }
}

// MARK: - Layout System
struct LayoutSystem: Identifiable, Codable {
    let id: String
    let name: String
    let version: String
    let grids: [GridSystem]
    let spacing: SpacingSystem
    let breakpoints: [Breakpoint]
    let containers: [Container]
    
    init(name: String, version: String, grids: [GridSystem], spacing: SpacingSystem, breakpoints: [Breakpoint], containers: [Container]) {
        self.id = UUID().uuidString
        self.name = name
        self.version = version
        self.grids = grids
        self.spacing = spacing
        self.breakpoints = breakpoints
        self.containers = containers
    }
}

// MARK: - Grid System
struct GridSystem: Identifiable, Codable {
    let id: String
    let name: String
    let columns: Int
    let gutter: Double
    let margin: Double
    let usage: String
    
    init(name: String, columns: Int, gutter: Double, margin: Double, usage: String) {
        self.id = UUID().uuidString
        self.name = name
        self.columns = columns
        self.gutter = gutter
        self.margin = margin
        self.usage = usage
    }
}

// MARK: - Spacing System
struct SpacingSystem: Codable {
    let base: Double
    let scale: [SpacingScale]
    let units: [SpacingUnit]
    
    init(base: Double, scale: [SpacingScale], units: [SpacingUnit]) {
        self.base = base
        self.scale = scale
        self.units = units
    }
}

// MARK: - Spacing Scale
struct SpacingScale: Identifiable, Codable {
    let id: String
    let name: String
    let value: Double
    let usage: String
    
    init(name: String, value: Double, usage: String) {
        self.id = UUID().uuidString
        self.name = name
        self.value = value
        self.usage = usage
    }
}

// MARK: - Spacing Unit
struct SpacingUnit: Identifiable, Codable {
    let id: String
    let name: String
    let value: Double
    let type: UnitType
    let usage: String
    
    init(name: String, value: Double, type: UnitType, usage: String) {
        self.id = UUID().uuidString
        self.name = name
        self.value = value
        self.type = type
        self.usage = usage
    }
}

// MARK: - Breakpoint
struct Breakpoint: Identifiable, Codable {
    let id: String
    let name: String
    let width: Double
    let device: DeviceType
    let usage: String
    
    init(name: String, width: Double, device: DeviceType, usage: String) {
        self.id = UUID().uuidString
        self.name = name
        self.width = width
        self.device = device
        self.usage = usage
    }
}

// MARK: - Container
struct Container: Identifiable, Codable {
    let id: String
    let name: String
    let maxWidth: Double
    let padding: Double
    let usage: String
    
    init(name: String, maxWidth: Double, padding: Double, usage: String) {
        self.id = UUID().uuidString
        self.name = name
        self.maxWidth = maxWidth
        self.padding = padding
        self.usage = usage
    }
}

// MARK: - Visual Hierarchy
struct VisualHierarchy: Identifiable, Codable {
    let id: String
    let name: String
    let levels: [HierarchyLevel]
    let principles: [String]
    let guidelines: [String]
    
    init(name: String, levels: [HierarchyLevel], principles: [String], guidelines: [String]) {
        self.id = UUID().uuidString
        self.name = name
        self.levels = levels
        self.principles = principles
        self.guidelines = guidelines
    }
}

// MARK: - Hierarchy Level
struct HierarchyLevel: Identifiable, Codable {
    let id: String
    let name: String
    let importance: Int
    let characteristics: [String]
    let usage: String
    
    init(name: String, importance: Int, characteristics: [String], usage: String) {
        self.id = UUID().uuidString
        self.name = name
        self.importance = importance
        self.characteristics = characteristics
        self.usage = usage
    }
}

// MARK: - Design Pattern
struct DesignPattern: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: PatternCategory
    let components: [String]
    let examples: [String]
    let bestPractices: [String]
    
    init(name: String, description: String, category: PatternCategory, components: [String], examples: [String], bestPractices: [String]) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.category = category
        self.components = components
        self.examples = examples
        self.bestPractices = bestPractices
    }
}

// MARK: - Enums
enum WCAGLevel: String, Codable, CaseIterable {
    case a = "A"
    case aa = "AA"
    case aaa = "AAA"
}

enum GradientDirection: String, Codable, CaseIterable {
    case horizontal = "Horizontal"
    case vertical = "Vertical"
    case diagonal = "Diagonal"
    case radial = "Radial"
}

enum FontStyle: String, Codable, CaseIterable {
    case normal = "Normal"
    case italic = "Italic"
    case oblique = "Oblique"
}

enum LineHeightUnit: String, Codable, CaseIterable {
    case pixels = "px"
    case em = "em"
    case percentage = "%"
}

enum UnitType: String, Codable, CaseIterable {
    case pixels = "px"
    case points = "pt"
    case em = "em"
    case rem = "rem"
    case percentage = "%"
}

enum DeviceType: String, Codable, CaseIterable {
    case mobile = "Mobile"
    case tablet = "Tablet"
    case desktop = "Desktop"
    case watch = "Watch"
    case tv = "TV"
}

enum PatternCategory: String, Codable, CaseIterable {
    case navigation = "Navigation"
    case forms = "Forms"
    case feedback = "Feedback"
    case data = "Data"
    case layout = "Layout"
}

// MARK: - Visual Design System Implementation
actor VisualDesignSystem: VisualDesignSystemProtocol {
    private let colorGenerator = ColorGenerator()
    private let typographyGenerator = TypographyGenerator()
    private let layoutGenerator = LayoutGenerator()
    private let hierarchyGenerator = HierarchyGenerator()
    private let patternGenerator = PatternGenerator()
    private let logger = Logger(subsystem: "com.healthai2030.design", category: "VisualDesignSystem")
    
    func createColorSystem() async throws -> ColorSystem {
        logger.info("Creating color system")
        return try await colorGenerator.generate()
    }
    
    func createTypographySystem() async throws -> TypographySystem {
        logger.info("Creating typography system")
        return try await typographyGenerator.generate()
    }
    
    func createLayoutSystem() async throws -> LayoutSystem {
        logger.info("Creating layout system")
        return try await layoutGenerator.generate()
    }
    
    func createVisualHierarchy() async throws -> VisualHierarchy {
        logger.info("Creating visual hierarchy")
        return try await hierarchyGenerator.generate()
    }
    
    func createDesignPatterns() async throws -> [DesignPattern] {
        logger.info("Creating design patterns")
        return try await patternGenerator.generate()
    }
}

// MARK: - Color Generator
class ColorGenerator {
    func generate() async throws -> ColorSystem {
        let primary = ColorPalette(
            name: "Primary",
            colors: [
                ColorDefinition(
                    name: "Primary Blue",
                    hex: "#007AFF",
                    rgb: "0, 122, 255",
                    hsl: "211, 100%, 50%",
                    usage: "Primary actions and branding",
                    accessibility: ColorAccessibility(
                        contrastRatio: 4.5,
                        wcagLevel: .aa,
                        recommendations: ["Use on light backgrounds", "Ensure sufficient contrast"]
                    )
                ),
                ColorDefinition(
                    name: "Primary Green",
                    hex: "#34C759",
                    rgb: "52, 199, 89",
                    hsl: "142, 59%, 49%",
                    usage: "Success states and health indicators",
                    accessibility: ColorAccessibility(
                        contrastRatio: 4.2,
                        wcagLevel: .aa,
                        recommendations: ["Use on light backgrounds", "Test with color blind users"]
                    )
                )
            ],
            usage: "Primary brand colors for main actions and branding"
        )
        
        let secondary = ColorPalette(
            name: "Secondary",
            colors: [
                ColorDefinition(
                    name: "Secondary Orange",
                    hex: "#FF9500",
                    rgb: "255, 149, 0",
                    hsl: "35, 100%, 50%",
                    usage: "Warnings and highlights",
                    accessibility: ColorAccessibility(
                        contrastRatio: 3.8,
                        wcagLevel: .aa,
                        recommendations: ["Use sparingly", "Ensure sufficient contrast"]
                    )
                )
            ],
            usage: "Secondary colors for supporting elements"
        )
        
        let neutral = ColorPalette(
            name: "Neutral",
            colors: [
                ColorDefinition(
                    name: "Gray 100",
                    hex: "#F2F2F7",
                    rgb: "242, 242, 247",
                    hsl: "240, 5%, 96%",
                    usage: "Background colors",
                    accessibility: ColorAccessibility(
                        contrastRatio: 1.2,
                        wcagLevel: .a,
                        recommendations: ["Use for backgrounds only", "Not for text"]
                    )
                ),
                ColorDefinition(
                    name: "Gray 900",
                    hex: "#1C1C1E",
                    rgb: "28, 28, 30",
                    hsl: "240, 2%, 11%",
                    usage: "Text colors",
                    accessibility: ColorAccessibility(
                        contrastRatio: 15.0,
                        wcagLevel: .aaa,
                        recommendations: ["Excellent for text", "High contrast"]
                    )
                )
            ],
            usage: "Neutral colors for backgrounds and text"
        )
        
        let semantic = ColorPalette(
            name: "Semantic",
            colors: [
                ColorDefinition(
                    name: "Error Red",
                    hex: "#FF3B30",
                    rgb: "255, 59, 48",
                    hsl: "3, 100%, 59%",
                    usage: "Error states",
                    accessibility: ColorAccessibility(
                        contrastRatio: 4.8,
                        wcagLevel: .aa,
                        recommendations: ["Use for errors only", "Ensure sufficient contrast"]
                    )
                ),
                ColorDefinition(
                    name: "Success Green",
                    hex: "#34C759",
                    rgb: "52, 199, 89",
                    hsl: "142, 59%, 49%",
                    usage: "Success states",
                    accessibility: ColorAccessibility(
                        contrastRatio: 4.2,
                        wcagLevel: .aa,
                        recommendations: ["Use for success states", "Test with color blind users"]
                    )
                )
            ],
            usage: "Semantic colors for status and feedback"
        )
        
        let gradients = [
            GradientDefinition(
                name: "Primary Gradient",
                colors: ["#007AFF", "#34C759"],
                direction: .horizontal,
                stops: [0.0, 1.0],
                usage: "Primary gradient for hero sections"
            ),
            GradientDefinition(
                name: "Health Gradient",
                colors: ["#FF3B30", "#FF9500", "#34C759"],
                direction: .horizontal,
                stops: [0.0, 0.5, 1.0],
                usage: "Health status gradient"
            )
        ]
        
        let accessibility = AccessibilityColors(
            highContrast: ["#000000", "#FFFFFF", "#007AFF"],
            colorBlindFriendly: ["#007AFF", "#FF9500", "#34C759"],
            darkMode: ["#1C1C1E", "#2C2C2E", "#3A3A3C"],
            lightMode: ["#FFFFFF", "#F2F2F7", "#E5E5EA"]
        )
        
        return ColorSystem(
            name: "HealthAI-2030 Color System",
            version: "1.0.0",
            primary: primary,
            secondary: secondary,
            neutral: neutral,
            semantic: semantic,
            gradients: gradients,
            accessibility: accessibility
        )
    }
}

// MARK: - Typography Generator
class TypographyGenerator {
    func generate() async throws -> TypographySystem {
        let fonts = [
            FontDefinition(
                name: "Large Title",
                family: "SF Pro Display",
                style: .normal,
                weight: "Bold",
                size: 34,
                usage: "Main headings and page titles"
            ),
            FontDefinition(
                name: "Title 1",
                family: "SF Pro Display",
                style: .normal,
                weight: "Bold",
                size: 28,
                usage: "Section headings"
            ),
            FontDefinition(
                name: "Title 2",
                family: "SF Pro Display",
                style: .normal,
                weight: "Semibold",
                size: 22,
                usage: "Subsection headings"
            ),
            FontDefinition(
                name: "Body",
                family: "SF Pro Text",
                style: .normal,
                weight: "Regular",
                size: 17,
                usage: "Body text and content"
            ),
            FontDefinition(
                name: "Caption",
                family: "SF Pro Text",
                style: .normal,
                weight: "Regular",
                size: 12,
                usage: "Captions and small text"
            )
        ]
        
        let scales = [
            TypeScale(name: "Large Title", size: 34, ratio: 1.0, usage: "Main headings"),
            TypeScale(name: "Title 1", size: 28, ratio: 1.2, usage: "Section headings"),
            TypeScale(name: "Title 2", size: 22, ratio: 1.3, usage: "Subsection headings"),
            TypeScale(name: "Body", size: 17, ratio: 1.4, usage: "Body text"),
            TypeScale(name: "Caption", size: 12, ratio: 1.5, usage: "Small text")
        ]
        
        let weights = [
            FontWeight(name: "Regular", weight: "Regular", value: 400, usage: "Body text"),
            FontWeight(name: "Medium", weight: "Medium", value: 500, usage: "Emphasis"),
            FontWeight(name: "Semibold", weight: "Semibold", value: 600, usage: "Headings"),
            FontWeight(name: "Bold", weight: "Bold", value: 700, usage: "Strong emphasis")
        ]
        
        let lineHeights = [
            LineHeight(name: "Tight", height: 1.2, unit: .em, usage: "Headings"),
            LineHeight(name: "Normal", height: 1.4, unit: .em, usage: "Body text"),
            LineHeight(name: "Relaxed", height: 1.6, unit: .em, usage: "Long content")
        ]
        
        let letterSpacing = [
            LetterSpacing(name: "Tight", spacing: -0.5, usage: "Headings"),
            LetterSpacing(name: "Normal", spacing: 0.0, usage: "Body text"),
            LetterSpacing(name: "Wide", spacing: 1.0, usage: "Display text")
        ]
        
        return TypographySystem(
            name: "HealthAI-2030 Typography System",
            version: "1.0.0",
            fonts: fonts,
            scales: scales,
            weights: weights,
            lineHeights: lineHeights,
            letterSpacing: letterSpacing
        )
    }
}

// MARK: - Layout Generator
class LayoutGenerator {
    func generate() async throws -> LayoutSystem {
        let grids = [
            GridSystem(name: "Mobile Grid", columns: 4, gutter: 16, margin: 16, usage: "Mobile layouts"),
            GridSystem(name: "Tablet Grid", columns: 8, gutter: 24, margin: 24, usage: "Tablet layouts"),
            GridSystem(name: "Desktop Grid", columns: 12, gutter: 32, margin: 32, usage: "Desktop layouts")
        ]
        
        let spacing = SpacingSystem(
            base: 8,
            scale: [
                SpacingScale(name: "XS", value: 4, usage: "Tight spacing"),
                SpacingScale(name: "S", value: 8, usage: "Standard spacing"),
                SpacingScale(name: "M", value: 16, usage: "Medium spacing"),
                SpacingScale(name: "L", value: 24, usage: "Large spacing"),
                SpacingScale(name: "XL", value: 32, usage: "Extra large spacing")
            ],
            units: [
                SpacingUnit(name: "Base Unit", value: 8, type: .pixels, usage: "Base spacing unit"),
                SpacingUnit(name: "Component Spacing", value: 16, type: .pixels, usage: "Component spacing"),
                SpacingUnit(name: "Section Spacing", value: 32, type: .pixels, usage: "Section spacing")
            ]
        )
        
        let breakpoints = [
            Breakpoint(name: "Mobile", width: 375, device: .mobile, usage: "iPhone and small devices"),
            Breakpoint(name: "Tablet", width: 768, device: .tablet, usage: "iPad and medium devices"),
            Breakpoint(name: "Desktop", width: 1024, device: .desktop, usage: "Desktop and large devices")
        ]
        
        let containers = [
            Container(name: "Small", maxWidth: 640, padding: 16, usage: "Small content containers"),
            Container(name: "Medium", maxWidth: 1024, padding: 24, usage: "Medium content containers"),
            Container(name: "Large", maxWidth: 1440, padding: 32, usage: "Large content containers")
        ]
        
        return LayoutSystem(
            name: "HealthAI-2030 Layout System",
            version: "1.0.0",
            grids: grids,
            spacing: spacing,
            breakpoints: breakpoints,
            containers: containers
        )
    }
}

// MARK: - Hierarchy Generator
class HierarchyGenerator {
    func generate() async throws -> VisualHierarchy {
        let levels = [
            HierarchyLevel(
                name: "Primary",
                importance: 1,
                characteristics: ["Largest size", "Boldest weight", "Highest contrast"],
                usage: "Main headings and primary actions"
            ),
            HierarchyLevel(
                name: "Secondary",
                importance: 2,
                characteristics: ["Medium size", "Medium weight", "Good contrast"],
                usage: "Section headings and secondary actions"
            ),
            HierarchyLevel(
                name: "Tertiary",
                importance: 3,
                characteristics: ["Smaller size", "Regular weight", "Standard contrast"],
                usage: "Subsection headings and body text"
            ),
            HierarchyLevel(
                name: "Quaternary",
                importance: 4,
                characteristics: ["Smallest size", "Light weight", "Lower contrast"],
                usage: "Captions and supporting text"
            )
        ]
        
        let principles = [
            "Use size to establish hierarchy",
            "Use weight to emphasize importance",
            "Use color to guide attention",
            "Use spacing to group related elements",
            "Use contrast to ensure readability"
        ]
        
        let guidelines = [
            "Start with the most important element",
            "Use consistent hierarchy patterns",
            "Test hierarchy with users",
            "Consider accessibility requirements",
            "Maintain hierarchy across platforms"
        ]
        
        return VisualHierarchy(
            name: "HealthAI-2030 Visual Hierarchy",
            levels: levels,
            principles: principles,
            guidelines: guidelines
        )
    }
}

// MARK: - Pattern Generator
class PatternGenerator {
    func generate() async throws -> [DesignPattern] {
        return [
            DesignPattern(
                name: "Card Layout",
                description: "Content organized in card containers",
                category: .layout,
                components: ["Card", "Header", "Content", "Footer"],
                examples: ["Health metrics card", "Activity summary card"],
                bestPractices: ["Use consistent spacing", "Maintain visual hierarchy", "Ensure accessibility"]
            ),
            DesignPattern(
                name: "Progressive Disclosure",
                description: "Show information progressively to avoid overwhelming users",
                category: .navigation,
                components: ["Expandable sections", "Collapsible content", "Progressive forms"],
                examples: ["Multi-step forms", "Expandable details", "Progressive onboarding"],
                bestPractices: ["Start with essential information", "Provide clear navigation", "Maintain context"]
            ),
            DesignPattern(
                name: "Status Feedback",
                description: "Provide clear feedback for user actions",
                category: .feedback,
                components: ["Success messages", "Error messages", "Loading states"],
                examples: ["Form submission feedback", "Data sync status", "Network status"],
                bestPractices: ["Be specific and helpful", "Use appropriate colors", "Provide next steps"]
            )
        ]
    }
}

// MARK: - SwiftUI Views for Visual Design System
struct VisualDesignSystemView: View {
    @State private var colorSystem: ColorSystem?
    @State private var typographySystem: TypographySystem?
    @State private var layoutSystem: LayoutSystem?
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ColorSystemView(colorSystem: $colorSystem)
                .tabItem {
                    Image(systemName: "paintpalette")
                    Text("Colors")
                }
                .tag(0)
            
            TypographySystemView(typographySystem: $typographySystem)
                .tabItem {
                    Image(systemName: "textformat")
                    Text("Typography")
                }
                .tag(1)
            
            LayoutSystemView(layoutSystem: $layoutSystem)
                .tabItem {
                    Image(systemName: "square.grid.3x3")
                    Text("Layout")
                }
                .tag(2)
        }
        .navigationTitle("Visual Design System")
        .onAppear {
            loadDesignSystems()
        }
    }
    
    private func loadDesignSystems() {
        // Load design systems
    }
}

struct ColorSystemView: View {
    @Binding var colorSystem: ColorSystem?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let colors = colorSystem {
                    ForEach([colors.primary, colors.secondary, colors.neutral, colors.semantic], id: \.name) { palette in
                        ColorPaletteView(palette: palette)
                    }
                } else {
                    ProgressView("Loading color system...")
                }
            }
            .padding()
        }
    }
}

struct ColorPaletteView: View {
    let palette: ColorPalette
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(palette.name)
                .font(.headline)
            
            Text(palette.usage)
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(palette.colors) { color in
                    ColorCard(color: color)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ColorCard: View {
    let color: ColorDefinition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Rectangle()
                .fill(Color(hex: color.hex))
                .frame(height: 40)
                .cornerRadius(4)
            
            Text(color.name)
                .font(.caption.bold())
            
            Text(color.hex)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct TypographySystemView: View {
    @Binding var typographySystem: TypographySystem?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let typography = typographySystem {
                    ForEach(typography.fonts) { font in
                        TypographyCard(font: font)
                    }
                } else {
                    ProgressView("Loading typography system...")
                }
            }
            .padding()
        }
    }
}

struct TypographyCard: View {
    let font: FontDefinition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(font.name)
                .font(.system(size: font.size, weight: .bold))
            
            Text("\(font.family) \(font.weight) \(String(format: "%.0f", font.size))pt")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(font.usage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct LayoutSystemView: View {
    @Binding var layoutSystem: LayoutSystem?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let layout = layoutSystem {
                    ForEach(layout.grids) { grid in
                        GridSystemCard(grid: grid)
                    }
                } else {
                    ProgressView("Loading layout system...")
                }
            }
            .padding()
        }
    }
}

struct GridSystemCard: View {
    let grid: GridSystem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(grid.name)
                .font(.headline)
            
            Text("\(grid.columns) columns • \(String(format: "%.0f", grid.gutter))px gutter • \(String(format: "%.0f", grid.margin))px margin")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(grid.usage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
struct VisualDesignSystem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VisualDesignSystemView()
        }
        .previewDevice("iPhone 15 Pro")
    }
} 