import Foundation
import NaturalLanguage

@available(iOS 18.0, *)
class SiriHealthFormatter {
    
    private let nlTagger = NLTagger(tagSchemes: [.language, .tokenType])
    
    // MARK: - Speech Formatting
    
    func formatForSpeech(_ text: String) async -> String {
        var spokenText = text
        
        // Convert numbers to spoken format
        spokenText = await convertNumbersToSpokenFormat(spokenText)
        
        // Add natural pauses
        spokenText = await addNaturalPauses(spokenText)
        
        // Adjust for speech clarity
        spokenText = await adjustForSpeechClarity(spokenText)
        
        // Add emphasis markers
        spokenText = await addEmphasisMarkers(spokenText)
        
        return spokenText
    }
    
    private func convertNumbersToSpokenFormat(_ text: String) async -> String {
        var result = text
        
        // Convert time formats
        result = result.replacingOccurrences(of: "75 bpm", with: "75 beats per minute")
        result = result.replacingOccurrences(of: "8h 30m", with: "8 hours and 30 minutes")
        result = result.replacingOccurrences(of: "10,000", with: "10 thousand")
        result = result.replacingOccurrences(of: "85%", with: "85 percent")
        
        // Convert measurements
        result = result.replacingOccurrences(of: "oz", with: "ounces")
        result = result.replacingOccurrences(of: "lbs", with: "pounds")
        result = result.replacingOccurrences(of: "kg", with: "kilograms")
        
        return result
    }
    
    private func addNaturalPauses(_ text: String) async -> String {
        var result = text
        
        // Add pauses after important statements
        result = result.replacingOccurrences(of: ". That's", with: "... That's")
        result = result.replacingOccurrences(of: ". Your", with: "... Your")
        result = result.replacingOccurrences(of: ". You", with: "... You")
        
        // Add pauses before suggestions
        result = result.replacingOccurrences(of: "Consider", with: "... Consider")
        result = result.replacingOccurrences(of: "Try", with: "... Try")
        
        return result
    }
    
    private func adjustForSpeechClarity(_ text: String) async -> String {
        var result = text
        
        // Replace abbreviations
        result = result.replacingOccurrences(of: "BPM", with: "beats per minute")
        result = result.replacingOccurrences(of: "HR", with: "heart rate")
        result = result.replacingOccurrences(of: "BP", with: "blood pressure")
        
        // Make technical terms more conversational
        result = result.replacingOccurrences(of: "cardiovascular fitness", with: "heart health")
        result = result.replacingOccurrences(of: "sleep efficiency", with: "sleep quality")
        result = result.replacingOccurrences(of: "hydration levels", with: "water intake")
        
        return result
    }
    
    private func addEmphasisMarkers(_ text: String) async -> String {
        var result = text
        
        // Add emphasis to positive achievements
        result = result.replacingOccurrences(of: "Excellent!", with: "**Excellent!**")
        result = result.replacingOccurrences(of: "Great job!", with: "**Great job!**")
        result = result.replacingOccurrences(of: "Fantastic!", with: "**Fantastic!**")
        
        // Add emphasis to important numbers
        if let range = result.range(of: "\\d+(?= beats per minute)", options: .regularExpression) {
            result.replaceSubrange(range, with: "**\(result[range])**")
        }
        
        return result
    }
    
    // MARK: - Display Formatting
    
    func formatForDisplay(_ text: String) async -> String {
        var displayText = text
        
        // Add emoji indicators
        displayText = await addEmojiIndicators(displayText)
        
        // Format data with visual elements
        displayText = await formatDataWithVisualElements(displayText)
        
        // Add bullet points for lists
        displayText = await formatListsWithBullets(displayText)
        
        return displayText
    }
    
    private func addEmojiIndicators(_ text: String) async -> String {
        var result = text
        
        // Health data emojis
        result = result.replacingOccurrences(of: "heart rate", with: "❤️ heart rate")
        result = result.replacingOccurrences(of: "sleep", with: "😴 sleep")
        result = result.replacingOccurrences(of: "steps", with: "👣 steps")
        result = result.replacingOccurrences(of: "water", with: "💧 water")
        result = result.replacingOccurrences(of: "workout", with: "🏋️ workout")
        result = result.replacingOccurrences(of: "meditation", with: "🧘 meditation")
        
        // Achievement emojis
        result = result.replacingOccurrences(of: "Excellent!", with: "🎉 Excellent!")
        result = result.replacingOccurrences(of: "Great job!", with: "👏 Great job!")
        result = result.replacingOccurrences(of: "Fantastic!", with: "🌟 Fantastic!")
        
        return result
    }
    
    private func formatDataWithVisualElements(_ text: String) async -> String {
        var result = text
        
        // Format health scores with progress bars
        if let scoreRange = result.range(of: "\\d+(?= out of 100)", options: .regularExpression) {
            let score = Int(result[scoreRange]) ?? 0
            let progressBar = generateProgressBar(value: score, max: 100)
            result = result.replacingOccurrences(of: "\(score) out of 100", with: "\(score)/100 \(progressBar)")
        }
        
        // Format percentages with visual indicators
        if let percentRange = result.range(of: "\\d+(?= percent)", options: .regularExpression) {
            let percent = Int(result[percentRange]) ?? 0
            let indicator = generatePercentageIndicator(percent)
            result = result.replacingOccurrences(of: "\(percent) percent", with: "\(percent)% \(indicator)")
        }
        
        return result
    }
    
    private func formatListsWithBullets(_ text: String) async -> String {
        var result = text
        
        // Convert suggestions to bullet points
        let suggestions = ["Consider", "Try", "Make sure", "Remember to"]
        for suggestion in suggestions {
            result = result.replacingOccurrences(of: suggestion, with: "• \(suggestion)")
        }
        
        return result
    }
    
    private func generateProgressBar(value: Int, max: Int) -> String {
        let percentage = Double(value) / Double(max)
        let filledSegments = Int(percentage * 10)
        let emptySegments = 10 - filledSegments
        
        return String(repeating: "█", count: filledSegments) + String(repeating: "░", count: emptySegments)
    }
    
    private func generatePercentageIndicator(_ percent: Int) -> String {
        switch percent {
        case 90...100: return "🟢"
        case 70...89: return "🟡"
        case 50...69: return "🟠"
        default: return "🔴"
        }
    }
    
    // MARK: - Follow-up Suggestions
    
    func generateFollowUpSuggestions(for response: ContextualHealthResponse) async -> [String] {
        var suggestions: [String] = []
        
        // Generate suggestions based on response content
        if response.baseResponse.contains("heart rate") {
            suggestions.append("Show my heart rate trends")
            suggestions.append("Compare to last week")
            suggestions.append("Set heart rate goal")
        }
        
        if response.baseResponse.contains("sleep") {
            suggestions.append("Sleep tips")
            suggestions.append("Set bedtime reminder")
            suggestions.append("View sleep history")
        }
        
        if response.baseResponse.contains("steps") {
            suggestions.append("Start a walk")
            suggestions.append("View step history")
            suggestions.append("Increase daily goal")
        }
        
        if response.baseResponse.contains("water") {
            suggestions.append("Log water intake")
            suggestions.append("Set hydration reminder")
            suggestions.append("Adjust water goal")
        }
        
        if response.baseResponse.contains("workout") {
            suggestions.append("Start new workout")
            suggestions.append("View workout history")
            suggestions.append("Set fitness goal")
        }
        
        // Add contextual suggestions based on insights
        for insight in response.insights {
            switch insight.type {
            case .cardiovascular:
                suggestions.append("Learn about heart health")
            case .sleep:
                suggestions.append("Improve sleep quality")
            case .activity:
                suggestions.append("Increase daily activity")
            case .nutrition:
                suggestions.append("Nutrition tips")
            case .mental:
                suggestions.append("Stress management")
            case .general:
                suggestions.append("Overall health tips")
            }
        }
        
        // Add time-based suggestions
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            suggestions.append("Plan today's activities")
        } else if hour > 18 {
            suggestions.append("Review today's progress")
        }
        
        // Remove duplicates and limit to 5 suggestions
        let uniqueSuggestions = Array(Set(suggestions)).prefix(5)
        return Array(uniqueSuggestions)
    }
    
    // MARK: - Accessibility Formatting
    
    func formatForAccessibility(_ text: String) async -> String {
        var accessibleText = text
        
        // Add descriptive text for screen readers
        accessibleText = await addScreenReaderDescriptions(accessibleText)
        
        // Simplify complex phrases
        accessibleText = await simplifyComplexPhrases(accessibleText)
        
        // Add pronunciation guides
        accessibleText = await addPronunciationGuides(accessibleText)
        
        return accessibleText
    }
    
    private func addScreenReaderDescriptions(_ text: String) async -> String {
        var result = text
        
        // Add context for numbers
        result = result.replacingOccurrences(of: "75", with: "seventy-five")
        result = result.replacingOccurrences(of: "8.5", with: "eight point five")
        result = result.replacingOccurrences(of: "10,000", with: "ten thousand")
        
        // Add context for symbols
        result = result.replacingOccurrences(of: "%", with: " percent")
        result = result.replacingOccurrences(of: "°", with: " degrees")
        
        return result
    }
    
    private func simplifyComplexPhrases(_ text: String) async -> String {
        var result = text
        
        // Simplify medical terms
        result = result.replacingOccurrences(of: "cardiovascular", with: "heart and blood vessel")
        result = result.replacingOccurrences(of: "respiratory", with: "breathing")
        result = result.replacingOccurrences(of: "metabolic", with: "body energy")
        
        // Simplify technical terms
        result = result.replacingOccurrences(of: "sleep efficiency", with: "quality of sleep")
        result = result.replacingOccurrences(of: "heart rate variability", with: "heart rhythm changes")
        
        return result
    }
    
    private func addPronunciationGuides(_ text: String) async -> String {
        var result = text
        
        // Add pronunciation for medical terms
        result = result.replacingOccurrences(of: "BPM", with: "B-P-M")
        result = result.replacingOccurrences(of: "ECG", with: "E-C-G")
        result = result.replacingOccurrences(of: "BMI", with: "B-M-I")
        
        return result
    }
    
    // MARK: - Conversation Context
    
    func formatWithConversationContext(_ text: String, previousResponses: [String]) async -> String {
        var contextualText = text
        
        // Add continuity phrases
        if !previousResponses.isEmpty {
            contextualText = await addContinuityPhrases(contextualText, previousResponses: previousResponses)
        }
        
        // Avoid repetition
        contextualText = await avoidRepetition(contextualText, previousResponses: previousResponses)
        
        // Add conversational transitions
        contextualText = await addConversationalTransitions(contextualText)
        
        return contextualText
    }
    
    private func addContinuityPhrases(_ text: String, previousResponses: [String]) async -> String {
        var result = text
        
        // Add phrases that connect to previous conversation
        if previousResponses.contains(where: { $0.contains("heart rate") }) {
            result = "Speaking of your heart rate, " + result.lowercased()
        }
        
        if previousResponses.contains(where: { $0.contains("sleep") }) {
            result = "Regarding your sleep, " + result.lowercased()
        }
        
        return result
    }
    
    private func avoidRepetition(_ text: String, previousResponses: [String]) async -> String {
        var result = text
        
        // Check for repeated phrases and vary them
        for previousResponse in previousResponses {
            if previousResponse.contains("That's excellent") && result.contains("That's excellent") {
                result = result.replacingOccurrences(of: "That's excellent", with: "That's fantastic")
            }
            
            if previousResponse.contains("Great job") && result.contains("Great job") {
                result = result.replacingOccurrences(of: "Great job", with: "Well done")
            }
        }
        
        return result
    }
    
    private func addConversationalTransitions(_ text: String) async -> String {
        var result = text
        
        // Add natural conversation starters
        let starters = ["By the way,", "Also,", "Additionally,", "Furthermore,"]
        let randomStarter = starters.randomElement() ?? ""
        
        if result.contains("Consider") {
            result = result.replacingOccurrences(of: "Consider", with: "\(randomStarter) consider")
        }
        
        return result
    }
    
    // MARK: - Data Visualization Text
    
    func generateDataVisualizationText(for dataType: String, value: Double, context: String) -> String {
        switch dataType.lowercased() {
        case "heart rate":
            return generateHeartRateVisualization(value: value, context: context)
        case "sleep":
            return generateSleepVisualization(value: value, context: context)
        case "steps":
            return generateStepsVisualization(value: value, context: context)
        case "water":
            return generateWaterVisualization(value: value, context: context)
        default:
            return generateGenericVisualization(value: value, context: context)
        }
    }
    
    private func generateHeartRateVisualization(value: Double, context: String) -> String {
        let heartIcons = String(repeating: "❤️", count: min(5, Int(value / 20)))
        return "\(heartIcons) \(Int(value)) BPM"
    }
    
    private func generateSleepVisualization(value: Double, context: String) -> String {
        let sleepIcons = String(repeating: "😴", count: min(5, Int(value / 2)))
        let hours = Int(value)
        let minutes = Int((value - Double(hours)) * 60)
        return "\(sleepIcons) \(hours)h \(minutes)m"
    }
    
    private func generateStepsVisualization(value: Double, context: String) -> String {
        let stepIcons = String(repeating: "👣", count: min(5, Int(value / 2000)))
        return "\(stepIcons) \(Int(value)) steps"
    }
    
    private func generateWaterVisualization(value: Double, context: String) -> String {
        let waterIcons = String(repeating: "💧", count: min(5, Int(value / 10)))
        return "\(waterIcons) \(Int(value)) oz"
    }
    
    private func generateGenericVisualization(value: Double, context: String) -> String {
        return "📊 \(value)"
    }
}