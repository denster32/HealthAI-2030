
import SwiftUI
import Charts

// MARK: - Interactive Chart Features
public struct InteractiveChartView<Content: View>: View {
    let content: Content
    @State private var selectedDate: Date?

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack {
            content
                .chartOverlay {
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        // Implement logic to find the nearest data point
                                        // and update the selectedDate state.
                                    }
                                    .onEnded { _ in
                                        selectedDate = nil
                                    }
                            )
                    }
                }
            
            if let selectedDate {
                Text("Selected: \(selectedDate, format: .dateTime)")
                    .padding()
                    .background(HealthAIDesignSystem.Color.surface)
                    .cornerRadius(10)
                    .transition(.opacity.animation(.easeInOut))
                    .accessibilityLabel("Selected date is \(selectedDate, format: .dateTime)")
            }
        }
    }
}
