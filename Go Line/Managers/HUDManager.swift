import SwiftUI
import Combine

class HUDManager: ObservableObject {
    static let shared = HUDManager()
    
    @Published var stitches: Int = 0
    @Published var day: String = "Day 1"
    @Published var time: String = "06:00"
    @Published var thread: Int = 0
    @Published var tension: CGFloat = 0.0
    @Published var maxTension: CGFloat = 100.0
    @Published var level: Int = 1
    @Published var dayProgress: Float = 0.0
    
    private init() {}
    
    func update(stitches: Int, day: String, time: String, thread: Int, tension: CGFloat, maxTension: CGFloat, level: Int, dayProgress: Float) {
        self.stitches = stitches
        self.day = day
        self.time = time
        self.thread = thread
        self.tension = tension
        self.maxTension = maxTension
        self.level = level
        self.dayProgress = dayProgress
    }
}
