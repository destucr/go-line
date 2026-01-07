import CoreGraphics
import Foundation

enum StationType: Int, CaseIterable {
    case circle
    case triangle
    case square
    case pentagon
    case star
}

struct Passenger: Identifiable, Equatable {
    let id: UUID
    let destinationType: StationType
    let spawnTime: TimeInterval
}

struct Station: Identifiable, Equatable {
    let id: UUID
    var position: CGPoint
    var type: StationType
    var passengers: [Passenger] = []
    var maxCapacity: Int = 6
    var overcrowdTimer: TimeInterval = 0.0
    
    var isOvercrowded: Bool {
        return passengers.count > maxCapacity
    }
    
    static func == (lhs: Station, rhs: Station) -> Bool {
        return lhs.id == rhs.id
    }
}