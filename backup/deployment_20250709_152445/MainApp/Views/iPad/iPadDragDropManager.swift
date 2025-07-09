import SwiftUI
import UniformTypeIdentifiers

/// Manager for iPad drag and drop functionality
@MainActor
class IPadDragDropManager: ObservableObject {
    @Published var draggedItem: HealthItem?
    @Published var isDragging = false
    @Published var dropTarget: String?
    
    // MARK: - Drag and Drop Types
    
    static let healthItemType = UTType(exportedAs: "com.healthai2030.healthitem")
    static let conversationType = UTType(exportedAs: "com.healthai2030.conversation")
    static let workoutType = UTType(exportedAs: "com.healthai2030.workout")
    static let medicationType = UTType(exportedAs: "com.healthai2030.medication")
    
    // MARK: - Drag Operations
    
    func startDragging(_ item: HealthItem) {
        draggedItem = item
        isDragging = true
    }
    
    func stopDragging() {
        draggedItem = nil
        isDragging = false
        dropTarget = nil
    }
    
    func setDropTarget(_ target: String?) {
        dropTarget = target
    }
    
    // MARK: - Drop Validation
    
    func canAcceptDrop(_ item: HealthItem, target: String) -> Bool {
        switch target {
        case "conversation":
            return item.type.isConversation
        case "workout":
            return item.type.isWorkout
        case "medication":
            return item.type.isMedication
        case "healthData":
            return item.type.isHealthCategory
        case "analytics":
            return true // All items can be analyzed
        default:
            return false
        }
    }
    
    // MARK: - Drop Actions
    
    func performDrop(_ item: HealthItem, target: String) async {
        switch target {
        case "conversation":
            await addToConversation(item)
        case "workout":
            await addToWorkout(item)
        case "medication":
            await addToMedication(item)
        case "healthData":
            await addToHealthData(item)
        case "analytics":
            await addToAnalytics(item)
        default:
            break
        }
    }
    
    // MARK: - Private Drop Actions
    
    private func addToConversation(_ item: HealthItem) async {
        // Add health data to conversation context
        print("Adding \(item.title) to conversation context")
        
        // Simulate async operation
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Update conversation with health data
        // This would integrate with the conversational engine
    }
    
    private func addToWorkout(_ item: HealthItem) async {
        // Add health data to workout planning
        print("Adding \(item.title) to workout planning")
        
        // Simulate async operation
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Update workout recommendations based on health data
    }
    
    private func addToMedication(_ item: HealthItem) async {
        // Add health data to medication tracking
        print("Adding \(item.title) to medication tracking")
        
        // Simulate async operation
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Update medication recommendations based on health data
    }
    
    private func addToHealthData(_ item: HealthItem) async {
        // Add health data to health data section
        print("Adding \(item.title) to health data section")
        
        // Simulate async operation
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Update health data organization
    }
    
    private func addToAnalytics(_ item: HealthItem) async {
        // Add health data to analytics
        print("Adding \(item.title) to analytics")
        
        // Simulate async operation
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Update analytics with new data point
    }
}

// MARK: - Drag and Drop View Modifiers

struct DraggableModifier: ViewModifier {
    let item: HealthItem
    @ObservedObject var dragDropManager: IPadDragDropManager
    
    func body(content: Content) -> some View {
        content
            .onDrag {
                dragDropManager.startDragging(item)
                return NSItemProvider(object: HealthItemProvider(item: item))
            }
            .onDragEnd { _ in
                dragDropManager.stopDragging()
            }
            .scaleEffect(dragDropManager.isDragging && dragDropManager.draggedItem?.id == item.id ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: dragDropManager.isDragging)
    }
}

struct DroppableModifier: ViewModifier {
    let target: String
    @ObservedObject var dragDropManager: IPadDragDropManager
    
    func body(content: Content) -> some View {
        content
            .onDrop(
                of: [IPadDragDropManager.healthItemType],
                isTargeted: { isTargeted in
                    dragDropManager.setDropTarget(isTargeted ? target : nil)
                }
            ) { providers in
                Task {
                    for provider in providers {
                        if let healthItem = await provider.loadHealthItem() {
                            if dragDropManager.canAcceptDrop(healthItem, target: target) {
                                await dragDropManager.performDrop(healthItem, target: target)
                            }
                        }
                    }
                }
                return true
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(dragDropManager.dropTarget == target ? Color.blue.opacity(0.1) : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: dragDropManager.dropTarget)
            )
    }
}

// MARK: - View Extensions

extension View {
    func draggable(_ item: HealthItem, dragDropManager: IPadDragDropManager) -> some View {
        modifier(DraggableModifier(item: item, dragDropManager: dragDropManager))
    }
    
    func droppable(_ target: String, dragDropManager: IPadDragDropManager) -> some View {
        modifier(DroppableModifier(target: target, dragDropManager: dragDropManager))
    }
}

// MARK: - NSItemProvider Support

class HealthItemProvider: NSObject, NSItemProviderWriting {
    static let writableTypeIdentifiersForItemProvider = [IPadDragDropManager.healthItemType.identifier]
    
    let item: HealthItem
    
    init(item: HealthItem) {
        self.item = item
        super.init()
    }
    
    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        do {
            let data = try JSONEncoder().encode(item)
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        return nil
    }
}

extension NSItemProvider {
    func loadHealthItem() async -> HealthItem? {
        await withCheckedContinuation { continuation in
            loadObject(ofClass: HealthItemProvider.self) { provider, error in
                if let provider = provider as? HealthItemProvider {
                    continuation.resume(returning: provider.item)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

// MARK: - HealthItem Type Extensions

extension HealthItem.ItemType {
    var isConversation: Bool {
        if case .conversation = self {
            return true
        }
        return false
    }
    
    var isWorkout: Bool {
        if case .workout = self {
            return true
        }
        return false
    }
    
    var isMedication: Bool {
        if case .medication = self {
            return true
        }
        return false
    }
    
    var isHealthCategory: Bool {
        if case .healthCategory = self {
            return true
        }
        return false
    }
}

// MARK: - Drag and Drop Preview

struct DragDropPreview: View {
    @StateObject private var dragDropManager = IPadDragDropManager()
    
    var body: some View {
        HStack {
            // Draggable items
            VStack {
                Text("Draggable Items")
                    .font(.headline)
                
                ForEach(sampleHealthItems, id: \.id) { item in
                    HealthItemRow(item: item)
                        .draggable(item, dragDropManager: dragDropManager)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
            
            // Drop targets
            VStack {
                Text("Drop Targets")
                    .font(.headline)
                
                VStack(spacing: 16) {
                    DropTargetView(title: "Conversation", target: "conversation", dragDropManager: dragDropManager)
                    DropTargetView(title: "Workout", target: "workout", dragDropManager: dragDropManager)
                    DropTargetView(title: "Medication", target: "medication", dragDropManager: dragDropManager)
                    DropTargetView(title: "Health Data", target: "healthData", dragDropManager: dragDropManager)
                    DropTargetView(title: "Analytics", target: "analytics", dragDropManager: dragDropManager)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
    
    private var sampleHealthItems: [HealthItem] {
        [
            HealthItem(
                title: "Heart Rate",
                subtitle: "Current: 72 BPM",
                type: .healthCategory(.heartRate),
                icon: "heart.fill",
                color: .red
            ),
            HealthItem(
                title: "Morning Check-in",
                subtitle: "How are you feeling?",
                type: .conversation("conv_1"),
                icon: "message.fill",
                color: .blue
            ),
            HealthItem(
                title: "Running",
                subtitle: "30 min workout",
                type: .workout(.running),
                icon: "figure.run",
                color: .green
            )
        ]
    }
}

struct DropTargetView: View {
    let title: String
    let target: String
    @ObservedObject var dragDropManager: IPadDragDropManager
    
    var body: some View {
        Text(title)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .droppable(target, dragDropManager: dragDropManager)
    }
}

struct HealthItemRow: View {
    let item: HealthItem
    
    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .foregroundColor(item.color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(item.subtitle ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(6)
        .shadow(radius: 2)
    }
}

// MARK: - Preview

#Preview {
    DragDropPreview()
} 