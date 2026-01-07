import Foundation
import CoreGraphics

struct Train: Identifiable {
    let id: UUID
    var lineID: UUID
    var passengers: [Passenger] = []
    
    // Upgrades
    var carriages: Int = 0
    
    var capacity: Int {
        return 6 + (carriages * 6)
    }
    
    // Movement State
    var currentSegmentIndex: Int = 0 // Index of the station in the line's station list the train is departing FROM
    var progress: CGFloat = 0.0 // 0.0 to 1.0 along the current segment
    var isReversed: Bool = false // True if moving from end to start
    
    var position: CGPoint = .zero // Calculated for rendering
    var rotation: CGFloat = 0.0 // Rotation angle in radians
    
    // Waiting State
    var isWaiting: Bool = false
    var waitTimer: TimeInterval = 0.0
    
    mutating func board(passenger: Passenger) -> Bool {
        if passengers.count < capacity {
            passengers.append(passenger)
            return true
        }
        return false
    }
    
    mutating func offboard(at type: StationType) -> Int {
        let countBefore = passengers.count
        passengers.removeAll { $0.destinationType == type }
        return countBefore - passengers.count
    }
}
