import Foundation
import EventKit

final class CalendarService: ObservableObject {
    static let shared = CalendarService()
    private let store = EKEventStore()

    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var events: [EKEvent] = []

    var isAuthorized: Bool {
        if #available(iOS 17.0, *) {
            return authorizationStatus == .fullAccess
        } else {
            // Pre-iOS 17: use raw value to avoid deprecated .authorized
            return authorizationStatus.rawValue == 3
        }
    }

    init() {
        if #available(iOS 17.0, *) {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        } else {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        }
    }

    func requestAccess() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                let granted = try await store.requestFullAccessToEvents()
                await MainActor.run { authorizationStatus = granted ? .fullAccess : .denied }
                return granted
            } else {
                let granted = try await store.requestAccess(to: .event)
                await MainActor.run { authorizationStatus = granted ? EKAuthorizationStatus(rawValue: 3) ?? .denied : .denied }
                return granted
            }
        } catch {
            await MainActor.run { authorizationStatus = .denied }
            return false
        }
    }

    func fetchUpcomingEvents(withinDays days: Int = 14) {
        let start = Date()
        guard let end = Calendar.current.date(byAdding: .day, value: days, to: start) else { return }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let ekEvents = store.events(matching: predicate)
        DispatchQueue.main.async {
            self.events = ekEvents.sorted { ($0.startDate ?? .distantPast) < ($1.startDate ?? .distantPast) }
        }
    }

    func refresh() {
        if #available(iOS 17.0, *) {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        } else {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        }
        if isAuthorized {
            fetchUpcomingEvents()
        }
    }
}
