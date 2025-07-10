import SwiftUI

// MARK: - Drag Drop Animations
/// Comprehensive drag and drop animations for enhanced user experience
/// Provides smooth, intuitive drag and drop interactions for reordering and organization
public struct DragDropAnimations {
    
    // MARK: - List Reorder Animation
    
    /// Drag and drop animation for reordering list items
    public struct ListReorderAnimation: View {
        let items: [ReorderableItem]
        let onReorder: ([ReorderableItem]) -> Void
        @State private var draggedItem: ReorderableItem?
        @State private var draggedOffset: CGSize = .zero
        @State private var reorderedItems: [ReorderableItem]
        
        public init(
            items: [ReorderableItem],
            onReorder: @escaping ([ReorderableItem]) -> Void
        ) {
            self.items = items
            self.onReorder = onReorder
            self._reorderedItems = State(initialValue: items)
        }
        
        public var body: some View {
            LazyVStack(spacing: 8) {
                ForEach(reorderedItems) { item in
                    ListItemView(item: item)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                        .scaleEffect(draggedItem?.id == item.id ? 1.05 : 1.0)
                        .offset(draggedItem?.id == item.id ? draggedOffset : .zero)
                        .zIndex(draggedItem?.id == item.id ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: draggedItem?.id == item.id)
                        .onDrag {
                            draggedItem = item
                            return NSItemProvider(object: item.id as NSString)
                        }
                        .onDrop(of: [.text], delegate: DropDelegate(
                            item: item,
                            items: $reorderedItems,
                            draggedItem: $draggedItem,
                            draggedOffset: $draggedOffset,
                            onReorder: onReorder
                        ))
                }
            }
            .padding()
        }
    }
    
    // MARK: - Card Stack Animation
    
    /// Drag and drop animation for card stack interactions
    public struct CardStackAnimation: View {
        let cards: [CardItem]
        let onCardAction: (CardAction, CardItem) -> Void
        @State private var draggedCard: CardItem?
        @State private var draggedOffset: CGSize = .zero
        @State private var cardRotation: Double = 0
        @State private var cardScale: CGFloat = 1.0
        
        public init(
            cards: [CardItem],
            onCardAction: @escaping (CardAction, CardItem) -> Void
        ) {
            self.cards = cards
            self.onCardAction = onCardAction
        }
        
        public var body: some View {
            ZStack {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    CardView(card: card)
                        .offset(draggedCard?.id == card.id ? draggedOffset : .zero)
                        .rotationEffect(.degrees(draggedCard?.id == card.id ? cardRotation : 0))
                        .scaleEffect(draggedCard?.id == card.id ? cardScale : 1.0)
                        .zIndex(draggedCard?.id == card.id ? 100 : Double(cards.count - index))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if draggedCard?.id == card.id {
                                        draggedOffset = value.translation
                                        
                                        // Calculate rotation based on horizontal movement
                                        let rotationFactor = value.translation.x / 200
                                        cardRotation = rotationFactor * 15
                                        
                                        // Calculate scale based on vertical movement
                                        let scaleFactor = 1.0 - abs(value.translation.y) / 1000
                                        cardScale = max(0.8, scaleFactor)
                                    }
                                }
                                .onEnded { value in
                                    if draggedCard?.id == card.id {
                                        let threshold: CGFloat = 100
                                        
                                        if abs(value.translation.x) > threshold {
                                            // Swipe left or right
                                            let action: CardAction = value.translation.x > 0 ? .like : .dislike
                                            onCardAction(action, card)
                                            
                                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                                draggedOffset = CGSize(
                                                    width: value.translation.x > 0 ? 500 : -500,
                                                    height: value.translation.y
                                                )
                                                cardRotation = value.translation.x > 0 ? 30 : -30
                                                cardScale = 0.5
                                            }
                                        } else if abs(value.translation.y) > threshold {
                                            // Swipe up or down
                                            let action: CardAction = value.translation.y > 0 ? .save : .share
                                            onCardAction(action, card)
                                            
                                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                                draggedOffset = CGSize(
                                                    width: value.translation.x,
                                                    height: value.translation.y > 0 ? 500 : -500
                                                )
                                                cardScale = 0.5
                                            }
                                        } else {
                                            // Snap back
                                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                                draggedOffset = .zero
                                                cardRotation = 0
                                                cardScale = 1.0
                                            }
                                        }
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            draggedCard = nil
                                            draggedOffset = .zero
                                            cardRotation = 0
                                            cardScale = 1.0
                                        }
                                    }
                                }
                        )
                        .onTapGesture {
                            draggedCard = card
                        }
                }
            }
        }
    }
    
    // MARK: - Grid Reorder Animation
    
    /// Drag and drop animation for grid layout reordering
    public struct GridReorderAnimation: View {
        let items: [GridItem]
        let columns: Int
        let onReorder: ([GridItem]) -> Void
        @State private var draggedItem: GridItem?
        @State private var draggedOffset: CGSize = .zero
        @State private var reorderedItems: [GridItem]
        @State private var dropTarget: GridItem?
        
        public init(
            items: [GridItem],
            columns: Int = 3,
            onReorder: @escaping ([GridItem]) -> Void
        ) {
            self.items = items
            self.columns = columns
            self.onReorder = onReorder
            self._reorderedItems = State(initialValue: items)
        }
        
        public var body: some View {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 16) {
                ForEach(reorderedItems) { item in
                    GridItemView(item: item)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(dropTarget?.id == item.id ? Color.blue.opacity(0.2) : Color(.systemBackground))
                                .stroke(dropTarget?.id == item.id ? Color.blue : Color.clear, lineWidth: 2)
                        )
                        .scaleEffect(draggedItem?.id == item.id ? 1.1 : 1.0)
                        .offset(draggedItem?.id == item.id ? draggedOffset : .zero)
                        .zIndex(draggedItem?.id == item.id ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: draggedItem?.id == item.id)
                        .onDrag {
                            draggedItem = item
                            return NSItemProvider(object: item.id as NSString)
                        }
                        .onDrop(of: [.text], delegate: GridDropDelegate(
                            item: item,
                            items: $reorderedItems,
                            draggedItem: $draggedItem,
                            draggedOffset: $draggedOffset,
                            dropTarget: $dropTarget,
                            onReorder: onReorder
                        ))
                }
            }
            .padding()
        }
    }
    
    // MARK: - File Drop Animation
    
    /// Drag and drop animation for file uploads
    public struct FileDropAnimation: View {
        let onFileDrop: ([FileItem]) -> Void
        @State private var isDragOver: Bool = false
        @State private var dragScale: CGFloat = 1.0
        @State private var dragRotation: Double = 0
        
        public init(onFileDrop: @escaping ([FileItem]) -> Void) {
            self.onFileDrop = onFileDrop
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Drop zone
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDragOver ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .stroke(isDragOver ? Color.blue : Color(.systemGray4), lineWidth: 2)
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: isDragOver ? "doc.badge.plus" : "doc.badge")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(isDragOver ? .blue : .secondary)
                                .scaleEffect(dragScale)
                                .rotationEffect(.degrees(dragRotation))
                            
                            Text(isDragOver ? "Drop files here" : "Drag files to upload")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(isDragOver ? .blue : .primary)
                            
                            Text("Supports: PDF, Images, Documents")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    )
                    .onDrop(of: [.fileURL, .image], isTargeted: $isDragOver) { providers in
                        handleFileDrop(providers: providers)
                        return true
                    }
                    .onChange(of: isDragOver) { dragging in
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            dragScale = dragging ? 1.1 : 1.0
                            dragRotation = dragging ? 5 : 0
                        }
                    }
                
                // Upload progress
                if isDragOver {
                    VStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.2)
                        
                        Text("Processing files...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding()
        }
        
        private func handleFileDrop(providers: [NSItemProvider]) {
            // Simulate file processing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let mockFiles = [
                    FileItem(name: "document.pdf", size: "2.5 MB", type: .pdf),
                    FileItem(name: "image.jpg", size: "1.8 MB", type: .image)
                ]
                onFileDrop(mockFiles)
            }
        }
    }
    
    // MARK: - Kanban Board Animation
    
    /// Drag and drop animation for Kanban board columns
    public struct KanbanBoardAnimation: View {
        let columns: [KanbanColumn]
        let onMoveTask: (TaskItem, String, String) -> Void
        @State private var draggedTask: TaskItem?
        @State private var draggedOffset: CGSize = .zero
        @State private var dropTarget: String?
        
        public init(
            columns: [KanbanColumn],
            onMoveTask: @escaping (TaskItem, String, String) -> Void
        ) {
            self.columns = columns
            self.onMoveTask = onMoveTask
        }
        
        public var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(columns) { column in
                        KanbanColumnView(
                            column: column,
                            draggedTask: $draggedTask,
                            draggedOffset: $draggedOffset,
                            dropTarget: $dropTarget,
                            onMoveTask: onMoveTask
                        )
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Supporting Views

struct ListItemView: View {
    let item: ReorderableItem
    
    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(item.color)
                .frame(width: 40, height: 40)
                .background(item.color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(item.subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(16)
    }
}

struct CardView: View {
    let card: CardItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: card.icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(card.color)
                .frame(width: 60, height: 60)
                .background(card.color.opacity(0.1))
                .clipShape(Circle())
            
            Text(card.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(card.description)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                ForEach(card.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .frame(width: 280, height: 200)
    }
}

struct GridItemView: View {
    let item: GridItem
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: item.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(item.color)
                .frame(width: 50, height: 50)
                .background(item.color.opacity(0.1))
                .clipShape(Circle())
            
            Text(item.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
    }
}

struct KanbanColumnView: View {
    let column: KanbanColumn
    @Binding var draggedTask: TaskItem?
    @Binding var draggedOffset: CGSize
    @Binding var dropTarget: String?
    let onMoveTask: (TaskItem, String, String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Column header
            HStack {
                Text(column.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(column.tasks.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Tasks
            VStack(spacing: 8) {
                ForEach(column.tasks) { task in
                    TaskItemView(task: task)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(dropTarget == column.id ? Color.blue.opacity(0.1) : Color(.systemBackground))
                                .stroke(dropTarget == column.id ? Color.blue : Color.clear, lineWidth: 1)
                        )
                        .onDrag {
                            draggedTask = task
                            return NSItemProvider(object: task.id as NSString)
                        }
                        .onDrop(of: [.text], delegate: TaskDropDelegate(
                            task: task,
                            column: column,
                            draggedTask: $draggedTask,
                            draggedOffset: $draggedOffset,
                            dropTarget: $dropTarget,
                            onMoveTask: onMoveTask
                        ))
                }
            }
        }
        .frame(width: 250)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TaskItemView: View {
    let task: TaskItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(task.description)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Circle()
                    .fill(task.priority.color)
                    .frame(width: 8, height: 8)
                
                Text(task.priority.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(task.priority.color)
                
                Spacer()
                
                Text(task.dueDate)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
    }
}

// MARK: - Drop Delegates

struct DropDelegate: DropDelegate {
    let item: ReorderableItem
    @Binding var items: [ReorderableItem]
    @Binding var draggedItem: ReorderableItem?
    @Binding var draggedOffset: CGSize
    let onReorder: ([ReorderableItem]) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = draggedItem else { return false }
        
        if let fromIndex = items.firstIndex(where: { $0.id == draggedItem.id }),
           let toIndex = items.firstIndex(where: { $0.id == item.id }) {
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                items.move(fromIndex: fromIndex, toIndex: toIndex)
            }
            
            onReorder(items)
        }
        
        self.draggedItem = nil
        draggedOffset = .zero
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

struct GridDropDelegate: DropDelegate {
    let item: GridItem
    @Binding var items: [GridItem]
    @Binding var draggedItem: GridItem?
    @Binding var draggedOffset: CGSize
    @Binding var dropTarget: GridItem?
    let onReorder: ([GridItem]) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = draggedItem else { return false }
        
        if let fromIndex = items.firstIndex(where: { $0.id == draggedItem.id }),
           let toIndex = items.firstIndex(where: { $0.id == item.id }) {
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                items.move(fromIndex: fromIndex, toIndex: toIndex)
            }
            
            onReorder(items)
        }
        
        self.draggedItem = nil
        draggedOffset = .zero
        dropTarget = nil
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        dropTarget = item
        return DropProposal(operation: .move)
    }
}

struct TaskDropDelegate: DropDelegate {
    let task: TaskItem
    let column: KanbanColumn
    @Binding var draggedTask: TaskItem?
    @Binding var draggedOffset: CGSize
    @Binding var dropTarget: String?
    let onMoveTask: (TaskItem, String, String) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedTask = draggedTask else { return false }
        
        // Find source column
        // This would need to be implemented with the full board state
        let sourceColumn = "source_column_id"
        
        onMoveTask(draggedTask, sourceColumn, column.id)
        
        self.draggedTask = nil
        draggedOffset = .zero
        dropTarget = nil
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        dropTarget = column.id
        return DropProposal(operation: .move)
    }
}

// MARK: - Supporting Types

struct ReorderableItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    init(id: String, title: String, subtitle: String, icon: String, color: Color = .blue) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }
}

struct CardItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    let tags: [String]
    
    init(id: String, title: String, description: String, icon: String, color: Color = .blue, tags: [String] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.tags = tags
    }
}

enum CardAction {
    case like
    case dislike
    case save
    case share
}

struct GridItem: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    
    init(id: String, title: String, icon: String, color: Color = .blue) {
        self.id = id
        self.title = title
        self.icon = icon
        self.color = color
    }
}

struct FileItem {
    let name: String
    let size: String
    let type: FileType
    
    enum FileType {
        case pdf
        case image
        case document
    }
}

struct TaskItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let priority: TaskPriority
    let dueDate: String
    
    init(id: String, title: String, description: String, priority: TaskPriority = .medium, dueDate: String) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.dueDate = dueDate
    }
}

enum TaskPriority: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct KanbanColumn: Identifiable {
    let id: String
    let title: String
    let tasks: [TaskItem]
    
    init(id: String, title: String, tasks: [TaskItem] = []) {
        self.id = id
        self.title = title
        self.tasks = tasks
    }
}

// MARK: - Preview

struct DragDropAnimations_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            ListReorderAnimation(
                items: [
                    ReorderableItem(id: "1", title: "Task 1", subtitle: "Description 1", icon: "checkmark.circle"),
                    ReorderableItem(id: "2", title: "Task 2", subtitle: "Description 2", icon: "clock"),
                    ReorderableItem(id: "3", title: "Task 3", subtitle: "Description 3", icon: "star")
                ]
            ) { _ in }
            
            CardStackAnimation(
                cards: [
                    CardItem(id: "1", title: "Card 1", description: "Description for card 1", icon: "heart.fill", color: .red, tags: ["Health", "Important"]),
                    CardItem(id: "2", title: "Card 2", description: "Description for card 2", icon: "star.fill", color: .yellow, tags: ["Favorite"])
                ]
            ) { _, _ in }
            
            GridReorderAnimation(
                items: [
                    GridItem(id: "1", title: "Item 1", icon: "house"),
                    GridItem(id: "2", title: "Item 2", icon: "car"),
                    GridItem(id: "3", title: "Item 3", icon: "person")
                ]
            ) { _ in }
            
            FileDropAnimation { _ in }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 