import Foundation

public struct DateUtils {
    /// Calculates the number of days between two dates (whole days).
    public static func daysBetween(_ from: Date, and to: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: from)
        let end = calendar.startOfDay(for: to)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }

    /// Formats a date to a user-friendly string.
    public static func formattedDateString(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}