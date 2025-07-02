import SwiftUI
import HealthKit
import AVFoundation
import CoreHaptics
import Combine
import os.log

// MARK: - Audio Controls Card
struct AudioControlsCard: View {
    @StateObject private var audioEngine = AudioGenerationEngine.shared
    @State private var isExpanded = false
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.title2)
                    .foregroundColor(.somnaPrimary)
                    .rotationEffect(.degrees(isAnimating ? 5 : -5))
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                
                Text("Audio Generation")
                .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    HapticManager.shared.impact(style: .medium)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.title3)
                        .foregroundColor(.somnaPrimary)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
                }
            }
            
            if isExpanded {
                VStack(spacing: 12) {
                    // Audio Status
                    HStack {
                        Circle()
                            .fill(audioEngine.isPlaying ? .somnaAccent : .gray)
                            .frame(width: 8, height: 8)
                            .scaleEffect(isAnimating ? 1.5 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                        
                        Text(audioEngine.isPlaying ? "Playing Audio" : "Audio Ready")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if audioEngine.isPlaying {
                            Text(audioEngine.currentAudioType?.displayName ?? "")
                                .font(.caption)
                                .foregroundColor(.somnaPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.somnaPrimary.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                    
                    // Volume Control
                    VStack(spacing: 8) {
                        HStack {
                            Text("Volume")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(audioEngine.volume * 100))%")
                                .font(.caption)
                                .foregroundColor(.somnaPrimary)
                        }
                        
                        Slider(value: $audioEngine.volume, in: 0...1)
                            .accentColor(.somnaPrimary)
                            .onChange(of: audioEngine.volume) { _ in
                                HapticManager.shared.impact(style: .light)
                            }
                    }
                    
                    // Quick Actions
                    HStack(spacing: 12) {
                        Button(action: {
                            HapticManager.shared.impact(style: .medium)
                            Task {
                                await audioEngine.generatePreSleepAudio(type: .binauralBeats(frequency: 432), duration: 1800)
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "waveform")
                                    .font(.title3)
                                Text("Binaural")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.somnaPrimary)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            HapticManager.shared.impact(style: .medium)
                            Task {
                                await audioEngine.generatePreSleepAudio(type: .whiteNoise(color: .white), duration: 1800)
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "speaker.wave.2")
                                    .font(.title3)
                                Text("White Noise")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.somnaSecondary)
                            .cornerRadius(10)
                        }
                    }
                    
                    // Play/Stop Button
                    Button(action: {
                        HapticManager.shared.impact(style: .heavy)
                        if audioEngine.isPlaying {
                            audioEngine.stopAudio()
                        } else {
                            Task {
                                await audioEngine.generatePreSleepAudio(type: .binauralBeats(frequency: 432), duration: 1800)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: audioEngine.isPlaying ? "stop.fill" : "play.fill")
                                .font(.title3)
                            Text(audioEngine.isPlaying ? "Stop Audio" : "Start Audio")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: audioEngine.isPlaying ? 
                                    [Color.red, Color.red.opacity(0.8)] : 
                                    [Color.somnaPrimary, Color.somnaSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .scaleEffect(isAnimating ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.somnaCardBackground)
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.somnaPrimary.opacity(0.3), .somnaSecondary.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            isAnimating = true
        }
    }
}

