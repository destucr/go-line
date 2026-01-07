import UIKit

struct MetroLine: Identifiable {
    let id: UUID
    var color: UIColor
    var stations: [UUID] // Ordered list of station IDs
    
    // Helper to check if a connection exists between two stations
    func hasConnection(from: UUID, to: UUID) -> Bool {
        guard let fromIndex = stations.firstIndex(of: from),
              let toIndex = stations.firstIndex(of: to) else {
            return false
        }
        // Check adjacency
        return abs(fromIndex - toIndex) == 1
    }
}
