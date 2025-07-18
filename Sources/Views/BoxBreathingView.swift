import SwiftUI

@available(tvOS 17.0, *)
struct BoxBreathingView: View {
    @StateObject private var breathingExercise = BoxBreathingExercise.shared
    @State private var showingSettings = false
    @State private var showingResults = false
    @State private var breathingScale: CGFloat = 0.3
    @State private var particleOpacity: Double = 0.5
    @State private var backgroundAnimation: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background Layer
            backgroundLayer
            
            // Particle Effects
            if breathingExercise.particleEffects {
                particleEffectsLayer
            }
            
            // Main Content
            if breathingExercise.isActive {
                breathingExerciseLayer
            } else if showingResults {
                resultsLayer
            } else {
                setupLayer
            }
            
            // Settings Overlay
            if showingSettings {
                settingsOverlay
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startBackgroundAnimation()
        }
        .onChange(of: breathingExercise.currentPhase) { _, newPhase in
            animateBreathingPhase(newPhase)
        }
        .onChange(of: breathingExercise.phaseProgress) { _, progress in
            updateBreathingAnimation(progress)
        }
        .onReceive(NotificationCenter.default.publisher(for: .breathingSessionCompleted)) { _ in
            showingResults = true
        }
    }
    
    // MARK: - HIG-Compliant Color System
    
    // Use system colors exclusively
    private var breathingColors: [Color] {
        [
            Color(.systemBlue),
            Color(.systemCyan),
            Color(.systemIndigo),
            Color(.systemGreen),
            Color(.systemMint),
            Color(.systemTeal)
        ]
    }
    
    // MARK: - Background Layer
    
    private var backgroundLayer: some View {
        ZStack {
            switch breathingExercise.backgroundStyle {
            case .cosmic:
                cosmicBackground
            case .ocean:
                oceanBackground
            case .forest:
                forestBackground
            case .abstract:
                abstractBackground
            case .minimal:
                minimalBackground
            }
        }
        .clipped()
    }
    
    private var cosmicBackground: some View {
        Rectangle()
            .fill(.regularMaterial)
            .overlay(
                LinearGradient(
                    colors: [Color(.systemIndigo).opacity(0.3), Color(.systemPurple).opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
    
    private var oceanBackground: some View {
        Rectangle()
            .fill(.regularMaterial)
            .overlay(
                LinearGradient(
                    colors: [Color(.systemBlue).opacity(0.3), Color(.systemCyan).opacity(0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
    
    private var forestBackground: some View {
        Rectangle()
            .fill(.regularMaterial)
            .overlay(
                LinearGradient(
                    colors: [Color(.systemGreen).opacity(0.3), Color(.systemMint).opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            ForEach(0..<40, id: \.self) { i in // More leaves for 4K
                Image(systemName: "leaf.fill")
                    .foregroundColor(hdrColor(.green, intensity: 0.3))
                    .font(.system(size: 25 + Double.random(in: 0...15))) // Larger for 4K
                    .position(
                        x: Double.random(in: 0...screenSize.width),
                        y: Double.random(in: 0...screenSize.height)
                    )
                    .rotation3DEffect(
                        .degrees(backgroundAnimation * 10 + Double(i) * 18),
                        axis: (x: 0, y: 0, z: 1)
                    )
                    .blur(radius: 0.5) // Subtle blur
            }
        }
    }
    
    private var abstractBackground: some View {
        ZStack {
            // Enhanced abstract shapes for HDR
            ForEach(0..<12, id: \.self) { i in // More shapes for 4K
                RoundedRectangle(cornerRadius: 80) // Larger corner radius
                    .fill(
                        hdrGradient(
                            colors: breathingExercise.colorTheme.primaryColors.map { hdrColor($0, intensity: 0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 450, height: 300) // Larger for 4K
                    .position(
                        x: Double.random(in: 200...(screenSize.width - 200)),
                        y: Double.random(in: 150...(screenSize.height - 150))
                    )
                    .rotation3DEffect(
                        .degrees(backgroundAnimation * 5 + Double(i) * 45),
                        axis: (x: 1, y: 1, z: 0)
                    )
                    .blur(radius: 1) // Subtle blur
            }
        }
    }
    
    private var minimalBackground: some View {
        hdrGradient(
            colors: [.black, hdrColor(.gray, intensity: 0.15)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Enhanced Particle Effects for 4K HDR
    
    private var particleEffectsLayer: some View {
        ZStack {
            ForEach(0..<60, id: \.self) { i in // More particles for 4K
                Circle()
                    .fill(hdrColor(breathingExercise.colorTheme.primaryColors[i % breathingExercise.colorTheme.primaryColors.count], intensity: 1.3))
                    .frame(width: 6, height: 6) // Larger particles
                    .position(
                        x: Double.random(in: 0...screenSize.width),
                        y: Double.random(in: 0...screenSize.height)
                    )
                    .opacity(particleOpacity * (0.4 + 0.6 * sin(backgroundAnimation + Double(i) * 0.2)))
                    .scaleEffect(0.6 + 0.4 * sin(backgroundAnimation + Double(i) * 0.1))
                    .blur(radius: 0.5) // Subtle glow effect
            }
        }
    }
    
    // MARK: - Setup Layer
    
    private var setupLayer: some View {
        VStack(spacing: 60) {
            // Title
            VStack(spacing: 20) {
                Text("Box Breathing")
                    .font(.system(size: 80, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Relaxation Exercise")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Watch Connection Status
            HStack(spacing: 20) {
                Image(systemName: breathingExercise.watchConnected ? "applewatch" : "applewatch.slash")
                    .font(.system(size: 40))
                    .foregroundColor(breathingExercise.watchConnected ? .green : .orange)
                
                Text(breathingExercise.watchConnected ? "Apple Watch Connected" : "Connecting to Apple Watch...")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            
            // Quick Start Options
            VStack(spacing: 30) {
                Text("Choose Your Session")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white)
                
                HStack(spacing: 40) {
                    quickStartButton(title: "Quick Start", subtitle: "5 minutes", cycles: 5, rate: 4.0)
                    quickStartButton(title: "Standard", subtitle: "10 minutes", cycles: 10, rate: 4.0)
                    quickStartButton(title: "Extended", subtitle: "15 minutes", cycles: 15, rate: 4.0)
                }
            }
            
            // Settings Button
            Button(action: { showingSettings = true }) {
                HStack(spacing: 15) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24))
                    Text("Customize Experience")
                        .font(.system(size: 24, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 25))
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
        }
        .padding(60)
    }
    
    private func quickStartButton(title: String, subtitle: String, cycles: Int, rate: Double) -> some View {
        Button(action: {
            breathingExercise.startBreathingSession(cycles: cycles, rate: rate)
        }) {
            VStack(spacing: 15) {
                Image(systemName: "lung.fill")
                    .font(.system(size: 50))
                    .foregroundColor(breathingExercise.colorTheme.primaryColors[0])
                
                Text(title)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(width: 280, height: 200)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30))
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.2), value: title)
    }
    
    // MARK: - Breathing Exercise Layer
    
    private var breathingExerciseLayer: some View {
        ZStack {
            // Watch Connection Indicator
            VStack {
                HStack {
                    Spacer()
                    watchStatusIndicator
                        .padding(.top, 60)
                        .padding(.trailing, 80)
                }
                Spacer()
            }
            
            // Main Breathing Visual
            VStack(spacing: 80) {
                // Progress Indicator
                progressIndicator
                
                // Breathing Visual
                breathingVisual
                
                // Phase Instructions
                phaseInstructions
                
                // Session Controls
                sessionControls
            }
        }
    }
    
    private var watchStatusIndicator: some View {
        HStack(spacing: 15) {
            Image(systemName: "applewatch")
                .font(.system(size: 24))
                .foregroundColor(breathingExercise.watchConnected ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 5) {
                if breathingExercise.watchConnected {
                    HStack(spacing: 10) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("\(Int(breathingExercise.watchHeartRate))")
                            .font(.system(size: 18, weight: .medium))
                    }
                    
                    HStack(spacing: 10) {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundColor(.blue)
                        Text("\(Int(breathingExercise.watchHRV))")
                            .font(.system(size: 18, weight: .medium))
                    }
                } else {
                    Text("Connecting...")
                        .font(.system(size: 16))
                }
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
    }
    
    private var progressIndicator: some View {
        VStack(spacing: 20) {
            // Session Progress
            HStack(spacing: 40) {
                VStack {
                    Text("\(breathingExercise.completedCycles)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(breathingExercise.colorTheme.primaryColors[0])
                    Text("Cycles")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                VStack {
                    Text("\(breathingExercise.targetCycles)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Goal")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                VStack {
                    Text(timeString(from: breathingExercise.sessionDuration))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(breathingExercise.colorTheme.primaryColors[1])
                    Text("Time")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Progress Bar
            ProgressView(value: Double(breathingExercise.completedCycles), total: Double(breathingExercise.targetCycles))
                .progressViewStyle(LinearProgressViewStyle(tint: breathingExercise.colorTheme.primaryColors[0]))
                .scaleEffect(y: 3)
                .frame(width: 400)
        }
    }
    
    private var breathingVisual: some View {
        ZStack {
            // Main breathing shape
            switch breathingExercise.visualStyle {
            case .circle:
                breathingCircle
            case .mandala:
                breathingMandala
            case .flower:
                breathingFlower
            case .geometric:
                breathingGeometric
            }
        }
        .frame(width: 600, height: 600) // Larger for 4K
        .scaleEffect(breathingScale)
        .animation(.easeInOut(duration: breathingExercise.breathingRate), value: breathingScale)
    }
    
    private var breathingCircle: some View {
        ZStack {
            // Outer ring with HDR enhancement
            Circle()
                .stroke(
                    hdrGradient(
                        colors: breathingExercise.colorTheme.primaryColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 12 // Thicker for 4K
                )
                .opacity(0.7)
                .blur(radius: 0.5) // Subtle glow
            
            // Inner fill with HDR enhancement
            Circle()
                .fill(
                    hdrRadialGradient(
                        colors: breathingExercise.colorTheme.primaryColors.map { hdrColor($0, intensity: 0.4) },
                        center: .center,
                        startRadius: 0,
                        endRadius: 300 // Larger for 4K
                    )
                )
                .opacity(0.8)
            
            // Enhanced pulsing center
            Circle()
                .fill(hdrColor(breathingExercise.colorTheme.primaryColors[0], intensity: 1.2))
                .frame(width: 30, height: 30) // Larger for 4K
                .scaleEffect(1.0 + breathingExercise.phaseProgress * 0.6)
                .opacity(0.9)
                .blur(radius: 1) // Glow effect
        }
    }
    
    private var breathingMandala: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Petal()
                    .fill(
                        hdrGradient(
                            colors: [
                                hdrColor(breathingExercise.colorTheme.primaryColors[i % breathingExercise.colorTheme.primaryColors.count], intensity: 1.1),
                                hdrColor(breathingExercise.colorTheme.primaryColors[(i + 1) % breathingExercise.colorTheme.primaryColors.count], intensity: 1.1)
                            ],
                            startPoint: .center,
                            endPoint: .topTrailing
                        )
                    )
                    .opacity(0.7)
                    .rotationEffect(.degrees(Double(i) * 45))
                    .scaleEffect(0.8 + breathingExercise.phaseProgress * 0.5)
                    .blur(radius: 0.5) // Subtle glow
            }
        }
    }
    
    private var breathingFlower: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Ellipse()
                    .fill(
                        hdrRadialGradient(
                            colors: [
                                hdrColor(breathingExercise.colorTheme.primaryColors[0], intensity: 0.9),
                                hdrColor(breathingExercise.colorTheme.primaryColors[1], intensity: 0.4)
                            ],
                            center: .bottom,
                            startRadius: 15,
                            endRadius: 150 // Larger for 4K
                        )
                    )
                    .frame(width: 120, height: 300) // Larger for 4K
                    .offset(y: -75)
                    .rotationEffect(.degrees(Double(i) * 60))
                    .scaleEffect(0.7 + breathingExercise.phaseProgress * 0.6)
                    .blur(radius: 0.5) // Subtle glow
            }
            
            // Enhanced center
            Circle()
                .fill(hdrColor(breathingExercise.colorTheme.primaryColors[2], intensity: 1.2))
                .frame(width: 60, height: 60) // Larger for 4K
                .blur(radius: 1) // Glow effect
        }
    }
    
    private var breathingGeometric: some View {
        ZStack {
            // Enhanced rotating hexagon
            Hexagon()
                .stroke(
                    hdrGradient(
                        colors: breathingExercise.colorTheme.primaryColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 10 // Thicker for 4K
                )
                .rotationEffect(.degrees(backgroundAnimation * 10))
                .blur(radius: 0.5) // Subtle glow
            
            // Enhanced inner triangle
            Triangle()
                .fill(
                    hdrGradient(
                        colors: breathingExercise.colorTheme.primaryColors.map { hdrColor($0, intensity: 0.5) },
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 300, height: 300) // Larger for 4K
                .rotationEffect(.degrees(-backgroundAnimation * 15))
                .blur(radius: 0.5) // Subtle glow
        }
    }
    
    private var phaseInstructions: some View {
        VStack(spacing: 30) { // Increased spacing for 4K
            Text(breathingExercise.currentPhase.displayName)
                .font(.system(size: 72, weight: .light)) // Larger for 4K
                .foregroundColor(hdrColor(.white, intensity: 1.1))
                .animation(.easeInOut(duration: 0.3), value: breathingExercise.currentPhase)
                .shadow(color: hdrColor(.black, intensity: 0.5), radius: 2, x: 0, y: 2) // Enhanced shadow
            
            // Enhanced phase progress indicator
            HStack(spacing: 15) { // Increased spacing
                ForEach(BreathingPhase.allCases, id: \.self) { phase in
                    Circle()
                        .fill(phase == breathingExercise.currentPhase ? 
                              hdrColor(breathingExercise.colorTheme.primaryColors[0], intensity: 1.2) : 
                              hdrColor(.white, intensity: 0.4))
                        .frame(width: 18, height: 18) // Larger for 4K
                        .scaleEffect(phase == breathingExercise.currentPhase ? 1.5 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: breathingExercise.currentPhase)
                        .blur(radius: phase == breathingExercise.currentPhase ? 0.5 : 0) // Glow for active phase
                }
            }
            
            // Enhanced breathing rate guidance
            Text("\(Int(breathingExercise.breathingRate)) seconds per phase")
                .font(.system(size: 30)) // Larger for 4K
                .foregroundColor(hdrColor(.white, intensity: 0.8))
                .shadow(color: hdrColor(.black, intensity: 0.3), radius: 1, x: 0, y: 1)
        }
    }
    
    private var sessionControls: some View {
        HStack(spacing: 90) { // Increased spacing for 4K
            // Enhanced Pause/Resume Button
            Button(action: {
                if breathingExercise.isActive {
                    breathingExercise.pauseBreathingSession()
                } else {
                    breathingExercise.resumeBreathingSession()
                }
            }) {
                HStack(spacing: 15) { // Increased spacing
                    Image(systemName: breathingExercise.isActive ? "pause.fill" : "play.fill")
                        .font(.system(size: 36)) // Larger for 4K
                    Text(breathingExercise.isActive ? "Pause" : "Resume")
                        .font(.system(size: 36, weight: .medium)) // Larger for 4K
                }
                .foregroundColor(hdrColor(.white, intensity: 1.1))
                .padding(.horizontal, 45) // Larger padding
                .padding(.vertical, 22) // Larger padding
                .background(
                    RoundedRectangle(cornerRadius: 35) // Larger corner radius
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 35)
                                .stroke(hdrColor(.white, intensity: 0.2), lineWidth: 1)
                        )
                )
                .shadow(color: hdrColor(.black, intensity: 0.3), radius: 3, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            
            // Enhanced Stop Button
            Button(action: {
                breathingExercise.stopBreathingSession()
            }) {
                HStack(spacing: 15) { // Increased spacing
                    Image(systemName: "stop.fill")
                        .font(.system(size: 36)) // Larger for 4K
                    Text("Stop")
                        .font(.system(size: 36, weight: .medium)) // Larger for 4K
                }
                .foregroundColor(hdrColor(.white, intensity: 1.1))
                .padding(.horizontal, 45) // Larger padding
                .padding(.vertical, 22) // Larger padding
                .background(
                    RoundedRectangle(cornerRadius: 35) // Larger corner radius
                        .fill(hdrColor(.red, intensity: 0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 35)
                                .stroke(hdrColor(.white, intensity: 0.2), lineWidth: 1)
                        )
                )
                .shadow(color: hdrColor(.black, intensity: 0.3), radius: 3, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Results Layer
    
    private var resultsLayer: some View {
        VStack(spacing: 50) {
            // Session Complete Title
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("Session Complete")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.white)
                
                Text("Great job on completing your breathing exercise!")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Results Summary
            VStack(spacing: 30) {
                HStack(spacing: 80) {
                    resultCard(
                        title: "Cycles",
                        value: "\(breathingExercise.completedCycles)",
                        subtitle: "of \(breathingExercise.targetCycles)",
                        color: breathingExercise.colorTheme.primaryColors[0]
                    )
                    
                    resultCard(
                        title: "Duration",
                        value: timeString(from: breathingExercise.sessionDuration),
                        subtitle: "minutes",
                        color: breathingExercise.colorTheme.primaryColors[1]
                    )
                    
                    resultCard(
                        title: "Relaxation",
                        value: "\(Int(breathingExercise.relaxationScore * 100))%",
                        subtitle: "score",
                        color: breathingExercise.colorTheme.primaryColors[2]
                    )
                }
                
                if breathingExercise.stressReduction > 0 {
                    HStack(spacing: 20) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.red)
                        
                        Text("Stress reduced by \(Int(breathingExercise.stressReduction * 100))%")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(.green.opacity(0.2), in: RoundedRectangle(cornerRadius: 20))
                }
            }
            
            // Action Buttons
            HStack(spacing: 40) {
                Button(action: {
                    showingResults = false
                }) {
                    HStack(spacing: 15) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 24))
                        Text("Back to Home")
                            .font(.system(size: 24, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 25))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    showingResults = false
                    breathingExercise.startBreathingSession(
                        cycles: breathingExercise.targetCycles,
                        rate: breathingExercise.breathingRate
                    )
                }) {
                    HStack(spacing: 15) {
                        Image(systemName: "repeat")
                            .font(.system(size: 24))
                        Text("Start Another Session")
                            .font(.system(size: 24, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(breathingExercise.colorTheme.primaryColors[0], in: RoundedRectangle(cornerRadius: 25))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(60)
    }
    
    private func resultCard(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 15) {
            Text(title)
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.8))
            
            Text(value)
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 200, height: 150)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Settings Overlay
    
    private var settingsOverlay: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    showingSettings = false
                }
            
            // Settings panel
            VStack(spacing: 40) {
                Text("Customize Experience")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
                
                VStack(spacing: 30) {
                    // Visual Style
                    settingsSection(title: "Visual Style") {
                        HStack(spacing: 20) {
                            ForEach(BreathingVisualStyle.allCases, id: \.self) { style in
                                Button(action: {
                                    breathingExercise.setVisualStyle(style)
                                }) {
                                    Text(style.displayName)
                                        .font(.system(size: 20))
                                        .foregroundColor(style == breathingExercise.visualStyle ? .black : .white)
                                        .padding(.horizontal, 25)
                                        .padding(.vertical, 12)
                                        .background(
                                            style == breathingExercise.visualStyle ? 
                                            .white : .clear,
                                            in: RoundedRectangle(cornerRadius: 15)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(.white.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Background Style
                    settingsSection(title: "Background") {
                        HStack(spacing: 20) {
                            ForEach(BackgroundStyle.allCases, id: \.self) { style in
                                Button(action: {
                                    breathingExercise.setBackgroundStyle(style)
                                }) {
                                    Text(style.displayName)
                                        .font(.system(size: 20))
                                        .foregroundColor(style == breathingExercise.backgroundStyle ? .black : .white)
                                        .padding(.horizontal, 25)
                                        .padding(.vertical, 12)
                                        .background(
                                            style == breathingExercise.backgroundStyle ? 
                                            .white : .clear,
                                            in: RoundedRectangle(cornerRadius: 15)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(.white.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Color Theme
                    settingsSection(title: "Color Theme") {
                        HStack(spacing: 20) {
                            ForEach(ColorTheme.allCases, id: \.self) { theme in
                                Button(action: {
                                    breathingExercise.setColorTheme(theme)
                                }) {
                                    HStack(spacing: 10) {
                                        HStack(spacing: 2) {
                                            ForEach(theme.primaryColors, id: \.self) { color in
                                                Circle()
                                                    .fill(color)
                                                    .frame(width: 8, height: 8)
                                            }
                                        }
                                        
                                        Text(theme.displayName)
                                            .font(.system(size: 18))
                                            .foregroundColor(theme == breathingExercise.colorTheme ? .black : .white)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        theme == breathingExercise.colorTheme ? 
                                        .white : .clear,
                                        in: RoundedRectangle(cornerRadius: 15)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Audio Settings
                    settingsSection(title: "Audio") {
                        VStack(spacing: 15) {
                            HStack(spacing: 40) {
                                Toggle("Guided Audio", isOn: $breathingExercise.guidedAudioEnabled)
                                    .toggleStyle(SwitchToggleStyle())
                                    .scaleEffect(1.2)
                                
                                Toggle("Background Music", isOn: $breathingExercise.backgroundMusic)
                                    .toggleStyle(SwitchToggleStyle())
                                    .scaleEffect(1.2)
                                
                                Toggle("Voice Guidance", isOn: $breathingExercise.voiceGuidance)
                                    .toggleStyle(SwitchToggleStyle())
                                    .scaleEffect(1.2)
                            }
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                            
                            HStack(spacing: 40) {
                                VStack {
                                    Text("Music Volume")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.8))
                                    Slider(value: Binding(
                                        get: { Double(breathingExercise.musicVolume) },
                                        set: { breathingExercise.musicVolume = Float($0) }
                                    ), in: 0...1)
                                    .frame(width: 200)
                                }
                                
                                VStack {
                                    Text("Voice Volume")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.8))
                                    Slider(value: Binding(
                                        get: { Double(breathingExercise.voiceVolume) },
                                        set: { breathingExercise.voiceVolume = Float($0) }
                                    ), in: 0...1)
                                    .frame(width: 200)
                                }
                            }
                        }
                    }
                }
                
                // Close Button
                Button(action: {
                    showingSettings = false
                }) {
                    Text("Done")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 15)
                        .background(breathingExercise.colorTheme.primaryColors[0], in: RoundedRectangle(cornerRadius: 25))
                }
                .buttonStyle(.plain)
            }
            .padding(60)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30))
            .frame(maxWidth: 1200, maxHeight: 800)
        }
    }
    
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
            
            content()
        }
    }
    
    // MARK: - Animation Methods
    
    private func startBackgroundAnimation() {
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            backgroundAnimation = 360
        }
    }
    
    private func animateBreathingPhase(_ phase: BreathingPhase) {
        withAnimation(.easeInOut(duration: breathingExercise.breathingRate)) {
            breathingScale = CGFloat(phase.visualScale)
        }
        
        // Particle effects
        withAnimation(.easeInOut(duration: breathingExercise.breathingRate * 0.5)) {
            particleOpacity = phase == .inhale ? 0.8 : 0.3
        }
    }
    
    private func updateBreathingAnimation(_ progress: Double) {
        // Smooth interpolation for breathing visual
        let baseScale = breathingExercise.currentPhase.visualScale
        let targetScale = breathingExercise.currentPhase == .inhale ? 1.0 : 0.3
        let interpolatedScale = baseScale + (targetScale - baseScale) * progress
        
        withAnimation(.linear(duration: 0.1)) {
            breathingScale = CGFloat(interpolatedScale)
        }
    }
    
    // MARK: - Helper Methods
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Custom Shapes

struct Wave: Shape {
    var amplitude: Double
    var frequency: Double
    var phase: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let centerY = height / 2
        
        path.move(to: CGPoint(x: 0, y: centerY))
        
        for x in stride(from: 0, through: width, by: 1) {
            let y = centerY + amplitude * sin(frequency * x + phase)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

struct Petal: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: center)
        path.addQuadCurve(
            to: CGPoint(x: center.x + radius, y: center.y),
            control: CGPoint(x: center.x + radius * 0.5, y: center.y - radius * 0.8)
        )
        path.addQuadCurve(
            to: center,
            control: CGPoint(x: center.x + radius * 0.5, y: center.y + radius * 0.8)
        )
        
        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        for i in 0..<6 {
            let angle = Double(i) * .pi / 3
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let breathingSessionCompleted = Notification.Name("breathingSessionCompleted")
}