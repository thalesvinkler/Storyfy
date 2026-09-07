import XCTest
@testable import Storyfy

final class CurationServiceTests: XCTestCase {
    func testKeepsBestPhotoFromShortBurst() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let photos = [
            candidate("low", date: start, score: 0.3),
            candidate("best", date: start.addingTimeInterval(2), score: 0.9),
            candidate("medium", date: start.addingTimeInterval(5), score: 0.6),
            candidate("later", date: start.addingTimeInterval(3600), score: 0.7),
        ]

        let selected = LocalCurationService().select(from: photos, limit: 15)

        XCTAssertEqual(selected.map(\.id), ["best", "later"])
    }

    func testLimitsSameDayToTwoWhenAlternativesExist() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(from: DateComponents(year: 2026, month: 6, day: 2, hour: 10))!
        var photos = (0..<5).map { candidate("day-one-\($0)", date: start.addingTimeInterval(Double($0 * 600)), score: 0.95 - Double($0) * 0.01) }
        photos += (1...4).map { candidate("other-\($0)", date: calendar.date(byAdding: .day, value: $0 * 5, to: start)!, score: 0.7) }

        let selected = LocalCurationService(calendar: calendar).select(from: photos, limit: 5)
        let firstDayCount = selected.filter { calendar.isDate($0.createdAt, inSameDayAs: start) }.count

        XCTAssertLessThanOrEqual(firstDayCount, 2)
    }

    private func candidate(_ id: String, date: Date, score: Double) -> PhotoCandidate {
        PhotoCandidate(id: id, asset: nil, createdAt: date, score: score, event: "Evento", symbol: "photo", colorIndex: 0)
    }
}
