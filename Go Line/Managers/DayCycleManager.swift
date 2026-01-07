import Foundation

class DayCycleManager {
    static let shared = DayCycleManager()
    
    // Config
    let dayDuration: TimeInterval = 120.0 // 2 minutes per day
    // let dayDuration: TimeInterval = 10.0 // DEBUG FASTER
    
    let startHour: Int = 6 // 6:00 AM
    let endHour: Int = 22 // 10:00 PM (16 hours shift)
    
    // State
    var currentDay: Int = 1
    var currentTime: TimeInterval = 0.0 // Elapsed time in current day
    var isDayRunning: Bool = false
    
    // Callbacks
    var onTimeUpdate: ((_ timeString: String, _ progress: Float) -> Void)?
    var onDayEnd: ((_ day: Int) -> Void)?
    var onDayStart: ((_ day: Int) -> Void)?
    
    private init() {}
    
    func reset() {
        currentDay = 1
        currentTime = 0
        isDayRunning = false
    }
    
    func startDay() {
        currentTime = 0
        isDayRunning = true
        onDayStart?(currentDay)
    }
    
    func update(dt: TimeInterval) {
        guard isDayRunning else { return }
        
        currentTime += dt
        
        // Calculate Game Time
        let dayProgress = max(0, min(1.0, Float(currentTime / dayDuration)))
        let totalHours = endHour - startHour
        let currentGameHour = Double(startHour) + Double(totalHours) * Double(dayProgress)
        
        let hour = Int(currentGameHour)
        let minute = Int((currentGameHour - Double(hour)) * 60)
        let timeString = String(format: "%02d:%02d", hour, minute)
        
        onTimeUpdate?(timeString, dayProgress)
        
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
        onDayEnd?(currentDay)
        currentDay += 1 // Advance day
    }
}
