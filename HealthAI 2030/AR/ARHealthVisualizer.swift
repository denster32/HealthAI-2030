import Foundation
import ARKit
import SwiftUI

/// ARHealthVisualizer: ARKit-based health data visualization
class ARHealthVisualizer: NSObject, ObservableObject, ARSCNViewDelegate {
    @Published var isSessionActive = false
    private var arView: ARSCNView?
    
    func startSession(in view: ARSCNView) {
        arView = view
        arView?.delegate = self
        let config = ARWorldTrackingConfiguration()
        arView?.session.run(config)
        isSessionActive = true
        addHealthOverlay()
    }
    
    func stopSession() {
        arView?.session.pause()
        isSessionActive = false
    }
    
    private func addHealthOverlay() {
        // Example: Add a 3D heart rate graph in AR
        let node = SCNNode(geometry: SCNBox(width: 0.1, height: 0.02, length: 0.1, chamferRadius: 0.01))
        node.position = SCNVector3(0, 0, -0.5)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        arView?.scene.rootNode.addChildNode(node)
    }
    
    func updateWithSkillResult(_ result: HealthCopilotSkillResult) {
        // Example: If result contains a metric or visualization command, update AR overlay
        switch result {
        case .json(let obj):
            if let metric = obj["arMetric"] as? String, let value = obj["value"] as? Double {
                addOrUpdateMetricOverlay(metric: metric, value: value)
            }
            if let command = obj["arCommand"] as? String {
                handleARCommand(command, params: obj)
            }
            if let group = obj["groupAnalytics"] as? [String: Any],
               let active = group["activeMembers"] as? Int,
               let avg = group["averageSteps"] as? Double,
               let ach = group["sharedAchievements"] as? Int {
                let analytics = GroupAnalytics(activeMembers: active, averageSteps: avg, sharedAchievements: ach)
                visualizeGroupAnalytics(analytics)
            }
            if let nudge = obj["nudgeMessage"] as? String {
                visualizeNudge(nudge)
            }
        default: break
        }
    }
    
    private func addOrUpdateMetricOverlay(metric: String, value: Double) {
        // TODO: Add or update a 3D overlay for the given metric
        // Example: update heart rate, sleep, or other health metric in AR
    }
    
    private func handleARCommand(_ command: String, params: [String: Any]) {
        // TODO: Handle custom AR commands from skills (e.g., highlight, animate, etc)
    }
    
    // MARK: - Group Analytics Visualization
    func visualizeGroupAnalytics(_ analytics: GroupAnalytics) {
        // Example: Show group progress as a 3D bar or badge
        let node = SCNNode(geometry: SCNBox(width: 0.15, height: CGFloat(analytics.averageSteps / 10000.0) * 0.1, length: 0.1, chamferRadius: 0.01))
        node.position = SCNVector3(-0.2, 0, -0.6)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        arView?.scene.rootNode.addChildNode(node)
        // Optionally add text for achievements
        let text = SCNText(string: "Achievements: \(analytics.sharedAchievements)", extrusionDepth: 0.5)
        let textNode = SCNNode(geometry: text)
        textNode.position = SCNVector3(-0.2, 0.08, -0.6)
        textNode.scale = SCNVector3(0.005, 0.005, 0.005)
        arView?.scene.rootNode.addChildNode(textNode)
    }

    // MARK: - Proactive Nudge Visualization
    func visualizeNudge(_ nudge: String) {
        // Example: Show a floating nudge message in AR
        let text = SCNText(string: nudge, extrusionDepth: 0.5)
        let node = SCNNode(geometry: text)
        node.position = SCNVector3(0.2, 0.05, -0.5)
        node.scale = SCNVector3(0.007, 0.007, 0.007)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGreen
        arView?.scene.rootNode.addChildNode(node)
        // Optionally animate or fade out after a delay
    }
}
