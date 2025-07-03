import Foundation

/// Types of personalized audio content
public enum PersonalizedAudioType {
    case meditation
    case sleepStory
    case motivation
}

/// User voice preferences for TTS
public struct VoiceProfile {
    public let languageCode: String
    public let voiceIdentifier: String?
    public let gender: String? // "male" or "female"
    public let style: String? // e.g., "calm", "energetic"
}

/// User psychological profile for content tailoring
public struct PsychologicalProfile {
    public let meditationFocus: String
    public let sleepStoryTheme: String
    public let motivationTheme: String
    public let affirmation: String
}
