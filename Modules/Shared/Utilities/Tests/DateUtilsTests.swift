import XCTest
@testable import DateUtils

final class DateUtilsTests: XCTestCase {
    func testDaysBetween() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2025, month: 1, day: 10))!
        XCTAssertEqual(DateUtils.daysBetween(start, and: end), 9)
    }

    func testFormattedDateString() {
        let date = Calendar.current.date(from: DateComponents(year: 2025, month: 7, day: 4))!
        let formatted = DateUtils.formattedDateString(date, style: .long)
        XCTAssertTrue(formatted.contains("2025"))
    }
}
