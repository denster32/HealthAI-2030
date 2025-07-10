// ResourceAllocationOptimizer.swift
// HealthAI 2030 - Agent 6 Analytics
// Optimizer for healthcare resource allocation

import Foundation

public struct ResourceAllocationRequest {
    public let resourceType: String
    public let quantity: Int
    public let priority: Int
}

public struct ResourceAllocationResult {
    public let allocated: Int
    public let resourceType: String
    public let status: String
}

public class ResourceAllocationOptimizer {
    public init() {}
    
    public func optimizeAllocation(requests: [ResourceAllocationRequest], available: [String: Int]) -> [ResourceAllocationResult] {
        var results: [ResourceAllocationResult] = []
        for request in requests {
            let availableQty = available[request.resourceType] ?? 0
            let allocated = min(request.quantity, availableQty)
            let status = allocated == request.quantity ? "fulfilled" : "partial"
            results.append(ResourceAllocationResult(allocated: allocated, resourceType: request.resourceType, status: status))
        }
        return results
    }
}
