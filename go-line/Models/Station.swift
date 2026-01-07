import CoreGraphics
import Foundation

enum StationType: Int, CaseIterable {
    case circle
    case triangle
    case square
    // Add more types as game progresses
}

struct Station: Identifiable, Equatable {
    let id: UUID
    var position: CGPoint
    var type: StationType
    var passengers: [Passenger] = []
    
    // For Equatable
    static func == (lhs: Station, rhs: Station) -> Bool {
        return lhs.id == rhs.id
    }
}

// Placeholder for Passenger until fully implemented
struct Passenger {
    let id: UUID
    let destinationType: StationType
    // Add spawn time, happiness, etc. later
}
