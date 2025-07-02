import XCTest
@testable import HealthAI_2030

class RLAgentTests: XCTestCase {

    var rlAgent: RLAgent!

    override func setUp() {
        super.setUp()
        rlAgent = RLAgent.shared
        // Reset Q-table for consistent testing
        rlAgent.initializeQTable()
    }

    override func tearDown() {
        rlAgent = nil
        super.tearDown()
    }

    func testDetermineNudgeAction_awakeStage() {
        let sleepStage: SleepStageType = .awake
        let environmentData = EnvironmentData(temperature: 25.0, humidity: 60.0, lightLevel: 0.8, airQuality: 0.9, noiseLevel: 50.0, co2Level: 400.0, timestamp: Date())
        
        let action = rlAgent.determineNudgeAction(sleepStage: sleepStage, environmentData: environmentData)
        
        // In a real RL scenario, the action might be non-deterministic due to exploration.
        // For this simplified test, we'll check if it's a valid action or one of the expected initial actions.
        // Given the current rule-based fallback in RLAgent, we expect specific actions.
        
        // Since the RLAgent now has a Q-table and exploration, we can't assert a specific action directly
        // unless we set explorationRate to 0 or mock the Q-table.
        // For a basic test, we'll ensure it's not .none if there are possible actions.
        XCTAssertNotEqual(action, .none, "RLAgent should determine a nudge action for awake stage")
    }

    func testDetermineNudgeAction_deepSleepStage() {
        let sleepStage: SleepStageType = .deepSleep
        let environmentData = EnvironmentData(temperature: 17.0, humidity: 45.0, lightLevel: 0.05, airQuality: 0.95, noiseLevel: 30.0, co2Level: 380.0, timestamp: Date())
        
        let action = rlAgent.determineNudgeAction(sleepStage: sleepStage, environmentData: environmentData)
        
        XCTAssertNotEqual(action, .none, "RLAgent should determine a nudge action for deep sleep stage")
    }

    func testLearnFunction_updatesQTable() {
        let initialSleepStage: SleepStageType = .lightSleep
        let initialEnvironmentData = EnvironmentData(temperature: 20.0, humidity: 50.0, lightLevel: 0.5, airQuality: 0.8, noiseLevel: 40.0, co2Level: 450.0, timestamp: Date())
        let action: NudgeAction = .audio(.isochronicTones, 0.5)
        let reward: Double = 1.0 // Positive reward for a good action
        let nextSleepStage: SleepStageType = .deepSleep
        let nextEnvironmentData = EnvironmentData(temperature: 18.0, humidity: 48.0, lightLevel: 0.1, airQuality: 0.9, noiseLevel: 35.0, co2Level: 400.0, timestamp: Date())

        let initialQValue = rlAgent.qTable[initialSleepStage]?[EnvironmentState(environmentData: initialEnvironmentData)]?[action] ?? 0.0
        
        rlAgent.learn(sleepStage: initialSleepStage, environmentData: initialEnvironmentData, action: action, reward: reward, nextSleepStage: nextSleepStage, nextEnvironmentData: nextEnvironmentData)
        
        let updatedQValue = rlAgent.qTable[initialSleepStage]?[EnvironmentState(environmentData: initialEnvironmentData)]?[action] ?? 0.0
        
        XCTAssertGreaterThan(updatedQValue, initialQValue, "Q-value should increase after positive reward")
    }

    func testEnvironmentStateHashing() {
        let envData1 = EnvironmentData(temperature: 20.1, humidity: 50.4, lightLevel: 0.51, airQuality: 0.8, noiseLevel: 40.3, co2Level: 400.0, timestamp: Date())
        let envData2 = EnvironmentData(temperature: 20.2, humidity: 50.6, lightLevel: 0.49, airQuality: 0.8, noiseLevel: 40.1, co2Level: 400.0, timestamp: Date())
        
        let state1 = EnvironmentState(environmentData: envData1)
        let state2 = EnvironmentState(environmentData: envData2)
        
        // Due to discretization, these might hash to the same value
        XCTAssertEqual(state1, state2, "Environment states should be equal after discretization if values are close")
        XCTAssertEqual(state1.hashValue, state2.hashValue, "Hash values should be equal for equal environment states")
    }
}