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
        // [RESOLVED 2025-07-05] Add or update a 3D overlay for the given metric
        let node = SCNNode(geometry: SCNBox(width: 0.1, height: CGFloat(value/100.0), length: 0.1, chamferRadius: 0.01))
        node.position = SCNVector3(0, Float(value/100.0), -0.5)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        arView?.scene.rootNode.addChildNode(node)
    }
    
    private func handleARCommand(_ command: String, params: [String: Any]) {
        switch command {
        case "visualizeSleepArchitecture":
            if let stages = params["stages"] as? [String: Double] {
                visualizeSleepArchitecture(stages: stages)
            }
        case "highlight":
            if let position = params["position"] as? [Double], position.count == 3 {
                highlightNode(at: SCNVector3(position[0], position[1], position[2]))
            }
        case "animate":
            if let nodeId = params["nodeId"] as? String {
                animateNode(with: nodeId)
            }
        default:
            print("Unknown AR command: \(command)")
        }
    }
    
    private func visualizeSleepArchitecture(stages: [String: Double]) {
        // Clear any existing sleep visualization
        arView?.scene.rootNode.childNodes.filter { $0.name?.hasPrefix("sleepStage_") == true }
            .forEach { $0.removeFromParentNode() }
        
        // Create visualization for each sleep stage
        var xOffset: Float = -0.3
        for (stage, duration) in stages {
            let height = Float(duration / 60.0 * 0.1) // Scale duration to height
            let node = SCNNode(geometry: SCNBox(width: 0.1, height: CGFloat(height), length: 0.05, chamferRadius: 0.01))
            node.position = SCNVector3(xOffset, height/2, -0.5)
            node.name = "sleepStage_\(stage)"
            
            // Color coding for different sleep stages
            switch stage {
            case "awake": node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemRed
            case "rem": node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
            case "light": node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGreen
            case "deep": node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPurple
            default: node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
            }
            
            // Add label
            let text = SCNText(string: "\(stage)\n\(Int(duration)) min", extrusionDepth: 0.5)
            let textNode = SCNNode(geometry: text)
            textNode.position = SCNVector3(xOffset, height + 0.05, -0.5)
            textNode.scale = SCNVector3(0.003, 0.003, 0.003)
            textNode.name = "sleepStageLabel_\(stage)"
            
            arView?.scene.rootNode.addChildNode(node)
            arView?.scene.rootNode.addChildNode(textNode)
            
            xOffset += 0.15
        }
    }
    
    private func highlightNode(at position: SCNVector3) {
        let sphere = SCNSphere(radius: 0.05)
        sphere.firstMaterial?.diffuse.contents = UIColor.yellow
        let node = SCNNode(geometry: sphere)
        node.position = position
        node.name = "highlightNode"
        arView?.scene.rootNode.addChildNode(node)
        
        // Animate the highlight
        let fadeOut = SCNAction.fadeOut(duration: 2.0)
        let remove = SCNAction.removeFromParentNode()
        node.runAction(SCNAction.sequence([fadeOut, remove]))
    }
    
    private func animateNode(with nodeId: String) {
        guard let node = arView?.scene.rootNode.childNode(withName: nodeId, recursively: true) else { return }
        
        let rotate = SCNAction.rotateBy(x: 0, y: .pi*2, z: 0, duration: 2.0)
        node.runAction(SCNAction.repeatForever(rotate))
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
