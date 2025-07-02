import ActivityKit
import WidgetKit
import SwiftUI

struct HealthLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HealthActivityAttributes.self) { context in
            // MARK: - Live Activity Compact and Minimal Presentation
            // This content is displayed in the Dynamic Island and Lock Screen when space is limited.
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("Heart Rate: \(context.state.heartRate) bpm")
                }
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.blue)
                    Text("Steps: \(context.state.steps)")
                }
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Calories: \(context.state.caloriesBurned) kcal")
                }
                Text("Last Updated: \(context.state.lastUpdated, style: .time)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .activityBackgroundBehavior(.content)
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Dynamic Island Expanded Presentation
                DynamicIslandExpandedRegion(.leading) {
                    Label("Health", systemImage: "heart.text.square.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("\(context.state.heartRate) bpm")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text("\(context.state.steps) steps")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Calories: \(context.state.caloriesBurned) kcal")
                        Spacer()
                        Button("Dismiss") {
                            // This action will be handled by the main app
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } compactLeading: {
                // MARK: - Dynamic Island Compact Leading
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
            } compactTrailing: {
                // MARK: - Dynamic Island Compact Trailing
                Text("\(context.state.heartRate) bpm")
                    .foregroundColor(.red)
            } minimal: {
                // MARK: - Dynamic Island Minimal
                VStack(alignment: .center) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("\(context.state.heartRate)")
                        .font(.caption2)
                }
            }
            .widgetURL(URL(string: "healthai2030://liveactivity")) // Deep link to app
            .keylineTint(.accentColor)
        }
    }
}

// MARK: - Live Activity Preview
struct HealthLiveActivity_Previews: PreviewProvider {
    static let attributes = HealthActivityAttributes(activityName: "Daily Health", patientName: "John Doe")
    static let contentState = HealthActivityAttributes.ContentState(heartRate: 75, steps: 5000, caloriesBurned: 1500, lastUpdated: Date())

    static var previews: some View {
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.compact))
            .previewDisplayName("Compact")
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
            .previewDisplayName("Expanded")
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
            .previewDisplayName("Minimal")
        attributes
            .previewContext(contentState, viewKind: .lockScreen)
            .previewDisplayName("Lock Screen")
    }
}