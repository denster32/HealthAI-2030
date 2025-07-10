import SwiftUI

// MARK: - Empty States
/// Comprehensive empty state components for HealthAI 2030
/// Provides empty state illustrations and messaging for various health scenarios
public struct EmptyStates {
    
    // MARK: - Health Data Empty States
    
    /// Empty state for no health data available
    public struct NoHealthDataEmptyState: View {
        let dataType: HealthDataType
        let message: String?
        let actionTitle: String?
        let action: (() -> Void)?
        
        public init(
            dataType: HealthDataType,
            message: String? = nil,
            actionTitle: String? = nil,
            action: (() -> Void)? = nil
        ) {
            self.dataType = dataType
            self.message = message
            self.actionTitle = actionTitle
            self.action = action
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Illustration
                Image(systemName: dataType.emptyStateIcon)
                    .font(.system(size: 80))
                    .foregroundColor(.secondary)
                    .opacity(0.6)
                
                // Title
                Text(dataType.emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                // Message
                Text(message ?? dataType.emptyStateMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Action button
                if let actionTitle = actionTitle, let action = action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(40)
        }
    }
    
    /// Empty state for no activity data
    public struct NoActivityEmptyState: View {
        let action: (() -> Void)?
        
        public init(action: (() -> Void)? = nil) {
            self.action = action
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Activity illustration
                Image(systemName: "figure.walk")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .opacity(0.6)
                
                Text("No Activity Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Start tracking your daily activity to see your progress and insights. Connect your fitness tracker or manually log your activities.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if let action = action {
                    Button(action: action) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Activity")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(40)
        }
    }
    
    /// Empty state for no sleep data
    public struct NoSleepEmptyState: View {
        let action: (() -> Void)?
        
        public init(action: (() -> Void)? = nil) {
            self.action = action
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Sleep illustration
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .opacity(0.6)
                
                Text("No Sleep Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Track your sleep patterns to understand your rest quality and get personalized recommendations for better sleep.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if let action = action {
                    Button(action: action) {
                        HStack(spacing: 8) {
                            Image(systemName: "moon.fill")
                            Text("Start Sleep Tracking")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(40)
        }
    }
    
    /// Empty state for no heart rate data
    public struct NoHeartRateEmptyState: View {
        let action: (() -> Void)?
        
        public init(action: (() -> Void)? = nil) {
            self.action = action
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Heart rate illustration
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .opacity(0.6)
                
                Text("No Heart Rate Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Connect your heart rate monitor or wearable device to track your cardiovascular health and get insights into your fitness levels.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if let action = action {
                    Button(action: action) {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.circle.fill")
                            Text("Connect Device")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(40)
        }
    }
    
    // MARK: - Search Empty States
    
    /// Empty state for no search results
    public struct NoSearchResultsEmptyState: View {
        let searchTerm: String
        let suggestions: [String]
        
        public init(searchTerm: String, suggestions: [String] = []) {
            self.searchTerm = searchTerm
            self.suggestions = suggestions
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Search illustration
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 80))
                    .foregroundColor(.secondary)
                    .opacity(0.6)
                
                Text("No Results Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("We couldn't find any results for \"\(searchTerm)\". Try adjusting your search terms or browse our categories.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Try searching for:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        ForEach(suggestions, id: \.self) { suggestion in
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text(suggestion)
                                    .font(.body)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding(40)
        }
    }
    
    // MARK: - Connection Empty States
    
    /// Empty state for no connected devices
    public struct NoConnectedDevicesEmptyState: View {
        let action: (() -> Void)?
        
        public init(action: (() -> Void)? = nil) {
            self.action = action
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Device illustration
                Image(systemName: "iphone")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .opacity(0.6)
                
                Text("No Connected Devices")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Connect your health devices to automatically sync your data and get comprehensive health insights.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if let action = action {
                    Button(action: action) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Device")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(40)
        }
    }
    
    // MARK: - Goals Empty States
    
    /// Empty state for no health goals
    public struct NoHealthGoalsEmptyState: View {
        let action: (() -> Void)?
        
        public init(action: (() -> Void)? = nil) {
            self.action = action
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Goal illustration
                Image(systemName: "target")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                    .opacity(0.6)
                
                Text("No Health Goals Set")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Set personalized health goals to track your progress and stay motivated on your wellness journey.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if let action = action {
                    Button(action: action) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Goal")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(40)
        }
    }
    
    // MARK: - Generic Empty State
    
    /// Generic empty state component
    public struct GenericEmptyState: View {
        let icon: String
        let title: String
        let message: String
        let actionTitle: String?
        let action: (() -> Void)?
        let iconColor: Color
        
        public init(
            icon: String,
            title: String,
            message: String,
            actionTitle: String? = nil,
            action: (() -> Void)? = nil,
            iconColor: Color = .blue
        ) {
            self.icon = icon
            self.title = title
            self.message = message
            self.actionTitle = actionTitle
            self.action = action
            self.iconColor = iconColor
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 80))
                    .foregroundColor(iconColor)
                    .opacity(0.6)
                
                // Title
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                // Message
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Action button
                if let actionTitle = actionTitle, let action = action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(iconColor)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(40)
        }
    }
}

// MARK: - Supporting Types

public enum HealthDataType {
    case activity
    case sleep
    case heartRate
    case bloodPressure
    case weight
    case nutrition
    case medication
    case mood
    case custom(String)
    
    var emptyStateIcon: String {
        switch self {
        case .activity:
            return "figure.walk"
        case .sleep:
            return "bed.double.fill"
        case .heartRate:
            return "heart.fill"
        case .bloodPressure:
            return "drop.fill"
        case .weight:
            return "scalemass.fill"
        case .nutrition:
            return "fork.knife"
        case .medication:
            return "pills.fill"
        case .mood:
            return "brain.head.profile"
        case .custom:
            return "chart.bar.fill"
        }
    }
    
    var emptyStateTitle: String {
        switch self {
        case .activity:
            return "No Activity Data"
        case .sleep:
            return "No Sleep Data"
        case .heartRate:
            return "No Heart Rate Data"
        case .bloodPressure:
            return "No Blood Pressure Data"
        case .weight:
            return "No Weight Data"
        case .nutrition:
            return "No Nutrition Data"
        case .medication:
            return "No Medication Data"
        case .mood:
            return "No Mood Data"
        case .custom(let name):
            return "No \(name) Data"
        }
    }
    
    var emptyStateMessage: String {
        switch self {
        case .activity:
            return "Start tracking your daily activity to see your progress and insights."
        case .sleep:
            return "Track your sleep patterns to understand your rest quality."
        case .heartRate:
            return "Connect your heart rate monitor to track your cardiovascular health."
        case .bloodPressure:
            return "Log your blood pressure readings to monitor your cardiovascular health."
        case .weight:
            return "Track your weight changes to monitor your health journey."
        case .nutrition:
            return "Log your meals and nutrition to understand your dietary patterns."
        case .medication:
            return "Track your medications to ensure proper adherence."
        case .mood:
            return "Log your mood to understand your mental health patterns."
        case .custom:
            return "Start tracking this data to get personalized insights."
        }
    }
}

// MARK: - Extensions

public extension EmptyStates {
    /// Create empty state for specific health data type
    static func forHealthDataType(
        _ dataType: HealthDataType,
        action: (() -> Void)? = nil
    ) -> some View {
        NoHealthDataEmptyState(
            dataType: dataType,
            action: action
        )
    }
    
    /// Create empty state for search results
    static func forSearchResults(
        searchTerm: String,
        suggestions: [String] = []
    ) -> some View {
        NoSearchResultsEmptyState(
            searchTerm: searchTerm,
            suggestions: suggestions
        )
    }
} 