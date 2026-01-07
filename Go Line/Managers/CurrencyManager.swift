import Foundation

class CurrencyManager {
    static let shared = CurrencyManager()
    
    private(set) var totalThread: Int = 0
    
    // Callbacks
    var onThreadUpdate: ((Int) -> Void)?
    
    private init() {}
    
    func addThread(_ amount: Int) {
        totalThread += amount
        onThreadUpdate?(totalThread)
    }
    
    func spendThread(_ amount: Int) -> Bool {
        guard totalThread >= amount else { return false }
        totalThread -= amount
        onThreadUpdate?(totalThread)
        return true
    }
    
    func reset() {
        totalThread = 0
        onThreadUpdate?(0)
    }
}
