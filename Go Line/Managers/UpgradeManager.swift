import Foundation
import RxSwift
import RxRelay

class UpgradeManager {
    static let shared = UpgradeManager()
    
    // Upgrade Levels
    var carriageCount: Int = 0
    var speedLevel: Int = 0
    var strengthLevel: Int = 0
    
    // Multipliers / Effects
    var speedMultiplier: Double {
        return 1.0 + (Double(speedLevel) * 0.15)
    }
    
    var maxTensionBonus: Double {
        return Double(strengthLevel) * 25.0
    }
    
    // Observables
    private let upgradePurchasedRelay = PublishRelay<Void>()
    var upgradePurchased: Observable<Void> { return upgradePurchasedRelay.asObservable() }
    
    private init() {}
    
    func reset() {
        carriageCount = 0
        speedLevel = 0
        strengthLevel = 0
    }
    
    // Purchase Logic
    func buyCarriage() -> Bool {
        let cost = 100 + (carriageCount * 50)
        if CurrencyManager.shared.spendThread(cost) {
            carriageCount += 1
            upgradePurchasedRelay.accept(())
            return true
        }
        return false
    }
    
    func buySpeed() -> Bool {
        let cost = 150 + (speedLevel * 75)
        if CurrencyManager.shared.spendThread(cost) {
            speedLevel += 1
            upgradePurchasedRelay.accept(())
            return true
        }
        return false
    }
    
    func buyStrength() -> Bool {
        let cost = 200 + (strengthLevel * 100)
        if CurrencyManager.shared.spendThread(cost) {
            strengthLevel += 1
            upgradePurchasedRelay.accept(())
            return true
        }
        return false
    }
    
    func getCarriageCost() -> Int { return 100 + (carriageCount * 50) }
    func getSpeedCost() -> Int { return 150 + (speedLevel * 75) }
    func getStrengthCost() -> Int { return 200 + (strengthLevel * 100) }
}
