import EventKit
import Foundation

struct CalendarMoment: Sendable {
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool

    func matches(_ date: Date, calendar: Calendar = .current) -> Bool {
        if isAllDay { return calendar.isDate(date, inSameDayAs: start) }
        return date >= start.addingTimeInterval(-3600) && date <= end.addingTimeInterval(3600)
    }
}

protocol CalendarServing {
    var hasFullAccess: Bool { get }
    func requestAccess() async -> Bool
    func moments(in interval: MonthInterval) async -> [CalendarMoment]
}

final class CalendarService: CalendarServing {
    private let store = EKEventStore()

    var hasFullAccess: Bool { EKEventStore.authorizationStatus(for: .event) == .fullAccess }

    func requestAccess() async -> Bool {
        do { return try await store.requestFullAccessToEvents() }
        catch { return false }
    }

    func moments(in interval: MonthInterval) async -> [CalendarMoment] {
        await Task.detached(priority: .utility) {
            guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return [] }
            let store = EKEventStore()
            let predicate = store.predicateForEvents(withStart: interval.start, end: interval.end, calendars: nil)
            return store.events(matching: predicate)
                .filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .map { CalendarMoment(title: $0.title, start: $0.startDate, end: $0.endDate, isAllDay: $0.isAllDay) }
        }.value
    }
}
