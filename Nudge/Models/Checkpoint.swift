import Foundation

/// A single alarm moment during the prep window
struct Checkpoint: Identifiable, Equatable {
    let id: UUID
    let at: Date
    let index: Int
    let total: Int
    let isLeaveNow: Bool

    var urgencyLevel: NotificationIntensity {
        if isLeaveNow { return .urgent }
        if index >= total - 1 { return .urgent }
        if index >= total - 2 { return .medium }
        return .calm
    }
}
