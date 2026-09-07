import Foundation
import UserNotifications

final class MonthlyReminderService {
    static let shared = MonthlyReminderService()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let reminderIdentifier = "storyfy.monthly.previous-month-reminder"
    private let debugReminderIdentifier = "storyfy.debug.notification-test"

    private init() {}

    func configure() async {
        await clearBadge()
        let settings = await notificationCenter.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = (try? await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            if granted { await scheduleReminders() }
        case .authorized, .provisional, .ephemeral:
            await scheduleReminders()
        case .denied:
            break
        @unknown default:
            break
        }
    }

    func clearBadge() async {
        try? await notificationCenter.setBadgeCount(0)
    }

    private func scheduleMonthlyReminder() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

        var date = DateComponents()
        date.day = 1
        date.hour = 9
        date.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Hora de criar sua história"
        content.body = "Abra o Storyfy para montar a retrospectiva do mês anterior."
        content.sound = .default
        content.badge = 1
        content.userInfo = ["destination": "home", "period": "previous_month"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)
        try? await notificationCenter.add(request)
    }

    private func scheduleReminders() async {
        await scheduleMonthlyReminder()
        #if DEBUG
        await scheduleDebugReminder()
        #else
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [debugReminderIdentifier])
        #endif
    }

    #if DEBUG
    private func scheduleDebugReminder() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [debugReminderIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Teste Storyfy"
        content.body = "Notificação de teste em Debug. O lembrete mensal está configurado."
        content.sound = .default
        content.badge = 1
        content.userInfo = ["destination": "home", "period": "debug_test"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: debugReminderIdentifier, content: content, trigger: trigger)
        try? await notificationCenter.add(request)
    }
    #endif
}
