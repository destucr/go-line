import Foundation

class CurrencyManager {
    static let shared = CurrencyManager()
    
    private var _totalThread: Int = 0
    private let queue = DispatchQueue(label: "CurrencyManager.queue")
    
    var totalThread: Int {
        return queue.sync { _totalThread }
    }
    
    // Callbacks
    var onThreadUpdate: ((Int) -> Void)?
    
    private init() {}
    
    func addThread(_ amount: Int) {
        queue.async {
            self._totalThread += amount
            let newTotal = self._totalThread
            DispatchQueue.main.async {
                self.onThreadUpdate?(newTotal)
            }
        }
    }
    
    func spendThread(_ amount: Int) -> Bool {
        return queue.sync {
            guard _totalThread >= amount else { return false }
            _totalThread -= amount
            let newTotal = _totalThread
            DispatchQueue.main.async {
                self.onThreadUpdate?(newTotal)
            }
            return true
        }
    }
    
    func reset() {
        queue.async {
            self._totalThread = 0
            DispatchQueue.main.async {
                self.onThreadUpdate?(0)
            }
        }
    }
}
