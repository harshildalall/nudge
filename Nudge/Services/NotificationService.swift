import Foundation
import UserNotifications

final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized: Bool = false

    init() {
        Task { await checkAuthorization() }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run { isAuthorized = granted }
            return granted
        } catch {
            await MainActor.run { isAuthorized = false }
            return false
        }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    func scheduleCheckpoint(_ checkpoint: Checkpoint, eventTitle: String, soundId: String) {
        let content = UNMutableNotificationContent()
        content.title = eventTitle
        content.body = checkpoint.isLeaveNow ? "LEAVE NOW" : "Time to get ready — next checkpoint in a few minutes."
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = "NUDGE_CHECKPOINT"

        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: checkpoint.at), repeats: false)
        let request = UNNotificationRequest(identifier: "nudge-\(checkpoint.id.uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func cancel(forEventId eventId: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.contains("nudge-") }.map(\.identifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func cancelAllForEvent(eventId: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix("nudge-") }.map(\.identifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
