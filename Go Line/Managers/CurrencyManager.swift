import Foundation
import RxSwift
import RxRelay

class CurrencyManager {
    static let shared = CurrencyManager()
    
    private let totalThreadRelay = BehaviorRelay<Int>(value: 0)
    private let queue = DispatchQueue(label: "CurrencyManager.queue")
    
    var totalThread: Observable<Int> {
        return totalThreadRelay.asObservable()
    }
    
    var currentTotalThread: Int {
        return totalThreadRelay.value
    }
    
    private init() {}
    
    func addThread(_ amount: Int) {
        queue.async {
            let newTotal = self.totalThreadRelay.value + amount
            self.totalThreadRelay.accept(newTotal)
        }
    }
    
    func spendThread(_ amount: Int) -> Bool {
        return queue.sync {
            let current = self.totalThreadRelay.value
            guard current >= amount else { return false }
            let newTotal = current - amount
            self.totalThreadRelay.accept(newTotal)
            return true
        }
    }
    
    func reset() {
        totalThreadRelay.accept(0)
    }
}
