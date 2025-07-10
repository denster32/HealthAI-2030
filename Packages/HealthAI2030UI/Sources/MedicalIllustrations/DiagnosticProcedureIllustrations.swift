import SwiftUI

// MARK: - Diagnostic Procedure Illustrations
/// Comprehensive diagnostic procedure illustrations for medical imaging and diagnostic techniques
/// Provides detailed visual guides for various diagnostic procedures and medical imaging
public struct DiagnosticProcedureIllustrations {
    
    // MARK: - X-Ray Illustrations
    
    /// X-ray procedure illustration
    public struct XRayIllustration: View {
        let bodyPart: XRayBodyPart
        let showingEquipment: Bool
        @State private var showingImage: Bool = false
        
        public init(
            bodyPart: XRayBodyPart = .chest,
            showingEquipment: Bool = false
        ) {
            self.bodyPart = bodyPart
            self.showingEquipment = showingEquipment
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Procedure Title
                Text("\(bodyPart.displayName) X-Ray")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Equipment Toggle
                Toggle("Show Equipment", isOn: $showingEquipment)
                    .padding(.horizontal)
                
                // X-Ray Setup
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    XRaySetupView(
                        bodyPart: bodyPart,
                        showingEquipment: showingEquipment,
                        showingImage: showingImage
                    )
                    .frame(height: 280)
                }
                
                // Image Toggle
                Button(action: { showingImage.toggle() }) {
                    HStack(spacing: 8) {
                        Image(systemName: showingImage ? "eye.slash" : "eye")
                        Text(showingImage ? "Hide X-Ray" : "Show X-Ray")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                
                // Procedure Information
                XRayInfoView(bodyPart: bodyPart)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - MRI Illustrations
    
    /// MRI procedure illustration
    public struct MRIIllustration: View {
        let bodyPart: MRIBodyPart
        let scanType: MRIScanType
        @State private var showingScan: Bool = false
        @State private var scanProgress: Double = 0
        
        public init(
            bodyPart: MRIBodyPart = .brain,
            scanType: MRIScanType = .t1
        ) {
            self.bodyPart = bodyPart
            self.scanType = scanType
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Procedure Title
                Text("\(bodyPart.displayName) MRI")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Scan Type Selector
                Picker("Scan Type", selection: .constant(scanType)) {
                    ForEach(MRIScanType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // MRI Machine
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    MRIMachineView(
                        bodyPart: bodyPart,
                        scanType: scanType,
                        showingScan: showingScan,
                        scanProgress: scanProgress
                    )
                    .frame(height: 280)
                }
                
                // Scan Controls
                VStack(spacing: 12) {
                    Button(action: { 
                        showingScan.toggle()
                        if showingScan {
                            startScan()
                        } else {
                            scanProgress = 0
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: showingScan ? "stop.fill" : "play.fill")
                            Text(showingScan ? "Stop Scan" : "Start Scan")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(showingScan ? Color.red : Color.green)
                        .cornerRadius(8)
                    }
                    
                    if showingScan {
                        ProgressView(value: scanProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        
                        Text("\(Int(scanProgress * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Procedure Information
                MRIInfoView(bodyPart: bodyPart, scanType: scanType)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private func startScan() {
            withAnimation(.linear(duration: 30)) {
                scanProgress = 1.0
            }
        }
    }
    
    // MARK: - CT Scan Illustrations
    
    /// CT scan procedure illustration
    public struct CTScanIllustration: View {
        let bodyPart: CTBodyPart
        let scanMode: CTScanMode
        @State private var showingCrossSection: Bool = false
        @State private var slicePosition: Double = 0.5
        
        public init(
            bodyPart: CTBodyPart = .chest,
            scanMode: CTScanMode = .standard
        ) {
            self.bodyPart = bodyPart
            self.scanMode = scanMode
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Procedure Title
                Text("\(bodyPart.displayName) CT Scan")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Scan Mode Selector
                Picker("Scan Mode", selection: .constant(scanMode)) {
                    ForEach(CTScanMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // CT Scanner
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    CTScannerView(
                        bodyPart: bodyPart,
                        scanMode: scanMode,
                        showingCrossSection: showingCrossSection,
                        slicePosition: slicePosition
                    )
                    .frame(height: 280)
                }
                
                // Cross Section Toggle
                Toggle("Show Cross Section", isOn: $showingCrossSection)
                    .padding(.horizontal)
                
                if showingCrossSection {
                    // Slice Position Slider
                    VStack(spacing: 8) {
                        Text("Slice Position")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Slider(value: $slicePosition, in: 0...1)
                            .padding(.horizontal)
                    }
                }
                
                // Procedure Information
                CTScanInfoView(bodyPart: bodyPart, scanMode: scanMode)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Ultrasound Illustrations
    
    /// Ultrasound procedure illustration
    public struct UltrasoundIllustration: View {
        let bodyPart: UltrasoundBodyPart
        let examType: UltrasoundExamType
        @State private var showingImage: Bool = false
        @State private var probePosition: CGPoint = CGPoint(x: 0.5, y: 0.5)
        
        public init(
            bodyPart: UltrasoundBodyPart = .abdomen,
            examType: UltrasoundExamType = .general
        ) {
            self.bodyPart = bodyPart
            self.examType = examType
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Procedure Title
                Text("\(bodyPart.displayName) Ultrasound")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Exam Type Selector
                Picker("Exam Type", selection: .constant(examType)) {
                    ForEach(UltrasoundExamType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Ultrasound Setup
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    UltrasoundSetupView(
                        bodyPart: bodyPart,
                        examType: examType,
                        showingImage: showingImage,
                        probePosition: probePosition
                    )
                    .frame(height: 280)
                }
                
                // Image Toggle
                Button(action: { showingImage.toggle() }) {
                    HStack(spacing: 8) {
                        Image(systemName: showingImage ? "eye.slash" : "eye")
                        Text(showingImage ? "Hide Image" : "Show Image")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                
                // Procedure Information
                UltrasoundInfoView(bodyPart: bodyPart, examType: examType)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Endoscopy Illustrations
    
    /// Endoscopy procedure illustration
    public struct EndoscopyIllustration: View {
        let endoscopyType: EndoscopyType
        @State private var showingInternal: Bool = false
        @State private var scopePosition: Double = 0.3
        
        public init(endoscopyType: EndoscopyType = .upperGI) {
            self.endoscopyType = endoscopyType
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Procedure Title
                Text("\(endoscopyType.displayName) Endoscopy")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // View Toggle
                Picker("View", selection: $showingInternal) {
                    Text("External").tag(false)
                    Text("Internal").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Endoscopy Setup
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    EndoscopySetupView(
                        endoscopyType: endoscopyType,
                        showingInternal: showingInternal,
                        scopePosition: scopePosition
                    )
                    .frame(height: 280)
                }
                
                if !showingInternal {
                    // Scope Position Slider
                    VStack(spacing: 8) {
                        Text("Scope Position")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Slider(value: $scopePosition, in: 0...1)
                            .padding(.horizontal)
                    }
                }
                
                // Procedure Information
                EndoscopyInfoView(endoscopyType: endoscopyType)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Supporting Views

struct XRaySetupView: View {
    let bodyPart: XRayBodyPart
    let showingEquipment: Bool
    let showingImage: Bool
    
    var body: some View {
        ZStack {
            if showingEquipment {
                // X-Ray machine
                VStack(spacing: 20) {
                    // X-Ray tube
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray)
                        .frame(width: 60, height: 40)
                    
                    // Patient table
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.brown)
                        .frame(width: 120, height: 20)
                    
                    // Detector
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray)
                        .frame(width: 100, height: 30)
                }
            }
            
            // Body part outline
            bodyPartShape
                .stroke(Color.black, lineWidth: 2)
                .frame(width: 100, height: 100)
            
            // X-Ray image overlay
            if showingImage {
                bodyPartShape
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 100, height: 100)
                    .overlay(
                        bodyPartXRayImage
                    )
            }
        }
    }
    
    @ViewBuilder
    private var bodyPartShape: some Shape {
        switch bodyPart {
        case .chest:
            Ellipse()
        case .spine:
            Rectangle()
        case .hand:
            RoundedRectangle(cornerRadius: 8)
        case .foot:
            RoundedRectangle(cornerRadius: 8)
        }
    }
    
    @ViewBuilder
    private var bodyPartXRayImage: some View {
        switch bodyPart {
        case .chest:
            VStack(spacing: 4) {
                // Ribs
                ForEach(0..<6, id: \.self) { index in
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 80, height: 1)
                        .offset(y: CGFloat(index * 8 - 20))
                }
                // Heart shadow
                Ellipse()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 30, height: 25)
            }
        case .spine:
            VStack(spacing: 2) {
                ForEach(0..<8, id: \.self) { index in
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 20, height: 8)
                }
            }
        case .hand:
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    VStack(spacing: 1) {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 3, height: 15)
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 3, height: 10)
                    }
                }
            }
        case .foot:
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 3, height: 20)
                }
            }
        }
    }
}

struct XRayInfoView: View {
    let bodyPart: XRayBodyPart
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("X-Ray Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(title: "Body Part", value: bodyPart.displayName)
                DetailRow(title: "Duration", value: "5-15 minutes")
                DetailRow(title: "Radiation", value: "Low dose")
                DetailRow(title: "Preparation", value: bodyPart.preparation)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MRIMachineView: View {
    let bodyPart: MRIBodyPart
    let scanType: MRIScanType
    let showingScan: Bool
    let scanProgress: Double
    
    var body: some View {
        ZStack {
            // MRI machine
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray)
                .frame(width: 200, height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 2)
                )
            
            // Patient table
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: 80, height: 20)
                .offset(y: 20)
            
            // Scan area indicator
            if showingScan {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 60, height: 15)
                    .offset(y: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            }
            
            // Progress indicator
            if showingScan {
                VStack {
                    Text("Scanning...")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    ProgressView(value: scanProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 100)
                }
                .offset(y: 60)
            }
        }
    }
}

struct MRIInfoView: View {
    let bodyPart: MRIBodyPart
    let scanType: MRIScanType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MRI Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(title: "Body Part", value: bodyPart.displayName)
                DetailRow(title: "Scan Type", value: scanType.displayName)
                DetailRow(title: "Duration", value: bodyPart.duration)
                DetailRow(title: "Preparation", value: bodyPart.preparation)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CTScannerView: View {
    let bodyPart: CTBodyPart
    let scanMode: CTScanMode
    let showingCrossSection: Bool
    let slicePosition: Double
    
    var body: some View {
        ZStack {
            // CT scanner
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray)
                .frame(width: 200, height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 2)
                )
            
            // Patient table
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: 80, height: 20)
                .offset(y: 20)
            
            // Cross section view
            if showingCrossSection {
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 80, height: 80)
                    .overlay(
                        bodyPartCrossSection
                    )
                    .offset(y: -20)
            }
            
            // Slice indicator
            if showingCrossSection {
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 100, height: 2)
                    .offset(y: CGFloat(slicePosition * 80 - 40))
            }
        }
    }
    
    @ViewBuilder
    private var bodyPartCrossSection: some View {
        switch bodyPart {
        case .chest:
            VStack(spacing: 4) {
                // Lungs
                HStack(spacing: 20) {
                    Circle()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 30, height: 30)
                    Circle()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 30, height: 30)
                }
                // Heart
                Circle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 20, height: 20)
            }
        case .abdomen:
            VStack(spacing: 4) {
                // Liver
                Ellipse()
                    .fill(Color.brown.opacity(0.3))
                    .frame(width: 40, height: 25)
                // Stomach
                Ellipse()
                    .fill(Color.pink.opacity(0.3))
                    .frame(width: 30, height: 20)
            }
        case .head:
            Circle()
                .fill(Color.pink.opacity(0.3))
                .frame(width: 60, height: 60)
        case .spine:
            VStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 15, height: 6)
                }
            }
        }
    }
}

struct CTScanInfoView: View {
    let bodyPart: CTBodyPart
    let scanMode: CTScanMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CT Scan Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(title: "Body Part", value: bodyPart.displayName)
                DetailRow(title: "Scan Mode", value: scanMode.displayName)
                DetailRow(title: "Duration", value: bodyPart.duration)
                DetailRow(title: "Radiation", value: "Moderate dose")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct UltrasoundSetupView: View {
    let bodyPart: UltrasoundBodyPart
    let examType: UltrasoundExamType
    let showingImage: Bool
    let probePosition: CGPoint
    
    var body: some View {
        ZStack {
            // Patient outline
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.skin.opacity(0.3))
                .frame(width: 150, height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.skin, lineWidth: 2)
                )
            
            // Ultrasound probe
            Ellipse()
                .fill(Color.gray)
                .frame(width: 30, height: 15)
                .position(
                    x: 75 + CGFloat(probePosition.x - 0.5) * 100,
                    y: 50 + CGFloat(probePosition.y - 0.5) * 60
                )
            
            // Ultrasound image
            if showingImage {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.8))
                    .frame(width: 80, height: 60)
                    .overlay(
                        bodyPartUltrasoundImage
                    )
                    .offset(x: 60, y: -20)
            }
        }
    }
    
    @ViewBuilder
    private var bodyPartUltrasoundImage: some View {
        switch bodyPart {
        case .abdomen:
            VStack(spacing: 2) {
                // Liver
                Ellipse()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 40, height: 25)
                // Gallbladder
                Ellipse()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 20, height: 15)
            }
        case .heart:
            Ellipse()
                .fill(Color.white.opacity(0.6))
                .frame(width: 50, height: 40)
        case .pregnancy:
            Ellipse()
                .fill(Color.white.opacity(0.7))
                .frame(width: 60, height: 45)
        case .thyroid:
            Ellipse()
                .fill(Color.white.opacity(0.5))
                .frame(width: 30, height: 20)
        }
    }
}

struct UltrasoundInfoView: View {
    let bodyPart: UltrasoundBodyPart
    let examType: UltrasoundExamType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ultrasound Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(title: "Body Part", value: bodyPart.displayName)
                DetailRow(title: "Exam Type", value: examType.displayName)
                DetailRow(title: "Duration", value: bodyPart.duration)
                DetailRow(title: "Radiation", value: "None")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EndoscopySetupView: View {
    let endoscopyType: EndoscopyType
    let showingInternal: Bool
    let scopePosition: Double
    
    var body: some View {
        ZStack {
            if showingInternal {
                // Internal view
                VStack(spacing: 10) {
                    // Esophagus
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.pink.opacity(0.3))
                        .frame(width: 40, height: 60)
                    
                    // Stomach
                    Ellipse()
                        .fill(Color.pink.opacity(0.3))
                        .frame(width: 60, height: 40)
                    
                    // Scope
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 3, height: 80)
                        .offset(x: 20, y: -20)
                }
            } else {
                // External view
                VStack(spacing: 20) {
                    // Patient outline
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.skin.opacity(0.3))
                        .frame(width: 120, height: 80)
                    
                    // Endoscope
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 4, height: 60)
                        .offset(x: 30, y: -10)
                }
            }
        }
    }
}

struct EndoscopyInfoView: View {
    let endoscopyType: EndoscopyType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Endoscopy Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(title: "Type", value: endoscopyType.displayName)
                DetailRow(title: "Duration", value: endoscopyType.duration)
                DetailRow(title: "Anesthesia", value: endoscopyType.anesthesia)
                DetailRow(title: "Preparation", value: endoscopyType.preparation)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Data Models

enum XRayBodyPart: CaseIterable {
    case chest
    case spine
    case hand
    case foot
    
    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .spine: return "Spine"
        case .hand: return "Hand"
        case .foot: return "Foot"
        }
    }
    
    var preparation: String {
        switch self {
        case .chest: return "Remove metal objects"
        case .spine: return "Remove metal objects"
        case .hand: return "Remove jewelry"
        case .foot: return "Remove shoes"
        }
    }
}

enum MRIBodyPart: CaseIterable {
    case brain
    case spine
    case knee
    case shoulder
    
    var displayName: String {
        switch self {
        case .brain: return "Brain"
        case .spine: return "Spine"
        case .knee: return "Knee"
        case .shoulder: return "Shoulder"
        }
    }
    
    var duration: String {
        switch self {
        case .brain: return "30-60 minutes"
        case .spine: return "30-60 minutes"
        case .knee: return "20-40 minutes"
        case .shoulder: return "20-40 minutes"
        }
    }
    
    var preparation: String {
        switch self {
        case .brain: return "Remove all metal"
        case .spine: return "Remove all metal"
        case .knee: return "Remove metal objects"
        case .shoulder: return "Remove metal objects"
        }
    }
}

enum MRIScanType: CaseIterable {
    case t1
    case t2
    case flair
    case diffusion
    
    var displayName: String {
        switch self {
        case .t1: return "T1"
        case .t2: return "T2"
        case .flair: return "FLAIR"
        case .diffusion: return "Diffusion"
        }
    }
}

enum CTBodyPart: CaseIterable {
    case chest
    case abdomen
    case head
    case spine
    
    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .abdomen: return "Abdomen"
        case .head: return "Head"
        case .spine: return "Spine"
        }
    }
    
    var duration: String {
        switch self {
        case .chest: return "5-10 minutes"
        case .abdomen: return "10-15 minutes"
        case .head: return "5-10 minutes"
        case .spine: return "10-15 minutes"
        }
    }
}

enum CTScanMode: CaseIterable {
    case standard
    case contrast
    case lowDose
    case highResolution
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .contrast: return "Contrast"
        case .lowDose: return "Low Dose"
        case .highResolution: return "High Res"
        }
    }
}

enum UltrasoundBodyPart: CaseIterable {
    case abdomen
    case heart
    case pregnancy
    case thyroid
    
    var displayName: String {
        switch self {
        case .abdomen: return "Abdomen"
        case .heart: return "Heart"
        case .pregnancy: return "Pregnancy"
        case .thyroid: return "Thyroid"
        }
    }
    
    var duration: String {
        switch self {
        case .abdomen: return "15-30 minutes"
        case .heart: return "20-40 minutes"
        case .pregnancy: return "20-30 minutes"
        case .thyroid: return "10-20 minutes"
        }
    }
}

enum UltrasoundExamType: CaseIterable {
    case general
    case doppler
    case echocardiogram
    case obstetric
    
    var displayName: String {
        switch self {
        case .general: return "General"
        case .doppler: return "Doppler"
        case .echocardiogram: return "Echo"
        case .obstetric: return "Obstetric"
        }
    }
}

enum EndoscopyType: CaseIterable {
    case upperGI
    case colonoscopy
    case bronchoscopy
    case cystoscopy
    
    var displayName: String {
        switch self {
        case .upperGI: return "Upper GI"
        case .colonoscopy: return "Colonoscopy"
        case .bronchoscopy: return "Bronchoscopy"
        case .cystoscopy: return "Cystoscopy"
        }
    }
    
    var duration: String {
        switch self {
        case .upperGI: return "15-30 minutes"
        case .colonoscopy: return "30-60 minutes"
        case .bronchoscopy: return "15-30 minutes"
        case .cystoscopy: return "10-20 minutes"
        }
    }
    
    var anesthesia: String {
        switch self {
        case .upperGI: return "Sedation"
        case .colonoscopy: return "Sedation"
        case .bronchoscopy: return "Local"
        case .cystoscopy: return "Local"
        }
    }
    
    var preparation: String {
        switch self {
        case .upperGI: return "Fasting 6-8 hours"
        case .colonoscopy: return "Bowel prep"
        case .bronchoscopy: return "Fasting 4-6 hours"
        case .cystoscopy: return "Empty bladder"
        }
    }
}

// MARK: - Extensions

extension Color {
    static let skin = Color(red: 0.9, green: 0.8, blue: 0.7)
} 