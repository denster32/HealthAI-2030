import SwiftUI
import HealthKit
import AVFoundation
import CoreHaptics
import Combine
import os.log

// MARK: - AudioType Extensions

extension AudioType: CaseIterable {
    static var allCases: [AudioType] {
        return [
            .binaural(frequency: 4.0),
            .whiteNoise(color: .pink),
            .nature(environment: .ocean),
            .meditation(style: .mindfulness),
            .ambient(genre: .drone),
            .customMix
        ]
    }
    
    var displayName: String {
        switch self {
        case .binaural(let frequency):
            return "Binaural Beats (\(Int(frequency))Hz)"
        case .whiteNoise(let color):
            return "\(color.rawValue) Noise"
        case .nature(let environment):
            return "\(environment.rawValue) Sounds"
        case .meditation(let style):
            return "\(style.rawValue) Meditation"
        case .ambient(let genre):
            return "\(genre.rawValue) Music"
        case .customMix:
            return "Custom Mix"
        }
    }
}

