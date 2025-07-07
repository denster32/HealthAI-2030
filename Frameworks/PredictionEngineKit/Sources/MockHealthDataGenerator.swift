import Foundation
import HealthKit

/// Advanced mock health data generator for comprehensive testing scenarios
public struct MockHealthDataGenerator {
    /// Generates a range of realistic health input scenarios
    public enum HealthScenario {
        case healthy
        case preDiabetic
        case highStress
        case poorSleep
        case cardiovascularRisk
        case metabolicSyndrome
        case random
    }
    
    /// Generate mock health input based on specific scenario
    public static func generateHealthInput(scenario: HealthScenario = .random) -> PreSymptomHealthInput {
        switch scenario {
        case .healthy:
            return healthyIndividualInput()
        case .preDiabetic:
            return preDiabeticInput()
        case .highStress:
            return highStressInput()
        case .poorSleep:
            return poorSleepInput()
        case .cardiovascularRisk:
            return cardiovascularRiskInput()
        case .metabolicSyndrome:
            return metabolicSyndromeInput()
        case .random:
            return randomHealthInput()
        }
    }
    
    /// Generate a comprehensive set of mock health inputs for testing
    public static func generateHealthInputSet(count: Int) -> [PreSymptomHealthInput] {
        return (0..<count).map { _ in generateHealthInput() }
    }
    
    // Scenario-specific input generators
    private static func healthyIndividualInput() -> PreSymptomHealthInput {
        return PreSymptomHealthInput(
            heartRateVariability: Double.random(in: 40.0...60.0),
            bloodPressure: (systolic: Double.random(in: 110...130), diastolic: Double.random(in: 70...85)),
            sleepQuality: Double.random(in: 0.7...1.0),
            physicalActivity: Double.random(in: 0.6...1.0),
            nutritionalIntake: Double.random(in: 0.7...1.0),
            stressLevel: Double.random(in: 0.0...0.3),
            geneticRiskFactors: [
                "cardiovascularDisease": 0.1,
                "diabetes": 0.05
            ],
            environmentalFactors: [
                "pollution": 0.2,
                "altitude": 0.3
            ],
            medicalHistory: [
                "familyHeartDisease": false,
                "diabetes": false
            ]
        )
    }
    
    private static func preDiabeticInput() -> PreSymptomHealthInput {
        return PreSymptomHealthInput(
            heartRateVariability: Double.random(in: 30.0...50.0),
            bloodPressure: (systolic: Double.random(in: 130...150), diastolic: Double.random(in: 85...95)),
            sleepQuality: Double.random(in: 0.4...0.7),
            physicalActivity: Double.random(in: 0.3...0.6),
            nutritionalIntake: Double.random(in: 0.4...0.7),
            stressLevel: Double.random(in: 0.4...0.7),
            geneticRiskFactors: [
                "diabetes": 0.6,
                "obesity": 0.5
            ],
            environmentalFactors: [
                "sedentaryLifestyle": 0.7,
                "sugarConsumption": 0.6
            ],
            medicalHistory: [
                "familyDiabetes": true,
                "prediabetes": true
            ]
        )
    }
    
    private static func highStressInput() -> PreSymptomHealthInput {
        return PreSymptomHealthInput(
            heartRateVariability: Double.random(in: 20.0...40.0),
            bloodPressure: (systolic: Double.random(in: 140...160), diastolic: Double.random(in: 90...100)),
            sleepQuality: Double.random(in: 0.2...0.5),
            physicalActivity: Double.random(in: 0.1...0.4),
            nutritionalIntake: Double.random(in: 0.3...0.6),
            stressLevel: Double.random(in: 0.7...1.0),
            geneticRiskFactors: [
                "mentalHealth": 0.5,
                "anxiety": 0.6
            ],
            environmentalFactors: [
                "workPressure": 0.8,
                "socialStress": 0.7
            ],
            medicalHistory: [
                "anxiety": true,
                "burnout": true
            ]
        )
    }
    
    private static func poorSleepInput() -> PreSymptomHealthInput {
        return PreSymptomHealthInput(
            heartRateVariability: Double.random(in: 25.0...45.0),
            bloodPressure: (systolic: Double.random(in: 125...145), diastolic: Double.random(in: 80...95)),
            sleepQuality: Double.random(in: 0.0...0.3),
            physicalActivity: Double.random(in: 0.2...0.5),
            nutritionalIntake: Double.random(in: 0.4...0.7),
            stressLevel: Double.random(in: 0.5...0.8),
            geneticRiskFactors: [
                "sleepDisorders": 0.5,
                "insomnia": 0.4
            ],
            environmentalFactors: [
                "nightShiftWork": 0.6,
                "screenTime": 0.7
            ],
            medicalHistory: [
                "sleepApnea": true,
                "chronicInsomnia": true
            ]
        )
    }
    
    private static func cardiovascularRiskInput() -> PreSymptomHealthInput {
        return PreSymptomHealthInput(
            heartRateVariability: Double.random(in: 20.0...40.0),
            bloodPressure: (systolic: Double.random(in: 150...180), diastolic: Double.random(in: 95...110)),
            sleepQuality: Double.random(in: 0.3...0.6),
            physicalActivity: Double.random(in: 0.1...0.4),
            nutritionalIntake: Double.random(in: 0.2...0.5),
            stressLevel: Double.random(in: 0.5...0.8),
            geneticRiskFactors: [
                "heartDisease": 0.7,
                "cholesterol": 0.6
            ],
            environmentalFactors: [
                "smoking": 0.5,
                "sedentaryLifestyle": 0.7
            ],
            medicalHistory: [
                "heartAttack": true,
                "highCholesterol": true
            ]
        )
    }
    
    private static func metabolicSyndromeInput() -> PreSymptomHealthInput {
        return PreSymptomHealthInput(
            heartRateVariability: Double.random(in: 25.0...45.0),
            bloodPressure: (systolic: Double.random(in: 140...160), diastolic: Double.random(in: 90...100)),
            sleepQuality: Double.random(in: 0.2...0.5),
            physicalActivity: Double.random(in: 0.1...0.4),
            nutritionalIntake: Double.random(in: 0.2...0.5),
            stressLevel: Double.random(in: 0.5...0.8),
            geneticRiskFactors: [
                "obesity": 0.7,
                "diabetes": 0.6,
                "metabolicSyndrome": 0.5
            ],
            environmentalFactors: [
                "dietQuality": 0.3,
                "physicalInactivity": 0.7
            ],
            medicalHistory: [
                "diabetes": true,
                "obesity": true,
                "hypertension": true
            ]
        )
    }
    
    private static func randomHealthInput() -> PreSymptomHealthInput {
        return PreSymptomHealthInput(
            heartRateVariability: Double.random(in: 20.0...70.0),
            bloodPressure: (systolic: Double.random(in: 100...180), diastolic: Double.random(in: 60...110)),
            sleepQuality: Double.random(in: 0.0...1.0),
            physicalActivity: Double.random(in: 0.0...1.0),
            nutritionalIntake: Double.random(in: 0.0...1.0),
            stressLevel: Double.random(in: 0.0...1.0),
            geneticRiskFactors: Dictionary(uniqueKeysWithValues: (0..<3).map { _ in
                (UUID().uuidString, Double.random(in: 0.0...1.0))
            }),
            environmentalFactors: Dictionary(uniqueKeysWithValues: (0..<3).map { _ in
                (UUID().uuidString, Double.random(in: 0.0...1.0))
            }),
            medicalHistory: Dictionary(uniqueKeysWithValues: (0..<3).map { _ in
                (UUID().uuidString, Bool.random())
            })
        )
    }
}

/// Extension to provide more advanced mock data generation capabilities
public extension MockHealthDataGenerator {
    /// Generate a stress test dataset with various health scenarios
    static func generateStressTestDataset(scenarioCount: Int = 1000) -> [PreSymptomHealthInput] {
        let scenarios: [HealthScenario] = [
            .healthy, .preDiabetic, .highStress, 
            .poorSleep, .cardiovascularRisk, .metabolicSyndrome
        ]
        
        return (0..<scenarioCount).map { _ in
            let scenario = scenarios.randomElement() ?? .random
            return generateHealthInput(scenario: scenario)
        }
    }
    
    /// Generate edge case health inputs for robust testing
    static func generateEdgeCaseInputs() -> [PreSymptomHealthInput] {
        return [
            // Extreme low values
            PreSymptomHealthInput(
                heartRateVariability: 0.0,
                bloodPressure: (systolic: 50, diastolic: 30),
                sleepQuality: 0.0,
                physicalActivity: 0.0,
                nutritionalIntake: 0.0,
                stressLevel: 0.0
            ),
            // Extreme high values
            PreSymptomHealthInput(
                heartRateVariability: 100.0,
                bloodPressure: (systolic: 200, diastolic: 120),
                sleepQuality: 1.0,
                physicalActivity: 1.0,
                nutritionalIntake: 1.0,
                stressLevel: 1.0
            ),
            // NaN and Infinity values
            PreSymptomHealthInput(
                heartRateVariability: Double.nan,
                bloodPressure: (systolic: Double.infinity, diastolic: -Double.infinity),
                sleepQuality: Double.nan,
                physicalActivity: Double.nan,
                nutritionalIntake: Double.nan,
                stressLevel: Double.nan
            )
        ]
    }
} 