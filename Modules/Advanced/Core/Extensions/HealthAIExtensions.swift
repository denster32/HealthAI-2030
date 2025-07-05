import Foundation
import SwiftUI
import Combine

// MARK: - Foundation Extensions

extension String {
    /// Validates if the string is a valid email format
    public var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Validates if the string is a valid phone number
    public var isValidPhoneNumber: Bool {
        let phoneRegex = "^[+]?[0-9]{10,15}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: self)
    }
    
    /// Converts string to URL safely
    public var safeURL: URL? {
        return URL(string: self)
    }
    
    /// Truncates string to specified length with ellipsis
    public func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count <= length {
            return self
        }
        return String(self.prefix(length)) + trailing
    }
    
    /// Capitalizes first letter of each word
    public var titleCase: String {
        return self.capitalized(with: Locale.current)
    }
    
    /// Removes all whitespace and newlines
    public var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Date {
    /// Returns a formatted string for display
    public func formattedString(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }
    
    /// Returns relative time string (e.g., "2 hours ago")
    public var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Returns start of day
    public var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// Returns end of day
    public var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    /// Returns start of week
    public var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Returns start of month
    public var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Returns age in years
    public var age: Int {
        return Calendar.current.dateComponents([.year], from: self, to: Date()).year ?? 0
    }
    
    /// Returns true if date is today
    public var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Returns true if date is yesterday
    public var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    /// Returns true if date is this week
    public var isThisWeek: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// Returns true if date is this month
    public var isThisMonth: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
}

extension Array {
    /// Safely access array element at index
    public subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    /// Chunks array into smaller arrays
    public func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
    
    /// Removes duplicate elements while preserving order
    public func removingDuplicates<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { element in
            let key = element[keyPath: keyPath]
            if seen.contains(key) {
                return false
            } else {
                seen.insert(key)
                return true
            }
        }
    }
}

extension Dictionary {
    /// Merges another dictionary into this one
    public mutating func merge(_ other: [Key: Value]) {
        for (key, value) in other {
            self[key] = value
        }
    }
    
    /// Returns a new dictionary by merging with another
    public func merging(_ other: [Key: Value]) -> [Key: Value] {
        var result = self
        result.merge(other)
        return result
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Applies corner radius to specific corners
    public func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    /// Adds shadow with custom parameters
    public func customShadow(color: Color = .black, radius: CGFloat = 10, x: CGFloat = 0, y: CGFloat = 0) -> some View {
        shadow(color: color.opacity(0.3), radius: radius, x: x, y: y)
    }
    
    /// Adds haptic feedback on tap
    public func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
    
    /// Conditionally applies a modifier
    public func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            return AnyView(transform(self))
        } else {
            return AnyView(self)
        }
    }
    
    /// Applies a modifier with animation
    public func animatedModifier<T: ViewModifier>(_ modifier: T, animation: Animation = .easeInOut(duration: 0.3)) -> some View {
        modifier(modifier)
            .animation(animation, value: true)
    }
    
    /// Centers the view in its container
    public func centered() -> some View {
        HStack {
            Spacer()
            self
            Spacer()
        }
    }
    
    /// Adds loading state
    public func loading(_ isLoading: Bool, text: String = "Loading...") -> some View {
        ZStack {
            self
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(text)
                        .foregroundColor(.white)
                        .padding(.top)
                }
            }
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Combine Extensions

extension Publisher {
    /// Debounces values with a delay
    public func debounce<S: Scheduler>(for delay: S.SchedulerTimeType.Stride, scheduler: S) -> AnyPublisher<Output, Failure> {
        return self.debounce(for: delay, scheduler: scheduler)
            .eraseToAnyPublisher()
    }
    
    /// Throttles values with a delay
    public func throttle<S: Scheduler>(for delay: S.SchedulerTimeType.Stride, scheduler: S, latest: Bool = true) -> AnyPublisher<Output, Failure> {
        return self.throttle(for: delay, scheduler: scheduler, latest: latest)
            .eraseToAnyPublisher()
    }
    
    /// Retries failed operations
    public func retry(times: Int, delay: TimeInterval = 1.0) -> AnyPublisher<Output, Failure> {
        return self.catch { error -> AnyPublisher<Output, Failure> in
            if times > 0 {
                return Just(())
                    .delay(for: .seconds(delay), scheduler: DispatchQueue.global())
                    .flatMap { _ in
                        self.retry(times: times - 1, delay: delay)
                    }
                    .eraseToAnyPublisher()
            } else {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Handles errors gracefully
    public func handleError(_ handler: @escaping (Failure) -> Void) -> AnyPublisher<Output, Never> {
        return self.catch { error in
            handler(error)
            return Empty()
        }
        .eraseToAnyPublisher()
    }
    
    /// Maps to a default value on error
    public func mapToDefault<T>(_ defaultValue: T) -> AnyPublisher<T, Never> where Output == T {
        return self.catch { _ in
            Just(defaultValue)
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Color Extensions

extension Color {
    /// Creates color from hex string
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Returns hex string representation
    public var hexString: String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
    
    /// Returns a lighter version of the color
    public func lighter(by percentage: CGFloat = 0.2) -> Color {
        return self.adjustBrightness(by: percentage)
    }
    
    /// Returns a darker version of the color
    public func darker(by percentage: CGFloat = 0.2) -> Color {
        return self.adjustBrightness(by: -percentage)
    }
    
    private func adjustBrightness(by percentage: CGFloat) -> Color {
        let uic = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uic.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        brightness = max(0, min(1, brightness + percentage))
        
        return Color(hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness), opacity: Double(alpha))
    }
}

// MARK: - Bundle Extensions

extension Bundle {
    /// Returns app version string
    public var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// Returns build number string
    public var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// Returns full version string
    public var fullVersion: String {
        return "\(appVersion) (\(buildNumber))"
    }
    
    /// Returns app name
    public var appName: String {
        return infoDictionary?["CFBundleName"] as? String ?? "HealthAI 2030"
    }
}

// MARK: - UserDefaults Extensions

extension UserDefaults {
    /// Safely sets a value with error handling
    public func safeSet(_ value: Any?, forKey key: String) {
        do {
            set(value, forKey: key)
            synchronize()
        } catch {
            print("Failed to set UserDefaults value for key: \(key)")
        }
    }
    
    /// Safely gets a value with type casting
    public func safeGet<T>(_ type: T.Type, forKey key: String) -> T? {
        return object(forKey: key) as? T
    }
    
    /// Removes all values for the app
    public func removeAll() {
        if let bundleID = Bundle.main.bundleIdentifier {
            removePersistentDomain(forName: bundleID)
        }
    }
}

// MARK: - NotificationCenter Extensions

extension NotificationCenter {
    /// Posts notification with object and user info
    public func post(name: NSNotification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        post(name: name, object: object, userInfo: userInfo)
    }
    
    /// Adds observer with completion handler
    public func addObserver(forName name: NSNotification.Name?, object obj: Any? = nil, queue: OperationQueue? = nil, using block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        return addObserver(forName: name, object: obj, queue: queue, using: block)
    }
} 