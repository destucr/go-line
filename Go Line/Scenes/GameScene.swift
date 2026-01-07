internal import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Navigation Callback
    var onMenuTapped: (() -> Void)?
    var onGameOver: ((Int, String) -> Void)?
    var onScoreUpdate: ((Int) -> Void)?
    var onLevelUpdate: ((Int) -> Void)?
    var onTimeUpdate: ((String, String, Float) -> Void)? // Day, Time, Progress
    var onTensionUpdate: ((CGFloat) -> Void)?
    var onDayComplete: ((Int) -> Void)?
    
    // MARK: - Game State
    var gameStations: [Station] = []
    var metroLines: [UIColor: MetroLine] = [:]
    var trains: [Train] = []
    var isGameOver = false
    var isGamePaused = false
    
    // Core Loop
    var level: Int = 1
    var trainSpeedMultiplier: CGFloat = 1.0
    
    // Mission Progress
    let levelGoals = [15, 30, 50, 100]
    var progressBarFill: SKShapeNode?
    var missionLabel: SKLabelNode?
    var score: Int = 0 {
        didSet {
            onScoreUpdate?(score)
            // checkLevelUp() // Removed: Old progression
        }
    }
    
    // MARK: - Time & Difficulty
    var lastUpdateTime: TimeInterval = 0
    var passengerSpawnTimer: TimeInterval = 0
    var currentSpawnInterval: TimeInterval = 3.0
    
    var stationSpawnTimer: TimeInterval = 0
    var stationSpawnInterval: TimeInterval = 20.0
    
    // Tension (Health)
    var tension: CGFloat = 0.0 {
        didSet {
            onTensionUpdate?(tension)
        }
    }
    
    var maxTension: CGFloat {
        return 100.0 + CGFloat(UpgradeManager.shared.maxTensionBonus)
    }
    
    // MARK: - View Cache
    var stationNodes: [UUID: SKShapeNode] = [:]
    var trainNodes: [UUID: SKShapeNode] = [:]
    var uiNodes: [String: SKNode] = [:]
    
    // MARK: - Interaction State
    var currentDraftLine: SKShapeNode?
    var startStationID: UUID?
    var currentLineColor: UIColor = .systemRed

    // MARK: - Camera & World
    let cameraNode = SKCameraNode()
    var worldSize: CGSize = .zero

    // MARK: - Config
    var stationRadius: CGFloat = 22.0
    var touchAreaRadius: CGFloat = 45.0
    var lastDominantAxisWasHorizontal: Bool = true
    var isCreated = false
    
    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = UIColor(named: "BackgroundColor") ?? .white
        worldSize = size
        
        // Setup Camera
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width/2, y: size.height/2)
        
        isUserInteractionEnabled = true
        
        // Listen for Upgrades
        UpgradeManager.shared.onUpgradePurchased = { [weak self] in
            DispatchQueue.main.async {
                self?.updateAllStationsCapacity()
            }
        }
        
        // Setup Day Cycle
        DayCycleManager.shared.onTimeUpdate = { [weak self] timeStr, progress in
            self?.onTimeUpdate?("Day \(DayCycleManager.shared.currentDay)", timeStr, progress)
        }
        
        DayCycleManager.shared.onDayEnd = { [weak self] day in
            self?.handleDayEnd(day: day)
        }
        
        DayCycleManager.shared.startDay()
        
        if !isCreated {
            // createCityMap() // Removed for white background
            // createHUD() // Legacy removed
            spawnCityStations()
            showTutorialHint()
            updateLockedLines()
            // createSewingScraps() // Removed for white background
            isCreated = true
        }
        layoutUI()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isGameOver || isGamePaused { return }
        
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        updateGameLogic(dt: dt)
    }
    
    func handleDayEnd(day: Int) {
        isGamePaused = true
        level += 1
        handleLevelUp()
        onDayComplete?(day)
    }
    
    func advanceDay() {
        isGamePaused = false
        // Slower tension recovery overnight
        tension = max(0, tension - 20) 
        DayCycleManager.shared.startDay()
    }
}
