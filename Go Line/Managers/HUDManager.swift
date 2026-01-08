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
    let carriageLevel: Int
    let speedLevel: Int
    let strengthLevel: Int
}

class HUDManager: ObservableObject {
    static let shared = HUDManager()
    
    @Published var stitches: Int = 0
    @Published var day: String = "1"
    @Published var time: String = "06:00"
    @Published var thread: Int = 0
    @Published var tension: CGFloat = 0.0
    @Published var maxTension: CGFloat = 100.0
    @Published var level: Int = 1
    @Published var dayProgress: Float = 0.0
    @Published var selectedColor: UIColor = .systemRed
    @Published var carriageLevel: Int = 0
    @Published var speedLevel: Int = 0
    @Published var strengthLevel: Int = 0
    
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
        self.carriageLevel = state.carriageLevel
        self.speedLevel = state.speedLevel
        self.strengthLevel = state.strengthLevel
    }
    
    func reset() {
        stitches = 0
        day = "1"
        time = "06:00"
        thread = 0
        tension = 0
        maxTension = 100
        level = 1
        dayProgress = 0
        selectedColor = .systemRed
        carriageLevel = 0
        speedLevel = 0
        strengthLevel = 0
    }
}
