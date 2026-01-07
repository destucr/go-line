import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Navigation Callback
    var onMenuTapped: (() -> Void)?
    
    // MARK: - Game State
    private var gameStations: [Station] = []
    private var metroLines: [UIColor: MetroLine] = [:]
    private var trains: [Train] = []
    private var isGameOver = false
    private var isGamePaused = false
    
    private var level: Int = 1
    private var trainSpeedMultiplier: CGFloat = 1.0
    
    private var score: Int = 0 {
        didSet {
            scoreLabel?.text = "\(score)"
            checkLevelUp()
        }
    }
    
    private var pauseOverlay: SKShapeNode?
    
    // MARK: - Leveling System
    private func checkLevelUp() {
        var newLevel = level
        
        if score >= 50 && level < 4 { newLevel = 4 }
        else if score >= 30 && level < 3 { newLevel = 3 }
        else if score >= 15 && level < 2 { newLevel = 2 }
        
        if newLevel > level {
            level = newLevel
            handleLevelUp()
        }
    }
    
    private func handleLevelUp() {
        // Visual Feedback
        showLevelUpPopup()
        
        // Update Game State
        updateLockedLines()
        levelLabel?.text = "Lv \(level)"
        
        run(SKAction.playSoundFileNamed("sfx_levelup.wav", waitForCompletion: false))
        
        // Level 4 Bonus: Speed
        if level >= 4 {
            trainSpeedMultiplier = 1.3
        }
    }    
    // MARK: - Time & Difficulty
    private var totalGameTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var passengerSpawnTimer: TimeInterval = 0
    private var currentSpawnInterval: TimeInterval = 3.0
    private var dayCounter: Int = 1
    
    // MARK: - View Cache
    private var stationNodes: [UUID: SKSpriteNode] = [:]
    private var trainNodes: [UUID: SKNode] = [:]
    private var uiNodes: [String: SKNode] = [:]
    private var scoreLabel: SKLabelNode?
    private var dayLabel: SKLabelNode?
    private var timeLabel: SKLabelNode?
    private var levelLabel: SKLabelNode?
    
    // MARK: - Interaction State
    private var currentDraftLine: SKShapeNode?
    private var startStationID: UUID?
    private var currentLineColor: UIColor = .systemRed
    
    // MARK: - Config
    private let stationRadius: CGFloat = 18.0
    private let touchAreaRadius: CGFloat = 35.0
    private var isCreated = false
    private let maxOvercrowdTime: TimeInterval = 10.0
    
    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        // Linen/Fabric background color
        let bg = GraphicsManager.createBackground(size: size)
        bg.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(bg)
        
        physicsWorld.gravity = .zero
        
        // Preload sounds to fix latency
        let dummy = SKAction.playSoundFileNamed("soft_click.mp3", waitForCompletion: false)
        run(SKAction.group([
            dummy,
            SKAction.playSoundFileNamed("sfx_passenger_spawn.wav", waitForCompletion: false),
            SKAction.playSoundFileNamed("sfx_levelup.wav", waitForCompletion: false),
            SKAction.playSoundFileNamed("sfx_score.wav", waitForCompletion: false)
        ]))
        
        if !isCreated {
            createCityMap()
            createHUD()
            spawnCityStations()
            showTutorialHint()
            updateLockedLines()
            isCreated = true
        }
        layoutUI()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if isCreated {
            layoutUI()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isGameOver || isGamePaused { return }
        
        // Calculate Delta Time
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        updateGameLogic(dt: dt)
    }
    
    // MARK: - Game Loop
    private func updateGameLogic(dt: TimeInterval) {
        totalGameTime += dt
        
        // Dynamic Difficulty: Slower ramp up
        // Level 1: One line, slow spawns (4.0s)
        // Level 2: Two lines, moderate spawns (3.0s)
        // Level 3+: Three lines, fast spawns (2.0s)
        
        var baseInterval: TimeInterval = 4.0
        if level >= 2 { baseInterval = 3.0 }
        if level >= 3 { baseInterval = 2.0 }
        if level >= 4 { baseInterval = 1.5 }
        
        currentSpawnInterval = baseInterval
        
        // Day/Time Display (1 min real time = 1 day logic for flavor)
        let dayProgress = Int(totalGameTime) % 60
        let dayNum = Int(totalGameTime / 60) + 1
        dayLabel?.text = "Day \(dayNum)"
        timeLabel?.text = String(format: "%02d:00", (dayProgress * 24 / 60))
        
        // 1. Spawn Passengers
        passengerSpawnTimer += dt
        if passengerSpawnTimer >= currentSpawnInterval {
            passengerSpawnTimer = 0
            spawnRandomPassenger()
        }
        
        // 2. Move Trains
        moveTrains(dt: dt)
        
        // 3. Check Overcrowding
        checkOvercrowding(dt: dt)
        
        // 4. Update Visuals
        updateTrainVisuals()
        updateStationVisuals()
    }

    // ... (rest of the file until updateLockedLines)

    private func updateLockedLines() {
        // Lock/Unlock logic to make leveling meaningful
        // Red: Always unlocked
        // Blue: Level 2+
        // Green: Level 3+
        
        if let blueBtn = uiNodes["line_blue"] {
            let isUnlocked = level >= 2
            blueBtn.alpha = isUnlocked ? 1.0 : 0.3
            // Visual lock indicator
            if !isUnlocked {
                blueBtn.setScale(0.8)
            } else {
                blueBtn.setScale(1.0)
            }
            
            if !isUnlocked && currentLineColor == .systemBlue {
                currentLineColor = .systemRed // Reset if locked
                updateHUD()
            }
        }
        
        if let greenBtn = uiNodes["line_green"] {
            let isUnlocked = level >= 3
            greenBtn.alpha = isUnlocked ? 1.0 : 0.3
            // Visual lock indicator
            if !isUnlocked {
                greenBtn.setScale(0.8)
            } else {
                greenBtn.setScale(1.0)
            }
            
            if !isUnlocked && currentLineColor == .systemGreen {
                currentLineColor = .systemRed // Reset if locked
                updateHUD()
            }
        }
    }
    
    private func showLevelUpPopup() {
        isGamePaused = true
        
        // Darken background
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = UIColor.black.withAlphaComponent(0.4)
        overlay.strokeColor = .clear
        overlay.zPosition = 199
        overlay.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(overlay)
        
        let container = SKNode()
        container.zPosition = 200
        container.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(container)
        
        // Badge Background
        let badge = GraphicsManager.createTagNode(size: CGSize(width: 300, height: 150))
        container.addChild(badge)
        
        let label = SKLabelNode(text: "LEVEL \(level) REACHED!")
        label.fontName = "ChalkboardSE-Bold"
        label.fontSize = 28
        label.fontColor = .darkGray
        label.position = CGPoint(x: 0, y: 20)
        container.addChild(label)
        
        // Info text
        var infoText = ""
        switch level {
        case 2: infoText = "Unlocked: Blue Thread"
        case 3: infoText = "Unlocked: Green Thread"
        case 4: infoText = "Bonus: Faster Stitching!"
        default: break
        }
        
        if !infoText.isEmpty {
            let subLabel = SKLabelNode(text: infoText)
            subLabel.fontName = "ChalkboardSE-Regular"
            subLabel.fontSize = 22
            subLabel.fontColor = .systemBlue
            subLabel.position = CGPoint(x: 0, y: -20)
            container.addChild(subLabel)
        }
        
        container.setScale(0.0)
        let grow = SKAction.scale(to: 1.1, duration: 0.2)
        let shrink = SKAction.scale(to: 1.0, duration: 0.1)
        let wait = SKAction.wait(forDuration: 2.0)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        
        container.run(SKAction.sequence([grow, shrink, wait, fade, remove])) {
            overlay.removeFromParent()
            self.isGamePaused = false
        }
    }
    
    private func checkOvercrowding(dt: TimeInterval) {
        for i in 0..<gameStations.count {
            var station = gameStations[i]
            
            if station.isOvercrowded {
                station.overcrowdTimer += dt
                if station.overcrowdTimer >= maxOvercrowdTime {
                    triggerGameOver(reason: "Fabric Snapping!\nPattern Failure")
                }
            } else {
                // Recover slowly
                station.overcrowdTimer = max(0, station.overcrowdTimer - dt)
            }
            gameStations[i] = station
        }
    }
    
    private func triggerGameOver(reason: String) {
        isGameOver = true
        
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = UIColor.black.withAlphaComponent(0.7)
        overlay.strokeColor = .clear
        overlay.zPosition = 1000
        overlay.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(overlay)
        
        let label = SKLabelNode(text: "THREAD SNAPPED")
        label.fontName = "ChalkboardSE-Bold"
        label.fontSize = 50
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: 20)
        overlay.addChild(label)
        
        let reasonLabel = SKLabelNode(text: reason)
        reasonLabel.fontName = "ChalkboardSE-Regular"
        reasonLabel.fontSize = 20
        reasonLabel.fontColor = .white
        reasonLabel.numberOfLines = 2
        reasonLabel.position = CGPoint(x: 0, y: -40)
        overlay.addChild(reasonLabel)
        
        let scoreFinal = SKLabelNode(text: "Final Score: \(score)")
        scoreFinal.fontName = "ChalkboardSE-Bold"
        scoreFinal.fontSize = 30
        scoreFinal.fontColor = .yellow
        scoreFinal.position = CGPoint(x: 0, y: -100)
        overlay.addChild(scoreFinal)
    }
    
    private func spawnRandomPassenger() {
        guard !gameStations.isEmpty else { return }
        
        let stationIndex = Int.random(in: 0..<gameStations.count)
        var station = gameStations[stationIndex]
        
        var destType = StationType.allCases.randomElement()!
        let existingTypes = Set(gameStations.map { $0.type })
        
        var attempts = 0
        while (destType == station.type || !existingTypes.contains(destType)) && attempts < 10 {
            destType = StationType.allCases.randomElement()!
            attempts += 1
        }
        
        let passenger = Passenger(id: UUID(), destinationType: destType, spawnTime: lastUpdateTime)
        
        station.passengers.append(passenger)
        gameStations[stationIndex] = station
        
        run(SKAction.playSoundFileNamed("sfx_passenger_spawn.wav", waitForCompletion: false))
    }
    
    private func moveTrains(dt: TimeInterval) {
        let baseSpeed: CGFloat = 100.0
        let speed = baseSpeed * trainSpeedMultiplier
        
        for i in 0..<trains.count {
            var train = trains[i]
            guard let line = metroLines.values.first(where: { $0.id == train.lineID }) else { continue }
            
            let stations = line.stations
            guard stations.count >= 2 else { continue }
            
            let fromIndex = train.currentSegmentIndex
            let toIndex = train.isReversed ? fromIndex - 1 : fromIndex + 1
            
            if toIndex < 0 || toIndex >= stations.count {
                train.isReversed.toggle()
                trains[i] = train
                continue
            }
            
            let fromID = stations[fromIndex]
            let toID = stations[toIndex]
            
            guard let fromPos = getStationPos(id: fromID),
                  let toPos = getStationPos(id: toID) else { continue }
            
            let segmentDist = hypot(toPos.x - fromPos.x, toPos.y - fromPos.y)
            let distanceTravelled = speed * CGFloat(dt)
            let progressDelta = distanceTravelled / segmentDist
            
            train.progress += progressDelta
            
            // Unified Curved Position Calculation
            let controlPoint = getControlPoint(from: fromPos, to: toPos)
            
            // Quadratic Bezier Formula: (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
            let t = train.progress
            let invT = 1.0 - t
            let posX = invT * invT * fromPos.x + 2 * invT * t * controlPoint.x + t * t * toPos.x
            let posY = invT * invT * fromPos.y + 2 * invT * t * controlPoint.y + t * t * toPos.y
            
            train.position = CGPoint(x: posX, y: posY)
            
            if train.progress >= 1.0 {
                train.progress = 0.0
                train.currentSegmentIndex = toIndex
                
                handleStationArrival(trainIndex: i, stationID: toID)
                
                if train.currentSegmentIndex == stations.count - 1 {
                    train.isReversed = true
                } else if train.currentSegmentIndex == 0 {
                    train.isReversed = false
                }
            }
            
            trains[i] = train
        }
    }
    
    private func handleStationArrival(trainIndex: Int, stationID: UUID) {
        var train = trains[trainIndex]
        guard let stationIndex = gameStations.firstIndex(where: { $0.id == stationID }) else { return }
        var station = gameStations[stationIndex]
        
        // 1. Offboard
        let offboardCount = train.offboard(at: station.type)
        if offboardCount > 0 {
            score += offboardCount
            showScorePopup(amount: offboardCount, at: station.position)
            run(SKAction.playSoundFileNamed("sfx_score.wav", waitForCompletion: false))
        }
        
        // 2. Board
        for i in (0..<station.passengers.count).reversed() {
            let p = station.passengers[i]
            if train.board(passenger: p) {
                station.passengers.remove(at: i)
            } else {
                break
            }
        }
        
        trains[trainIndex] = train
        gameStations[stationIndex] = station
    }
    
    private func showScorePopup(amount: Int, at position: CGPoint) {
        let label = SKLabelNode(text: "+\(amount)")
        label.fontName = "ChalkboardSE-Bold"
        label.fontSize = 20
        label.fontColor = .systemOrange
        label.position = CGPoint(x: position.x, y: position.y + 20)
        label.zPosition = 50
        addChild(label)
        
        let move = SKAction.moveBy(x: 0, y: 30, duration: 0.8)
        let fade = SKAction.fadeOut(withDuration: 0.8)
        let group = SKAction.group([move, fade])
        label.run(SKAction.sequence([group, .removeFromParent()]))
    }
    
    // MARK: - Map Generation (Berlin Inspired)
    private func createCityMap() {
        // 1. River Spree (Simplified East-West flow with Museum Island curve)
        let riverPath = CGMutablePath()
        // Start from East (Right)
        riverPath.move(to: CGPoint(x: size.width + 50, y: size.height * 0.55))
        
        // Curve 1: The "East Side Gallery" / Oberbaum bridge area
        riverPath.addCurve(to: CGPoint(x: size.width * 0.7, y: size.height * 0.45),
                           control1: CGPoint(x: size.width * 0.9, y: size.height * 0.55),
                           control2: CGPoint(x: size.width * 0.8, y: size.height * 0.45))
        
        // Curve 2: Around Museum Island (goes up)
        riverPath.addCurve(to: CGPoint(x: size.width * 0.4, y: size.height * 0.6),
                           control1: CGPoint(x: size.width * 0.6, y: size.height * 0.45),
                           control2: CGPoint(x: size.width * 0.5, y: size.height * 0.65))
        
        // Curve 3: Toward Spandau (West)
        riverPath.addCurve(to: CGPoint(x: -50, y: size.height * 0.5),
                           control1: CGPoint(x: size.width * 0.2, y: size.height * 0.55),
                           control2: CGPoint(x: size.width * 0.1, y: size.height * 0.5))
        
        let riverShape = SKShapeNode(path: riverPath)
        riverShape.strokeColor = UIColor(red: 0.6, green: 0.8, blue: 0.9, alpha: 0.5)
        riverShape.lineWidth = 50
        riverShape.zPosition = -10
        riverShape.lineCap = .round
        
        // Stitch Border for River
        let dashedRiverPath = riverPath.copy(
            dashingWithPhase: 0,
            lengths: [5, 5]
        )
        let border = SKShapeNode(path: dashedRiverPath)
        border.strokeColor = .white
        border.lineWidth = 2
        riverShape.addChild(border)
        
        addChild(riverShape)
        
        // 2. Landmark: Fernsehturm (TV Tower) - Stylized Stitch
        let towerNode = SKNode()
        towerNode.position = CGPoint(x: size.width * 0.55, y: size.height * 0.65)
        towerNode.zPosition = -5
        towerNode.alpha = 0.6
        
        // Sphere
        let sphere = SKShapeNode(circleOfRadius: 12)
        sphere.strokeColor = .lightGray
        sphere.lineWidth = 2
        sphere.fillColor = .clear
        
        // Needle
        let needlePath = CGMutablePath()
        needlePath.move(to: CGPoint(x: 0, y: 12))
        needlePath.addLine(to: CGPoint(x: 0, y: 40)) // Top antenna
        needlePath.move(to: CGPoint(x: 0, y: -12))
        needlePath.addLine(to: CGPoint(x: -10, y: -60)) // Legs
        needlePath.move(to: CGPoint(x: 0, y: -12))
        needlePath.addLine(to: CGPoint(x: 10, y: -60))
        
        let needle = SKShapeNode(path: needlePath)
        needle.strokeColor = .lightGray
        needle.lineWidth = 2
        
        towerNode.addChild(sphere)
        towerNode.addChild(needle)
        addChild(towerNode)
    }
    
    private func spawnCityStations() {
        gameStations.removeAll()
        stationNodes.removeAll()
        children.forEach { if $0.name?.starts(with: "station") == true { $0.removeFromParent() } }
        
        let w = size.width
        let h = size.height
        
        // Defined Positions mimicking Berlin Districts roughly
        // Mitte (Center)
        let mittePos = CGPoint(x: w * 0.5, y: h * 0.55)
        let alexPos = CGPoint(x: w * 0.6, y: h * 0.65) // Near TV Tower
        
        // Charlottenburg (West)
        let westPos = CGPoint(x: w * 0.2, y: h * 0.5)
        
        // Kreuzberg (South East)
        let xbergPos = CGPoint(x: w * 0.7, y: h * 0.3)
        
        // Prenzlauer Berg (North East)
        let pbergPos = CGPoint(x: w * 0.65, y: h * 0.8)
        
        // Tiergarten/South (South West)
        let southPos = CGPoint(x: w * 0.35, y: h * 0.35)
        
        let definitions: [(CGPoint, StationType)] = [
            (mittePos, .square),
            (alexPos, .circle),
            (westPos, .triangle),
            (xbergPos, .square),
            (pbergPos, .triangle),
            (southPos, .circle)
        ]
        
        for (pos, type) in definitions {
            let s = Station(id: UUID(), position: pos, type: type)
            gameStations.append(s)
            renderStation(s)
        }
    }
    
    // MARK: - UI & HUD
    private func createHUD() {
        // Font override
        let fontName = "ChalkboardSE-Bold"
        
        // Menu Button (Fabric Tag Style)
        let menuBtnContainer = SKNode()
        menuBtnContainer.name = "menu_btn"
        
        // Use GraphicsManager for consistent tag style
        let menuBg = GraphicsManager.createTagNode(size: CGSize(width: 80, height: 40))
        menuBg.name = "menu_btn"
        menuBtnContainer.addChild(menuBg)
        
        let menuLabel = SKLabelNode(text: "Menu")
        menuLabel.fontName = fontName
        menuLabel.fontSize = 16
        menuLabel.fontColor = .darkGray
        menuLabel.verticalAlignmentMode = .center
        menuLabel.name = "menu_btn"
        menuBtnContainer.addChild(menuLabel)
        
        addChild(menuBtnContainer)
        uiNodes["menu_btn"] = menuBtnContainer
        
        // Line Selectors (Spools of Thread)
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen]
        let names = ["line_red", "line_blue", "line_green"]
        
        for (i, color) in colors.enumerated() {
            let container = SKNode() // Container for button + shadow
            container.name = names[i]
            
            // Shadow
            let btnShadow = SKShapeNode(circleOfRadius: 20)
            btnShadow.fillColor = UIColor.black.withAlphaComponent(0.3)
            btnShadow.strokeColor = .clear
            btnShadow.position = CGPoint(x: 2, y: -2)
            container.addChild(btnShadow)
            
            // Main Button
            let btn = SKShapeNode(circleOfRadius: 20)
            btn.fillColor = color
            btn.strokeColor = (color == currentLineColor) ? .black : .clear
            btn.lineWidth = 2
            
            // "Thread" texture look (simple rings)
            let ring = SKShapeNode(circleOfRadius: 15)
            ring.strokeColor = UIColor(white: 1.0, alpha: 0.3)
            ring.lineWidth = 2
            btn.addChild(ring)
            
            btn.name = names[i] // Important for hit test
            container.addChild(btn)
            
            container.zPosition = 100
            addChild(container)
            uiNodes[names[i]] = container
        }
        
        // Score Panel
        let scoreNode = SKLabelNode(text: "0")
        scoreNode.fontName = fontName
        scoreNode.fontSize = 40
        scoreNode.fontColor = .darkGray
        scoreNode.horizontalAlignmentMode = .right
        addChild(scoreNode)
        scoreLabel = scoreNode
        
        let scoreTitle = SKLabelNode(text: "STITCHES")
        scoreTitle.fontName = fontName
        scoreTitle.fontSize = 12
        scoreTitle.fontColor = .gray
        scoreTitle.horizontalAlignmentMode = .right
        scoreTitle.position = CGPoint(x: 0, y: 25)
        scoreNode.addChild(scoreTitle)
        
        let levelNode = SKLabelNode(text: "PATTERN 1")
        levelNode.fontName = fontName
        levelNode.fontSize = 24
        levelNode.fontColor = .systemBlue
        levelNode.horizontalAlignmentMode = .right
        addChild(levelNode)
        levelLabel = levelNode
        
        let dayNode = SKLabelNode(text: "Day 1")
        dayNode.fontName = "ChalkboardSE-Regular"
        dayNode.fontSize = 18
        dayNode.fontColor = .gray
        dayNode.horizontalAlignmentMode = .right
        addChild(dayNode)
        dayLabel = dayNode
        
        let timeNode = SKLabelNode(text: "12:00")
        timeNode.fontName = "ChalkboardSE-Regular"
        timeNode.fontSize = 14
        timeNode.fontColor = .lightGray
        timeNode.horizontalAlignmentMode = .right
        addChild(timeNode)
        timeLabel = timeNode
    }
    
    private func layoutUI() {
        if let menuBtn = uiNodes["menu_btn"] {
            menuBtn.position = CGPoint(x: 60, y: size.height - 40)
        }
        
        let names = ["line_red", "line_blue", "line_green"]
        let startX = size.width / 2 - 60
        for (i, name) in names.enumerated() {
            if let btn = uiNodes[name] {
                btn.position = CGPoint(x: startX + CGFloat(i * 60), y: 50)
            }
        }
        
        scoreLabel?.position = CGPoint(x: size.width - 40, y: size.height - 60)
        levelLabel?.position = CGPoint(x: size.width - 40, y: size.height - 90)
        dayLabel?.position = CGPoint(x: size.width - 40, y: size.height - 115)
        timeLabel?.position = CGPoint(x: size.width - 40, y: size.height - 135)
        
        if let label = childNode(withName: "tutorial_hint") {
            label.position = CGPoint(x: size.width / 2, y: size.height / 2 + 120)
        }
    }
    
    private func updateHUD() {
        let names = ["line_red", "line_blue", "line_green"]
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen]
        
        for (i, name) in names.enumerated() {
            guard let container = uiNodes[name] else { continue }
            
            // Try to find the button node (could be SKShapeNode or SKSpriteNode)
            let btn = container.childNode(withName: name)
            
            // Visual selection state
            if colors[i] == currentLineColor {
                if btn?.xScale == 1.0 {
                    let pop = SKAction.sequence([
                        SKAction.scale(to: 1.3, duration: 0.1),
                        SKAction.scale(to: 1.2, duration: 0.1)
                    ])
                    btn?.run(pop)
                    if let shape = btn as? SKShapeNode {
                        shape.strokeColor = .black
                    }
                }
            } else {
                if btn?.xScale != 1.0 {
                    let shrink = SKAction.scale(to: 1.0, duration: 0.15)
                    btn?.run(shrink)
                    if let shape = btn as? SKShapeNode {
                        shape.strokeColor = .clear
                    }
                }
            }
        }
    }
    
    private func animateButtonPress(node: SKNode, completion: (() -> Void)? = nil) {
        // Find the main visual part (the button shape) if it's a container
        let target: SKNode
        if let shape = node.childNode(withName: node.name ?? "") {
            target = shape
        } else {
            target = node
        }
        
        let originalScale = target.xScale
        let press = SKAction.sequence([
            SKAction.scale(to: originalScale * 0.9, duration: 0.05),
            SKAction.moveBy(x: 1, y: -1, duration: 0.05),
            SKAction.wait(forDuration: 0.05),
            SKAction.moveBy(x: -1, y: 1, duration: 0.05),
            SKAction.scale(to: originalScale, duration: 0.1)
        ])
        
        target.run(press) {
            completion?()
        }
        
        run(SKAction.playSoundFileNamed("soft_click.mp3", waitForCompletion: false))
    }
    
    private func showTutorialHint() {
        let label = SKLabelNode(text: "Stitch the pattern together!")
        label.fontName = "ChalkboardSE-Bold"
        label.fontSize = 24
        label.fontColor = .darkGray
        label.alpha = 0
        label.name = "tutorial_hint"
        label.position = CGPoint(x: frame.midX, y: frame.midY + 120)
        addChild(label)
        
        let fadeIn = SKAction.fadeIn(withDuration: 1.0)
        let wait = SKAction.wait(forDuration: 4.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()
        
        label.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
    }
    
    // MARK: - Visual Rendering (Embroidery Style)
    private func renderStation(_ station: Station) {
        let stationNode = SKSpriteNode(color: .clear, size: CGSize(width: touchAreaRadius*2, height: touchAreaRadius*2))
        stationNode.position = station.position
        stationNode.name = "station_\(station.id.uuidString)"
        stationNode.zPosition = 10
        
        // Base Patch (Code Generated)
        let shape = GraphicsManager.createStationShape(type: station.type, radius: stationRadius)
        shape.name = "shape"
        stationNode.addChild(shape)
        
        // Passengers Container
        let passengersNode = SKNode()
        passengersNode.name = "passengers"
        passengersNode.position = CGPoint(x: stationRadius + 10, y: 0)
        stationNode.addChild(passengersNode)
        
        // Overcrowd Timer Indicator
        let timerArc = SKShapeNode(circleOfRadius: stationRadius + 8)
        if let path = timerArc.path {
            timerArc.path = path.copy(dashingWithPhase: 0, lengths: [2, 4])
        }
        timerArc.strokeColor = .red
        timerArc.lineWidth = 3
        timerArc.alpha = 0
        timerArc.name = "timer_arc"
        stationNode.addChild(timerArc)
        
        addChild(stationNode)
        stationNodes[station.id] = stationNode
    }
    
    private func animateButtonPress(_ node: SKNode, completion: @escaping () -> Void) {
        run(SKAction.playSoundFileNamed("soft_click.mp3", waitForCompletion: false))
        
        let shrink = SKAction.scale(to: 0.9, duration: 0.1)
        let grow = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([shrink, grow])
        
        node.run(sequence) {
            completion()
        }
    }
    
    private func updateTrainVisuals() {
        for train in trains {
            if let node = trainNodes[train.id] {
                node.position = train.position
                // Rotation logic to face direction
                if let line = metroLines.values.first(where: { $0.id == train.lineID }),
                   let currentStationPos = getStationPos(id: line.stations[train.currentSegmentIndex]),
                   let nextStationID = (train.isReversed ? line.stations.indices.contains(train.currentSegmentIndex - 1) : line.stations.indices.contains(train.currentSegmentIndex + 1)) ? line.stations[train.isReversed ? train.currentSegmentIndex - 1 : train.currentSegmentIndex + 1] : nil,
                   let nextPos = getStationPos(id: nextStationID) {
                    
                    let dx = nextPos.x - currentStationPos.x
                    let dy = nextPos.y - currentStationPos.y
                    let angle = atan2(dy, dx)
                    node.zRotation = angle
                }
            } else {
                // Shape Node
                var color: UIColor = .systemBlue
                if let line = metroLines.values.first(where: { $0.id == train.lineID }) {
                    color = line.color
                }
                
                let node = GraphicsManager.createTrainShape(color: color)
                node.zPosition = 20
                node.position = train.position
                addChild(node)
                trainNodes[train.id] = node
            }
        }
    }
    
    private func updateStationVisuals() {
        for station in gameStations {
            guard let stationNode = stationNodes[station.id],
                  let passengersNode = stationNode.childNode(withName: "passengers"),
                  let timerArc = stationNode.childNode(withName: "timer_arc") as? SKShapeNode else { continue }
            
            // 1. Update Timer Visual
            if station.overcrowdTimer > 0 {
                timerArc.alpha = 1.0
                let progress = CGFloat(station.overcrowdTimer / maxOvercrowdTime)
                timerArc.alpha = 0.5 + (progress * 0.5)
                
                if progress > 0.7 && !timerArc.hasActions() {
                    let pulse = SKAction.sequence([
                        SKAction.scale(to: 1.1, duration: 0.2),
                        SKAction.scale(to: 1.0, duration: 0.2)
                    ])
                    timerArc.run(SKAction.repeatForever(pulse))
                }
            } else {
                timerArc.alpha = 0
                timerArc.removeAllActions()
                timerArc.setScale(1.0)
            }
            
            // 2. Update Passengers (Buttons)
            passengersNode.removeAllChildren()
            
            for (i, passenger) in station.passengers.prefix(6).enumerated() {
                // Button Shape
                let pNode: SKShapeNode
                switch passenger.destinationType {
                case .circle:
                    pNode = SKShapeNode(circleOfRadius: 5)
                    pNode.fillColor = .systemYellow
                case .triangle:
                    // Approx triangle button
                    pNode = SKShapeNode(circleOfRadius: 5) // Simplify to circle-ish button for now
                    pNode.fillColor = .systemPurple
                case .square:
                    pNode = SKShapeNode(rectOf: CGSize(width: 9, height: 9), cornerRadius: 2)
                    pNode.fillColor = .systemTeal
                default:
                    pNode = SKShapeNode(circleOfRadius: 5)
                    pNode.fillColor = .black
                }
                pNode.strokeColor = .white // Button edge
                pNode.lineWidth = 1
                
                // Button holes
                let hole1 = SKShapeNode(circleOfRadius: 0.5)
                hole1.fillColor = .black
                hole1.position = CGPoint(x: -1.5, y: 0)
                pNode.addChild(hole1)
                
                let hole2 = SKShapeNode(circleOfRadius: 0.5)
                hole2.fillColor = .black
                hole2.position = CGPoint(x: 1.5, y: 0)
                pNode.addChild(hole2)
                
                let col = i % 2
                let row = i / 2
                pNode.position = CGPoint(x: CGFloat(col) * 12, y: CGFloat(row) * 12)
                passengersNode.addChild(pNode)
            }
            
            if station.passengers.count > 6 {
                let plus = SKLabelNode(text: "!")
                plus.fontSize = 16
                plus.fontName = "ChalkboardSE-Bold"
                plus.fontColor = .red
                plus.position = CGPoint(x: 10, y: 40)
                passengersNode.addChild(plus)
            }
        }
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver, let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let nodesAtPoint = nodes(at: location)
        for node in nodesAtPoint {
            let name = node.name ?? node.parent?.name
            if name == "menu_btn" {
                let buttonNode = (node.name == "menu_btn") ? node : node.parent!
                animateButtonPress(node: buttonNode) { [weak self] in
                    self?.onMenuTapped?()
                }
                return
            }
            if let n = name, n.starts(with: "line_") {
                // Check locks
                if n == "line_blue" && level < 2 {
                    return
                }
                if n == "line_green" && level < 3 {
                    return
                }
                
                let buttonNode = (node.name == n) ? node : node.parent!
                animateButtonPress(node: buttonNode) { [weak self] in
                    if n == "line_red" { self?.currentLineColor = .systemRed }
                    if n == "line_blue" { self?.currentLineColor = .systemBlue }
                    if n == "line_green" { self?.currentLineColor = .systemGreen }
                    self?.updateHUD()
                }
                return
            }
        }
        
        if let (stationID, stationPos) = getStationAt(location) {
            startDrawingLine(from: stationID, at: stationPos)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver, let touch = touches.first,
              let startID = startStationID,
              let startNode = stationNodes[startID] else { return }
        
        let location = touch.location(in: self)
        updateDraftLine(from: startNode.position, to: location)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        guard let touch = touches.first,
              let startID = startStationID else {
            resetDraft()
            return
        }
        
        let location = touch.location(in: self)
        if let (endID, _) = getStationAt(location), endID != startID {
            completeConnection(from: startID, to: endID)
        }
        
        resetDraft()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetDraft()
    }
    
    // MARK: - Logic Helpers
    private func getStationAt(_ location: CGPoint) -> (UUID, CGPoint)? {
        for station in gameStations {
            if hypot(station.position.x - location.x, station.position.y - location.y) < touchAreaRadius {
                return (station.id, station.position)
            }
        }
        return nil
    }
    
    private func getStationPos(id: UUID) -> CGPoint? {
        return gameStations.first(where: { $0.id == id })?.position
    }
    
    private func startDrawingLine(from stationID: UUID, at position: CGPoint) {
        startStationID = stationID
        let draft = SKShapeNode()
        draft.strokeColor = currentLineColor.withAlphaComponent(0.5)
        draft.lineWidth = 4
        draft.lineCap = .round
        draft.zPosition = 5
        addChild(draft)
        currentDraftLine = draft
    }
    
    private func updateDraftLine(from startPos: CGPoint, to currentPos: CGPoint) {
        guard let draft = currentDraftLine else { return }
        
        let controlPoint = getControlPoint(from: startPos, to: currentPos)
        
        let path = CGMutablePath()
        path.move(to: startPos)
        path.addQuadCurve(to: currentPos, control: controlPoint)
        draft.path = path.copy(dashingWithPhase: 0, lengths: [6, 4])
    }
    
    private func resetDraft() {
        currentDraftLine?.removeFromParent()
        currentDraftLine = nil
        startStationID = nil
    }
    
    private func completeConnection(from start: UUID, to end: UUID) {
        // Logic to update metroLines
        var line = metroLines[currentLineColor]
        
        // Haptic Feedback for connection
        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        
        if line == nil {
            // New Line
            line = MetroLine(id: UUID(), color: currentLineColor, stations: [start, end])
            metroLines[currentLineColor] = line
            spawnTrain(for: line!)
            createVisualLineSegment(from: start, to: end, color: currentLineColor)
        } else {
            // Extend Line
            var newLine = line!
            
            if newLine.stations.last == start {
                if !newLine.stations.contains(end) {
                    newLine.stations.append(end)
                    metroLines[currentLineColor] = newLine
                    createVisualLineSegment(from: start, to: end, color: currentLineColor)
                }
            } else if newLine.stations.first == start {
                if !newLine.stations.contains(end) {
                    newLine.stations.insert(end, at: 0)
                    metroLines[currentLineColor] = newLine
                    createVisualLineSegment(from: start, to: end, color: currentLineColor)
                }
            } else if newLine.stations.last == end {
                 if !newLine.stations.contains(start) {
                     newLine.stations.append(start)
                     metroLines[currentLineColor] = newLine
                     createVisualLineSegment(from: end, to: start, color: currentLineColor)
                 }
             } else if newLine.stations.first == end {
                 if !newLine.stations.contains(start) {
                     newLine.stations.insert(start, at: 0)
                     metroLines[currentLineColor] = newLine
                     createVisualLineSegment(from: end, to: start, color: currentLineColor)
                 }
             }
        }
    }
    
    private func spawnTrain(for line: MetroLine) {
        let train = Train(id: UUID(), lineID: line.id)
        trains.append(train)
    }
    
    private func createVisualLineSegment(from startID: UUID, to endID: UUID, color: UIColor) {
        guard let startNode = stationNodes[startID],
              let endNode = stationNodes[endID] else { return }
        
        let startPos = startNode.position
        let endPos = endNode.position
        
        let controlPoint = getControlPoint(from: startPos, to: endPos)
        
        let path = CGMutablePath()
        path.move(to: startPos)
        path.addQuadCurve(to: endPos, control: controlPoint)
        
        // Base thick thread
        let lineSeg = SKShapeNode(path: path)
        lineSeg.strokeColor = color
        lineSeg.lineWidth = 5
        lineSeg.lineCap = .round
        
        // Stitch texture (dashed lighter line on top)
        let stitch = SKShapeNode(
            path: path.copy(dashingWithPhase: 0, lengths: [6, 4])
        )
        stitch.strokeColor = color.withAlphaComponent(0.5) // Slightly lighter/diff
        stitch.lineWidth = 2
        lineSeg.addChild(stitch)
        
        lineSeg.zPosition = 1
        
        // Connection Animation
        lineSeg.alpha = 0
        lineSeg.run(SKAction.fadeIn(withDuration: 0.3))
        
        // Station Pulse
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        startNode.run(pulse)
        endNode.run(pulse)
        
        addChild(lineSeg)
    }
    
    // MARK: - Standardized Curve Logic
    private func getControlPoint(from: CGPoint, to: CGPoint) -> CGPoint {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let dist = hypot(dx, dy)
        
        // Normalize mid-point
        let midX = (from.x + to.x) / 2
        let midY = (from.y + to.y) / 2
        
        // To make it look like a metro map, we want more structured bends.
        // Instead of a random perpendicular offset, let's bias it based on the primary axis.
        // This creates a more 'Transit-like' purposeful curve.
        
        let curveScale: CGFloat = min(dist * 0.2, 50.0) // Scale curve with distance but cap it
        
        // Perpendicular vector
        let normalX = -dy / dist
        let normalY = dx / dist
        
        return CGPoint(x: midX + normalX * curveScale, y: midY + normalY * curveScale)
    }
}
