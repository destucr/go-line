import Foundation
import RxSwift
import RxRelay

class DayCycleManager {
    static let shared = DayCycleManager()
    
    // Config
    let dayDuration: TimeInterval = 120.0
    let startHour: Int = 6
    let endHour: Int = 22
    
    // State
    private let currentDayRelay = BehaviorRelay<Int>(value: 1)
    var currentTime: TimeInterval = 0.0
    var isDayRunning: Bool = false
    
    // Observables
    private let timeUpdateRelay = PublishRelay<(timeString: String, progress: Float)>()
    private let dayEndRelay = PublishRelay<Int>()
    private let dayStartRelay = PublishRelay<Int>()
    
    var currentDay: Observable<Int> { return currentDayRelay.asObservable() }
    var timeUpdate: Observable<(timeString: String, progress: Float)> { return timeUpdateRelay.asObservable() }
    var dayEnd: Observable<Int> { return dayEndRelay.asObservable() }
    var dayStart: Observable<Int> { return dayStartRelay.asObservable() }
    
    var currentDayValue: Int { return currentDayRelay.value }
    
    private init() {}
    
    func reset() {
        currentDayRelay.accept(1)
        currentTime = 0
        isDayRunning = false
    }
    
    func startDay() {
        currentTime = 0
        isDayRunning = true
        dayStartRelay.accept(currentDayRelay.value)
    }
    
    func update(dt: TimeInterval) {
        guard isDayRunning else { return }
        
        currentTime += dt
        
        let dayProgress = max(0, min(1.0, Float(currentTime / dayDuration)))
        let totalHours = endHour - startHour
        let currentGameHour = Double(startHour) + Double(totalHours) * Double(dayProgress)
        
        let hour = Int(currentGameHour)
        let minute = Int((currentGameHour - Double(hour)) * 60)
        let timeString = String(format: "%02d:%02d", hour, minute)
        
        timeUpdateRelay.accept((timeString, dayProgress))
        
        if currentTime >= dayDuration {
            endDay()
        }
    }
    
    var currentTimeString: String {
        let dayProgress = max(0, min(1.0, Float(currentTime / dayDuration)))
        let totalHours = endHour - startHour
        let currentGameHour = Double(startHour) + Double(totalHours) * Double(dayProgress)
        let hour = Int(currentGameHour)
        let minute = Int((currentGameHour - Double(hour)) * 60)
        return String(format: "%02d:%02d", hour, minute)
    }
    
    private func endDay() {
        isDayRunning = false
        dayEndRelay.accept(currentDayRelay.value)
        currentDayRelay.accept(currentDayRelay.value + 1)
    }
}
