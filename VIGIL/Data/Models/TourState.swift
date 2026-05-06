import Foundation
import SwiftData

@Model
final class TourState {
    var id: UUID
    var seenTours: [String]

    init(id: UUID = UUID(), seenTours: [String] = []) {
        self.id = id
        self.seenTours = seenTours
    }

    func hasSeen(_ id: TourID) -> Bool {
        seenTours.contains(id.rawValue)
    }

    func markSeen(_ id: TourID) {
        if !seenTours.contains(id.rawValue) {
            seenTours.append(id.rawValue)
        }
    }
}
