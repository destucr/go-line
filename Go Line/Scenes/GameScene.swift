internal import SpriteKit
import RxSwift
import RxRelay

class GameScene: SKScene {
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Navigation Relays
    let menuTappedRelay = PublishRelay<Void>()
    let gameOverRelay = PublishRelay<(score: Int, message: String)>()
    let scoreUpdateRelay = BehaviorRelay<Int>(value: 0)
    let levelUpdateRelay = BehaviorRelay<Int>(value: 1)
    let timeUpdateRelay = PublishRelay<(day: String, time: String, progress: Float)>()
    let tensionUpdateRelay = BehaviorRelay<CGFloat>(value: 0.0)
    let dayCompleteRelay = PublishRelay<Int>()
    
    // MARK: - Game State
    var gameStations: [Station] = []
    var metroLines: [UIColor: MetroLine] = [:]
    var trains: [Train] = []
    var isGameOver = false
    var isGamePaused = false
    
    // Core Loop
    var level: Int = 1 {
        didSet {
            levelUpdateRelay.accept(level)
        }
    }
    var trainSpeedMultiplier: CGFloat = 1.0
    
    // Mission Progress
    let levelGoals = [15, 30, 50, 100]
    var progressBarFill: SKShapeNode?
    var missionLabel: SKLabelNode?
    var score: Int = 0 {
        didSet {
            scoreUpdateRelay.accept(score)
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
            tensionUpdateRelay.accept(tension)
        }
    }
    
    let maxTensionRelay = BehaviorRelay<CGFloat>(value: 100.0)
    var maxTension: CGFloat {
        return maxTensionRelay.value
    }
    
    // MARK: - View Cache
    var stationNodes: [UUID: SKShapeNode] = [:]
    var trainNodes: [UUID: SKNode] = [:]
    var lineNodes: [SKNode] = []
    var uiNodes: [String: SKNode] = [:]
    
    // MARK: - Interaction State
    var currentDraftLine: SKShapeNode?
    var startStationID: UUID?
    let currentLineColorRelay = BehaviorRelay<UIColor>(value: .systemRed)
    var currentLineColor: UIColor {
        get { return currentLineColorRelay.value }
        set { currentLineColorRelay.accept(newValue) }
    }
    var isPanning: Bool = false
    var lastTouchPosition: CGPoint = .zero

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
        cameraNode.position = CGPoint(x: worldSize.width / 2, y: worldSize.height / 2)
        
        isUserInteractionEnabled = true
        
        // Listen for Upgrades
        UpgradeManager.shared.upgradePurchased
            .startWith(())
            .subscribe(onNext: { [weak self] in
                self?.updateAllStationsCapacity()
                self?.maxTensionRelay.accept(100.0 + CGFloat(UpgradeManager.shared.maxTensionBonus))
            })
            .disposed(by: disposeBag)
        
        // Setup Day Cycle
        DayCycleManager.shared.timeUpdate
            .subscribe(onNext: { [weak self] timeStr, progress in
                self?.timeUpdateRelay.accept(("Day \(DayCycleManager.shared.currentDayValue)", timeStr, progress))
            })
            .disposed(by: disposeBag)
        
        DayCycleManager.shared.dayEnd
            .subscribe(onNext: { [weak self] day in
                self?.handleDayEnd(day: day)
            })
            .disposed(by: disposeBag)
        
        DayCycleManager.shared.startDay()
        
        if !isCreated {
            spawnCityStations()
            showTutorialHint()
            updateLockedLines()
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
        dayCompleteRelay.accept(day)
    }
    
    func advanceDay() {
        isGamePaused = false
        lastUpdateTime = 0
        tension = max(0, tension - 20)
        DayCycleManager.shared.startDay()
    }
    
    func setCameraZoom(_ scale: CGFloat) {
        let minZoom: CGFloat = 0.3
        let maxZoom: CGFloat = 2.0
        
        let newScale = max(minZoom, min(maxZoom, cameraNode.xScale * scale))
        cameraNode.xScale = newScale
        cameraNode.yScale = newScale
    }
}
