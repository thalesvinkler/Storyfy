import XCTest
@testable import Storyfy

final class MonthIntervalTests: XCTestCase {
    func testPreviousMonthAcrossYearBoundary() throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let interval = MonthInterval.previous(to: date, calendar: calendar)
        XCTAssertEqual(calendar.component(.year, from: interval.start), 2025)
        XCTAssertEqual(calendar.component(.month, from: interval.start), 12)
        XCTAssertEqual(interval.end, calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)))
    }
}
