import SwiftUI

// MARK: - Interactive Body Maps
/// Comprehensive interactive body mapping components for HealthAI 2030
/// Provides interactive body maps for health data visualization and education
public struct InteractiveBodyMaps {
    
    // MARK: - Interactive Human Body Map
    
    /// Interactive human body map with touchable regions
    public struct InteractiveHumanBodyMap: View {
        let bodyData: [BodyRegion: HealthData]
        let selectedRegion: BodyRegion?
        let onRegionTap: (BodyRegion) -> Void
        @State private var hoveredRegion: BodyRegion?
        
        public init(
            bodyData: [BodyRegion: HealthData],
            selectedRegion: BodyRegion? = nil,
            onRegionTap: @escaping (BodyRegion) -> Void
        ) {
            self.bodyData = bodyData
            self.selectedRegion = selectedRegion
            self.onRegionTap = onRegionTap
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Body map canvas
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 400)
                    
                    // Body outline
                    BodyOutline()
                        .stroke(Color.primary, lineWidth: 2)
                        .frame(height: 400)
                    
                    // Interactive regions
                    ForEach(BodyRegion.allCases, id: \.self) { region in
                        BodyRegionShape(region: region)
                            .fill(regionColor(for: region))
                            .opacity(regionOpacity(for: region))
                            .scaleEffect(selectedRegion == region ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: selectedRegion)
                            .onTapGesture {
                                onRegionTap(region)
                            }
                            .onHover { isHovered in
                                hoveredRegion = isHovered ? region : nil
                            }
                    }
                    
                    // Data overlays
                    ForEach(BodyRegion.allCases, id: \.self) { region in
                        if let data = bodyData[region] {
                            BodyDataOverlay(region: region, data: data)
                                .opacity(selectedRegion == region ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 0.3), value: selectedRegion)
                        }
                    }
                }
                .frame(height: 400)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Region legend
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(BodyRegion.allCases, id: \.self) { region in
                            Button(action: { onRegionTap(region) }) {
                                VStack(spacing: 4) {
                                    Image(systemName: region.icon)
                                        .font(.title2)
                                        .foregroundColor(selectedRegion == region ? .blue : .secondary)
                                    Text(region.name)
                                        .font(.caption)
                                        .foregroundColor(selectedRegion == region ? .blue : .secondary)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedRegion == region ? Color.blue.opacity(0.1) : Color.clear)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        
        private func regionColor(for region: BodyRegion) -> Color {
            guard let data = bodyData[region] else { return .clear }
            
            switch data.status {
            case .normal:
                return .green.opacity(0.3)
            case .warning:
                return .orange.opacity(0.3)
            case .alert:
                return .red.opacity(0.3)
            case .info:
                return .blue.opacity(0.3)
            }
        }
        
        private func regionOpacity(for region: BodyRegion) -> Double {
            if selectedRegion == region || hoveredRegion == region {
                return 0.8
            }
            return bodyData[region] != nil ? 0.6 : 0.0
        }
    }
    
    // MARK: - Anatomical Body Map
    
    /// Detailed anatomical body map with organ systems
    public struct AnatomicalBodyMap: View {
        let organSystems: [OrganSystem: OrganData]
        let selectedSystem: OrganSystem?
        let onSystemTap: (OrganSystem) -> Void
        
        public init(
            organSystems: [OrganSystem: OrganData],
            selectedSystem: OrganSystem? = nil,
            onSystemTap: @escaping (OrganSystem) -> Void
        ) {
            self.organSystems = organSystems
            self.selectedSystem = selectedSystem
            self.onSystemTap = onSystemTap
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Anatomical map canvas
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 400)
                    
                    // Body outline
                    BodyOutline()
                        .stroke(Color.primary, lineWidth: 2)
                        .frame(height: 400)
                    
                    // Organ systems
                    ForEach(OrganSystem.allCases, id: \.self) { system in
                        OrganSystemShape(system: system)
                            .fill(systemColor(for: system))
                            .opacity(systemOpacity(for: system))
                            .scaleEffect(selectedSystem == system ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: selectedSystem)
                            .onTapGesture {
                                onSystemTap(system)
                            }
                    }
                    
                    // System overlays
                    ForEach(OrganSystem.allCases, id: \.self) { system in
                        if let data = organSystems[system] {
                            OrganSystemOverlay(system: system, data: data)
                                .opacity(selectedSystem == system ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 0.3), value: selectedSystem)
                        }
                    }
                }
                .frame(height: 400)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // System legend
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(OrganSystem.allCases, id: \.self) { system in
                        Button(action: { onSystemTap(system) }) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(systemColor(for: system))
                                    .frame(width: 12, height: 12)
                                Text(system.name)
                                    .font(.caption)
                                    .foregroundColor(selectedSystem == system ? .blue : .primary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedSystem == system ? Color.blue.opacity(0.1) : Color.clear)
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        
        private func systemColor(for system: OrganSystem) -> Color {
            guard let data = organSystems[system] else { return .clear }
            
            switch data.status {
            case .normal:
                return .green.opacity(0.4)
            case .warning:
                return .orange.opacity(0.4)
            case .alert:
                return .red.opacity(0.4)
            case .info:
                return .blue.opacity(0.4)
            }
        }
        
        private func systemOpacity(for system: OrganSystem) -> Double {
            return selectedSystem == system ? 0.8 : (organSystems[system] != nil ? 0.6 : 0.0)
        }
    }
    
    // MARK: - Pain Mapping
    
    /// Interactive pain mapping for symptom tracking
    public struct PainMapping: View {
        let painPoints: [PainPoint]
        let onPainPointTap: (PainPoint) -> Void
        let onAddPainPoint: (CGPoint) -> Void
        
        public init(
            painPoints: [PainPoint],
            onPainPointTap: @escaping (PainPoint) -> Void,
            onAddPainPoint: @escaping (CGPoint) -> Void
        ) {
            self.painPoints = painPoints
            self.onPainPointTap = onPainPointTap
            self.onAddPainPoint = onAddPainPoint
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Pain map canvas
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 400)
                    
                    // Body outline
                    BodyOutline()
                        .stroke(Color.primary, lineWidth: 2)
                        .frame(height: 400)
                    
                    // Pain points
                    ForEach(painPoints, id: \.id) { painPoint in
                        PainPointMarker(painPoint: painPoint)
                            .onTapGesture {
                                onPainPointTap(painPoint)
                            }
                    }
                }
                .frame(height: 400)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .onTapGesture { location in
                    onAddPainPoint(location)
                }
                
                // Pain intensity legend
                HStack(spacing: 16) {
                    ForEach(PainIntensity.allCases, id: \.self) { intensity in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(intensity.color)
                                .frame(width: 12, height: 12)
                            Text(intensity.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Injury Mapping
    
    /// Interactive injury mapping for medical documentation
    public struct InjuryMapping: View {
        let injuries: [Injury]
        let onInjuryTap: (Injury) -> Void
        let onAddInjury: (InjuryType, CGPoint) -> Void
        
        public init(
            injuries: [Injury],
            onInjuryTap: @escaping (Injury) -> Void,
            onAddInjury: @escaping (InjuryType, CGPoint) -> Void
        ) {
            self.injuries = injuries
            self.onInjuryTap = onInjuryTap
            self.onAddInjury = onAddInjury
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Injury map canvas
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 400)
                    
                    // Body outline
                    BodyOutline()
                        .stroke(Color.primary, lineWidth: 2)
                        .frame(height: 400)
                    
                    // Injuries
                    ForEach(injuries, id: \.id) { injury in
                        InjuryMarker(injury: injury)
                            .onTapGesture {
                                onInjuryTap(injury)
                            }
                    }
                }
                .frame(height: 400)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Injury type selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(InjuryType.allCases, id: \.self) { type in
                            Button(action: {}) {
                                HStack(spacing: 4) {
                                    Image(systemName: type.icon)
                                        .font(.caption)
                                    Text(type.name)
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(type.color)
                                .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Supporting Views

/// Body outline shape
private struct BodyOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Simplified human body outline
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.1)) // Head
        path.addEllipse(in: CGRect(x: width * 0.4, y: height * 0.05, width: width * 0.2, height: height * 0.15))
        
        // Neck
        path.move(to: CGPoint(x: width * 0.45, y: height * 0.2))
        path.addLine(to: CGPoint(x: width * 0.55, y: height * 0.2))
        
        // Torso
        path.move(to: CGPoint(x: width * 0.35, y: height * 0.2))
        path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.2))
        path.addLine(to: CGPoint(x: width * 0.7, y: height * 0.6))
        path.addLine(to: CGPoint(x: width * 0.3, y: height * 0.6))
        path.closeSubpath()
        
        // Arms
        path.move(to: CGPoint(x: width * 0.35, y: height * 0.25))
        path.addLine(to: CGPoint(x: width * 0.2, y: height * 0.4))
        path.move(to: CGPoint(x: width * 0.65, y: height * 0.25))
        path.addLine(to: CGPoint(x: width * 0.8, y: height * 0.4))
        
        // Legs
        path.move(to: CGPoint(x: width * 0.4, y: height * 0.6))
        path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.9))
        path.move(to: CGPoint(x: width * 0.6, y: height * 0.6))
        path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.9))
        
        return path
    }
}

/// Body region shape
private struct BodyRegionShape: Shape {
    let region: BodyRegion
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        switch region {
        case .head:
            path.addEllipse(in: CGRect(x: width * 0.4, y: height * 0.05, width: width * 0.2, height: height * 0.15))
        case .chest:
            path.addRect(CGRect(x: width * 0.35, y: height * 0.2, width: width * 0.3, height: height * 0.2))
        case .abdomen:
            path.addRect(CGRect(x: width * 0.35, y: height * 0.4, width: width * 0.3, height: height * 0.2))
        case .arms:
            path.addRect(CGRect(x: width * 0.15, y: height * 0.25, width: width * 0.1, height: height * 0.2))
            path.addRect(CGRect(x: width * 0.75, y: height * 0.25, width: width * 0.1, height: height * 0.2))
        case .legs:
            path.addRect(CGRect(x: width * 0.35, y: height * 0.6, width: width * 0.1, height: height * 0.3))
            path.addRect(CGRect(x: width * 0.55, y: height * 0.6, width: width * 0.1, height: height * 0.3))
        }
        
        return path
    }
}

/// Body data overlay
private struct BodyDataOverlay: View {
    let region: BodyRegion
    let data: HealthData
    
    var body: some View {
        VStack(spacing: 4) {
            Text(region.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(data.value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(data.unit)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
        .position(regionOverlayPosition(for: region))
    }
    
    private func regionOverlayPosition(for region: BodyRegion) -> CGPoint {
        switch region {
        case .head:
            return CGPoint(x: 200, y: 80)
        case .chest:
            return CGPoint(x: 200, y: 150)
        case .abdomen:
            return CGPoint(x: 200, y: 220)
        case .arms:
            return CGPoint(x: 200, y: 180)
        case .legs:
            return CGPoint(x: 200, y: 320)
        }
    }
}

/// Organ system shape
private struct OrganSystemShape: Shape {
    let system: OrganSystem
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        switch system {
        case .cardiovascular:
            // Heart and blood vessels
            path.addEllipse(in: CGRect(x: width * 0.4, y: height * 0.25, width: width * 0.2, height: height * 0.15))
        case .respiratory:
            // Lungs
            path.addEllipse(in: CGRect(x: width * 0.3, y: height * 0.3, width: width * 0.15, height: height * 0.2))
            path.addEllipse(in: CGRect(x: width * 0.55, y: height * 0.3, width: width * 0.15, height: height * 0.2))
        case .digestive:
            // Stomach and intestines
            path.addEllipse(in: CGRect(x: width * 0.35, y: height * 0.4, width: width * 0.3, height: height * 0.2))
        case .nervous:
            // Brain and spine
            path.addEllipse(in: CGRect(x: width * 0.4, y: height * 0.05, width: width * 0.2, height: height * 0.15))
            path.addRect(CGRect(x: width * 0.48, y: height * 0.2, width: width * 0.04, height: height * 0.4))
        case .musculoskeletal:
            // Bones and muscles
            path.addRect(CGRect(x: width * 0.35, y: height * 0.2, width: width * 0.3, height: height * 0.6))
        }
        
        return path
    }
}

/// Organ system overlay
private struct OrganSystemOverlay: View {
    let system: OrganSystem
    let data: OrganData
    
    var body: some View {
        VStack(spacing: 4) {
            Text(system.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(data.status.description)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
        .position(systemOverlayPosition(for: system))
    }
    
    private func systemOverlayPosition(for system: OrganSystem) -> CGPoint {
        switch system {
        case .cardiovascular:
            return CGPoint(x: 200, y: 150)
        case .respiratory:
            return CGPoint(x: 200, y: 200)
        case .digestive:
            return CGPoint(x: 200, y: 250)
        case .nervous:
            return CGPoint(x: 200, y: 100)
        case .musculoskeletal:
            return CGPoint(x: 200, y: 300)
        }
    }
}

/// Pain point marker
private struct PainPointMarker: View {
    let painPoint: PainPoint
    
    var body: some View {
        Circle()
            .fill(painPoint.intensity.color)
            .frame(width: 20, height: 20)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
            .position(painPoint.position)
    }
}

/// Injury marker
private struct InjuryMarker: View {
    let injury: Injury
    
    var body: some View {
        Image(systemName: injury.type.icon)
            .font(.title2)
            .foregroundColor(injury.type.color)
            .background(
                Circle()
                    .fill(Color.white)
                    .frame(width: 30, height: 30)
            )
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
            .position(injury.position)
    }
}

// MARK: - Supporting Types

/// Body region for mapping
public enum BodyRegion: String, CaseIterable {
    case head = "Head"
    case chest = "Chest"
    case abdomen = "Abdomen"
    case arms = "Arms"
    case legs = "Legs"
    
    var name: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .head:
            return "brain.head.profile"
        case .chest:
            return "heart.fill"
        case .abdomen:
            return "circle.fill"
        case .arms:
            return "figure.walk"
        case .legs:
            return "figure.walk"
        }
    }
}

/// Health data for body regions
public struct HealthData {
    let value: String
    let unit: String
    let status: HealthStatus
    let timestamp: Date
    
    public init(value: String, unit: String, status: HealthStatus, timestamp: Date = Date()) {
        self.value = value
        self.unit = unit
        self.status = status
        self.timestamp = timestamp
    }
}

/// Health status
public enum HealthStatus {
    case normal
    case warning
    case alert
    case info
}

/// Organ system
public enum OrganSystem: String, CaseIterable {
    case cardiovascular = "Cardiovascular"
    case respiratory = "Respiratory"
    case digestive = "Digestive"
    case nervous = "Nervous"
    case musculoskeletal = "Musculoskeletal"
    
    var name: String {
        return rawValue
    }
}

/// Organ data
public struct OrganData {
    let status: HealthStatus
    let description: String
    let timestamp: Date
    
    public init(status: HealthStatus, description: String, timestamp: Date = Date()) {
        self.status = status
        self.description = description
        self.timestamp = timestamp
    }
}

/// Pain point
public struct PainPoint: Identifiable {
    public let id = UUID()
    public let position: CGPoint
    public let intensity: PainIntensity
    public let description: String
    public let timestamp: Date
    
    public init(position: CGPoint, intensity: PainIntensity, description: String, timestamp: Date = Date()) {
        self.position = position
        self.intensity = intensity
        self.description = description
        self.timestamp = timestamp
    }
}

/// Pain intensity
public enum PainIntensity: Int, CaseIterable {
    case mild = 1
    case moderate = 2
    case severe = 3
    case extreme = 4
    
    var description: String {
        switch self {
        case .mild:
            return "Mild"
        case .moderate:
            return "Moderate"
        case .severe:
            return "Severe"
        case .extreme:
            return "Extreme"
        }
    }
    
    var color: Color {
        switch self {
        case .mild:
            return .green
        case .moderate:
            return .yellow
        case .severe:
            return .orange
        case .extreme:
            return .red
        }
    }
}

/// Injury
public struct Injury: Identifiable {
    public let id = UUID()
    public let type: InjuryType
    public let position: CGPoint
    public let description: String
    public let timestamp: Date
    
    public init(type: InjuryType, position: CGPoint, description: String, timestamp: Date = Date()) {
        self.type = type
        self.position = position
        self.description = description
        self.timestamp = timestamp
    }
}

/// Injury type
public enum InjuryType: String, CaseIterable {
    case bruise = "Bruise"
    case cut = "Cut"
    case fracture = "Fracture"
    case sprain = "Sprain"
    case burn = "Burn"
    
    var name: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .bruise:
            return "circle.fill"
        case .cut:
            return "scissors"
        case .fracture:
            return "bolt.fill"
        case .sprain:
            return "arrow.up.and.down"
        case .burn:
            return "flame.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .bruise:
            return .purple
        case .cut:
            return .red
        case .fracture:
            return .orange
        case .sprain:
            return .yellow
        case .burn:
            return .red
        }
    }
}

// MARK: - Extensions

public extension InteractiveBodyMaps {
    /// Create default body data
    static func defaultBodyData() -> [BodyRegion: HealthData] {
        return [
            .head: HealthData(value: "98.6", unit: "°F", status: .normal),
            .chest: HealthData(value: "72", unit: "BPM", status: .normal),
            .abdomen: HealthData(value: "22.5", unit: "BMI", status: .normal),
            .arms: HealthData(value: "120/80", unit: "mmHg", status: .normal),
            .legs: HealthData(value: "8,500", unit: "steps", status: .normal)
        ]
    }
    
    /// Create default organ systems data
    static func defaultOrganSystems() -> [OrganSystem: OrganData] {
        return [
            .cardiovascular: OrganData(status: .normal, description: "Heart rate normal"),
            .respiratory: OrganData(status: .normal, description: "Breathing normal"),
            .digestive: OrganData(status: .normal, description: "Digestion normal"),
            .nervous: OrganData(status: .normal, description: "Brain activity normal"),
            .musculoskeletal: OrganData(status: .normal, description: "Muscles and bones healthy")
        ]
    }
} 