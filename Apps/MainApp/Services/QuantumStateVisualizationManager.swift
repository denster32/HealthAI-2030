import Foundation

public class QuantumStateVisualizationManager {
    public init() {}
    
    /// Converts quantum state amplitudes into visualization-friendly data (e.g., Bloch sphere coords).
    public func computeVisualization(amplitudes: [Double]) -> [String: Double] {
        // Implementation of actual mapping from amplitudes to visualization coordinates
        var visualization: [String: Double] = [:]
        
        // For a 2-qubit system, compute Bloch sphere coordinates
        if amplitudes.count >= 4 {
            // Normalize amplitudes
            let norm = sqrt(amplitudes.map { $0 * $0 }.reduce(0, +))
            let normalizedAmplitudes = amplitudes.map { $0 / norm }
            
            // Compute Bloch sphere coordinates for first qubit
            let alpha = normalizedAmplitudes[0]
            let beta = normalizedAmplitudes[1]
            let gamma = normalizedAmplitudes[2]
            let delta = normalizedAmplitudes[3]
            
            // Calculate Bloch sphere coordinates (x, y, z)
            let x1 = 2 * (alpha * beta + gamma * delta)
            let y1 = 2 * (alpha * gamma - beta * delta)
            let z1 = alpha * alpha + beta * beta - gamma * gamma - delta * delta
            
            // Calculate Bloch sphere coordinates for second qubit
            let x2 = 2 * (alpha * gamma + beta * delta)
            let y2 = 2 * (alpha * delta - beta * gamma)
            let z2 = alpha * alpha - beta * beta + gamma * gamma - delta * delta
            
            // Store visualization coordinates
            visualization["qubit1_x"] = x1
            visualization["qubit1_y"] = y1
            visualization["qubit1_z"] = z1
            visualization["qubit2_x"] = x2
            visualization["qubit2_y"] = y2
            visualization["qubit2_z"] = z2
            
            // Calculate entanglement measure (concurrence)
            let concurrence = calculateConcurrence(amplitudes: normalizedAmplitudes)
            visualization["entanglement"] = concurrence
            
            // Calculate purity
            let purity = calculatePurity(amplitudes: normalizedAmplitudes)
            visualization["purity"] = purity
        } else if amplitudes.count == 2 {
            // Single qubit case
            let norm = sqrt(amplitudes.map { $0 * $0 }.reduce(0, +))
            let normalizedAmplitudes = amplitudes.map { $0 / norm }
            
            let alpha = normalizedAmplitudes[0]
            let beta = normalizedAmplitudes[1]
            
            // Bloch sphere coordinates for single qubit
            let x = 2 * alpha * beta
            let y = 0.0 // Assuming real amplitudes
            let z = alpha * alpha - beta * beta
            
            visualization["qubit_x"] = x
            visualization["qubit_y"] = y
            visualization["qubit_z"] = z
            visualization["purity"] = 1.0 // Pure state
        }
        
        // Add amplitude information
        for (index, amp) in amplitudes.enumerated() {
            visualization["amp\(index)"] = amp
        }
        
        return visualization
    }
    
    // MARK: - Private Helper Methods
    
    private func calculateConcurrence(amplitudes: [Double]) -> Double {
        // Calculate concurrence for 2-qubit system
        guard amplitudes.count >= 4 else { return 0.0 }
        
        let a = amplitudes[0]
        let b = amplitudes[1]
        let c = amplitudes[2]
        let d = amplitudes[3]
        
        let term1 = abs(a * d - b * c)
        let term2 = 2 * sqrt(abs(a * c) * abs(b * d))
        
        return max(0.0, term1 - term2)
    }
    
    private func calculatePurity(amplitudes: [Double]) -> Double {
        // Calculate purity of quantum state
        let norm = sqrt(amplitudes.map { $0 * $0 }.reduce(0, +))
        let normalizedAmplitudes = amplitudes.map { $0 / norm }
        
        // For pure state, purity = 1
        // For mixed state, purity < 1
        let purity = normalizedAmplitudes.map { $0 * $0 }.reduce(0, +)
        return purity
    }
} 