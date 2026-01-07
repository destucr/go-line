import SwiftUI
import Combine

struct HUDState {
    let stitches: Int
    let day: String
    let time: String
    let thread: Int
    let tension: CGFloat
    let maxTension: CGFloat
    let level: Int
    let dayProgress: Float
    let selectedColor: UIColor
}

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
    @Published var selectedColor: UIColor = .systemRed
    
    private init() {}
    
    func update(with state: HUDState) {
        self.stitches = state.stitches
        self.day = state.day
        self.time = state.time
        self.thread = state.thread
        self.tension = state.tension
        self.maxTension = state.maxTension
        self.level = state.level
        self.dayProgress = state.dayProgress
        self.selectedColor = state.selectedColor
    }
    
    func reset() {
        stitches = 0
        day = "Day 1"
        time = "06:00"
        thread = 0
        tension = 0
        maxTension = 100
        level = 1
        dayProgress = 0
        selectedColor = .systemRed
    }
}
