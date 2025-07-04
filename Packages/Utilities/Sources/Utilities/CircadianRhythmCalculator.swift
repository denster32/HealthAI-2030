import Foundation

/// Calculates lighting settings based on circadian rhythm principles.
public class CircadianRhythmCalculator {
    
    /// Returns the appropriate color temperature and brightness based on the time of day.
    /// - Returns: A tuple containing the color temperature (in Kelvin) and brightness percentage.
    public func getCurrentLighting() -> (colorTemperature: Int, brightness: Int) {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Early morning (5-8 AM): Bright, cool light to help wake up
        if hour >= 5 && hour < 8 {
            return (6500, 100) // Cool, bright light
        }
        
        // Morning to afternoon (8 AM-2 PM): Bright, neutral light for productivity
        if hour >= 8 && hour < 14 {
            return (5000, 100) // Neutral, bright light
        }
        
        // Afternoon (2-6 PM): Slightly warmer, still bright
        if hour >= 14 && hour < 18 {
            return (4000, 90) // Slightly warm, bright light
        }
        
        // Evening (6-9 PM): Warm, dimming light
        if hour >= 18 && hour < 21 {
            return (3000, 70) // Warm, dimmer light
        }
        
        // Night (9 PM-12 AM): Very warm, dim light
        if hour >= 21 || hour == 0 {
            return (2000, 40) // Very warm, dim light
        }
        
        // Late night/early morning (12-5 AM): Minimal, very warm light
        return (1800, 20) // Extremely warm, very dim light
    }
}