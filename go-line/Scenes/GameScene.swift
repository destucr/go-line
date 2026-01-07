import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Navigation Callback
    var onMenuTapped: (() -> Void)?
    
    // MARK: - Game State
    private var gameStations: [Station] = []
    
    // MARK: - View Cache
    private var stationNodes: [UUID: SKSpriteNode] = [:]
    private var uiNodes: [String: SKNode] = [:]
    
    // MARK: - Interaction State
    private var currentDraftLine: SKShapeNode?
    private var startStationID: UUID?
    private var currentLineColor: UIColor = .systemRed
    
    // MARK: - Config
    private let stationRadius: CGFloat = 15.0
    private let touchAreaRadius: CGFloat = 30.0
    private var isCreated = false
    
    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .white
        physicsWorld.gravity = .zero
        
        if !isCreated {
            createHUD()
            spawnTestStations()
            showTutorialHint()
            isCreated = true
        }
        layoutUI()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if isCreated {
            layoutUI()
        }
        // If we wanted to re-position stations based on new size, we would do it here.
        // For now, we keep stations absolute but move HUD.
    }
    
    // MARK: - UI & HUD
    private func createHUD() {
        // Menu Button
        let menuBtnContainer = SKNode()
        menuBtnContainer.name = "menu_btn"
        
        let menuBg = SKShapeNode(rectOf: CGSize(width: 80, height: 40), cornerRadius: 8)
        menuBg.fillColor = .lightGray
        menuBg.strokeColor = .clear
        menuBg.name = "menu_btn"
        menuBtnContainer.addChild(menuBg)
        
        let menuLabel = SKLabelNode(text: "Menu")
        menuLabel.fontName = "AvenirNext-Bold"
        menuLabel.fontSize = 16
        menuLabel.fontColor = .white
        menuLabel.verticalAlignmentMode = .center
        menuLabel.name = "menu_btn"
        menuBtnContainer.addChild(menuLabel)
        
        addChild(menuBtnContainer)
        uiNodes["menu_btn"] = menuBtnContainer
        
        // Line Selectors
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen]
        let names = ["line_red", "line_blue", "line_green"]
        
        for (i, color) in colors.enumerated() {
            let btn = SKShapeNode(circleOfRadius: 20)
            btn.fillColor = color
            btn.strokeColor = (color == currentLineColor) ? .black : .clear
            btn.lineWidth = 3
            btn.name = names[i]
            btn.zPosition = 100
            addChild(btn)
            uiNodes[names[i]] = btn
        }
    }
    
    private func layoutUI() {
        // Menu top left
        if let menuBtn = uiNodes["menu_btn"] {
            menuBtn.position = CGPoint(x: 60, y: size.height - 40)
        }
        
        // Line selectors bottom center
        let names = ["line_red", "line_blue", "line_green"]
        let startX = size.width / 2 - 60
        
        for (i, name) in names.enumerated() {
            if let btn = uiNodes[name] {
                btn.position = CGPoint(x: startX + CGFloat(i * 60), y: 50)
            }
        }
        
        // Center tutorial label if it exists
        if let label = childNode(withName: "tutorial_hint") {
            label.position = CGPoint(x: size.width / 2, y: size.height / 2 + 100)
        }
    }
    
    private func updateHUD() {
        let names = ["line_red", "line_blue", "line_green"]
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen]
        
        for (i, name) in names.enumerated() {
            if let btn = uiNodes[name] as? SKShapeNode {
                if colors[i] == currentLineColor {
                    btn.strokeColor = .black
                    btn.setScale(1.2)
                } else {
                    btn.strokeColor = .clear
                    btn.setScale(1.0)
                }
            }
        }
    }
    
    private func showTutorialHint() {
        let label = SKLabelNode(text: "Drag from one station to another to build a line!")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 24
        label.fontColor = .black
        label.alpha = 0
        label.name = "tutorial_hint"
        label.position = CGPoint(x: frame.midX, y: frame.midY + 100)
        addChild(label)
        
        let fadeIn = SKAction.fadeIn(withDuration: 1.0)
        let wait = SKAction.wait(forDuration: 3.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()
        
        label.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
    }
    
    // MARK: - Setup & Spawning
    private func spawnTestStations() {
        // Clear existing
        children.forEach { if $0.name?.starts(with: "station") == true { $0.removeFromParent() } }
        gameStations.removeAll()
        stationNodes.removeAll()
        
        // Use normalized coordinates (0.0 to 1.0) then scale to view size in a real game
        // For now, we use a safe area in the center relative to an assumed safe canvas
        let cx = size.width / 2
        let cy = size.height / 2
        
        // If size is 0 (first load), default to standard iPhone landscape
        let safeCX = cx == 0 ? 400 : cx
        let safeCY = cy == 0 ? 200 : cy
        
        let positions = [
            CGPoint(x: safeCX - 150, y: safeCY),
            CGPoint(x: safeCX + 150, y: safeCY),
            CGPoint(x: safeCX, y: safeCY + 150),
            CGPoint(x: safeCX - 100, y: safeCY - 120),
            CGPoint(x: safeCX + 100, y: safeCY - 120)
        ]
        
        let types: [StationType] = [.circle, .triangle, .square, .circle, .triangle]
        
        for (i, pos) in positions.enumerated() {
            let type = types[i % types.count]
            let station = Station(id: UUID(), position: pos, type: type)
            gameStations.append(station)
            renderStation(station)
        }
    }
    
    private func renderStation(_ station: Station) {
        let stationNode = SKSpriteNode(color: .clear, size: CGSize(width: touchAreaRadius*2, height: touchAreaRadius*2))
        stationNode.position = station.position
        stationNode.name = "station_\(station.id.uuidString)"
        stationNode.zPosition = 10
        
        // Visual Shape
        let shape: SKShapeNode
        switch station.type {
        case .circle:
            shape = SKShapeNode(circleOfRadius: stationRadius)
        case .square:
            shape = SKShapeNode(rectOf: CGSize(width: stationRadius*2, height: stationRadius*2), cornerRadius: 2)
        case .triangle:
            let path = CGMutablePath()
            let h = stationRadius * sqrt(3)
            path.move(to: CGPoint(x: 0, y: h/2))
            path.addLine(to: CGPoint(x: stationRadius, y: -h/2))
            path.addLine(to: CGPoint(x: -stationRadius, y: -h/2))
            path.closeSubpath()
            shape = SKShapeNode(path: path)
        }
        
        shape.fillColor = .white
        shape.strokeColor = .black
        shape.lineWidth = 3
        shape.isUserInteractionEnabled = false
        
        stationNode.addChild(shape)
        addChild(stationNode)
        
        stationNodes[station.id] = stationNode
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // 0. Check HUD
        let nodesAtPoint = nodes(at: location)
        for node in nodesAtPoint {
            let name = node.name ?? node.parent?.name
            if name == "menu_btn" {
                onMenuTapped?()
                return
            }
            if name == "line_red" {
                currentLineColor = .systemRed
                updateHUD()
                return
            }
            if name == "line_blue" {
                currentLineColor = .systemBlue
                updateHUD()
                return
            }
            if name == "line_green" {
                currentLineColor = .systemGreen
                updateHUD()
                return
            }
        }
        
        // 1. Check if touched a station
        if let (stationID, stationPos) = getStationAt(location) {
            startDrawingLine(from: stationID, at: stationPos)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let startID = startStationID,
              let startNode = stationNodes[startID] else { return }
        
        let location = touch.location(in: self)
        updateDraftLine(from: startNode.position, to: location)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let startID = startStationID else {
            resetDraft()
            return
        }
        
        let location = touch.location(in: self)
        
        // 2. Check if ended on a different station
        if let (endID, _) = getStationAt(location), endID != startID {
            completeConnection(from: startID, to: endID)
        }
        
        resetDraft()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetDraft()
    }
    
    // MARK: - Logic
    
    private func getStationAt(_ location: CGPoint) -> (UUID, CGPoint)? {
        for station in gameStations {
            if hypot(station.position.x - location.x, station.position.y - location.y) < touchAreaRadius {
                return (station.id, station.position)
            }
        }
        return nil
    }
    
    private func startDrawingLine(from stationID: UUID, at position: CGPoint) {
        startStationID = stationID
        let draft = SKShapeNode()
        draft.strokeColor = currentLineColor.withAlphaComponent(0.5)
        draft.lineWidth = 6
        draft.lineCap = .round
        draft.zPosition = 5
        addChild(draft)
        currentDraftLine = draft
    }
    
    private func updateDraftLine(from startPos: CGPoint, to currentPos: CGPoint) {
        guard let draft = currentDraftLine else { return }
        let path = CGMutablePath()
        path.move(to: startPos)
        path.addLine(to: currentPos)
        draft.path = path
    }
    
    private func resetDraft() {
        currentDraftLine?.removeFromParent()
        currentDraftLine = nil
        startStationID = nil
    }
    
    private func completeConnection(from start: UUID, to end: UUID) {
        createVisualLineSegment(from: start, to: end, color: currentLineColor)
    }
    
    private func createVisualLineSegment(from startID: UUID, to endID: UUID, color: UIColor) {
        guard let startNode = stationNodes[startID],
              let endNode = stationNodes[endID] else { return }
        
        let path = CGMutablePath()
        path.move(to: startNode.position)
        path.addLine(to: endNode.position)
        
        let lineSeg = SKShapeNode(path: path)
        lineSeg.strokeColor = color
        lineSeg.lineWidth = 8
        lineSeg.lineCap = .round
        lineSeg.zPosition = 1
        
        addChild(lineSeg)
    }
}