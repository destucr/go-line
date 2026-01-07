internal import SpriteKit

extension GameScene {
    
    // MARK: - UI & HUD
    func createHUD() {
        // Legacy SpriteKit HUD removed in favor of native UIKit HUD
    }
    
    func layoutUI() {
        // Legacy SpriteKit HUD layout removed
    }
    
    func showTutorialHint() {
        let hint = SKLabelNode(text: "Draw a path between stations to begin")
        hint.name = "tutorial_hint"
        hint.fontName = "ChalkboardSE-Bold"
        hint.fontSize = 24
        hint.fontColor = .darkGray
        // Relative to camera center (0,0)
        hint.position = CGPoint(x: 0, y: 100)
        hint.alpha = 0
        
        // Add to camera so it stays on screen
        if let cam = camera {
            cam.addChild(hint)
        } else {
            addChild(hint)
        }
        
        let appear = SKAction.fadeIn(withDuration: 1.0)
        let wait = SKAction.wait(forDuration: 4.0)
        let disappear = SKAction.fadeOut(withDuration: 1.0)
        
        hint.run(SKAction.sequence([appear, wait, disappear, SKAction.removeFromParent()]))
    }
    
    func showLevelUpPopup() {
        let container = SKShapeNode(rectOf: CGSize(width: 400, height: 120), cornerRadius: 20)
        container.fillColor = UIColor(named: "BackgroundColor") ?? .white
        
        var unlockedColorName = ""
        var strokeColor: UIColor = .systemBlue
        
        switch level {
        case 2: unlockedColorName = "BLUE"; strokeColor = .systemBlue
        case 3: unlockedColorName = "GREEN"; strokeColor = .systemGreen
        case 4: unlockedColorName = "ORANGE"; strokeColor = .systemOrange
        case 5: unlockedColorName = "PURPLE"; strokeColor = .systemPurple
        default: unlockedColorName = "NEW GOALS"; strokeColor = .black
        }
        
        container.strokeColor = strokeColor
        container.lineWidth = 4
        container.position = CGPoint(x: 0, y: -20)
        container.zPosition = 1000
        container.alpha = 0
        
        if let cam = camera {
            cam.addChild(container)
        } else {
            addChild(container)
        }
        
        let titleLabel = SKLabelNode(text: "LEVEL \(level) REACHED")
        titleLabel.fontName = "ChalkboardSE-Bold"
        titleLabel.fontSize = 24
        titleLabel.fontColor = .darkGray
        titleLabel.position = CGPoint(x: 0, y: 15)
        container.addChild(titleLabel)
        
        let subLabel = SKLabelNode(text: level <= 5 ? "\(unlockedColorName) LINE UNLOCKED" : "GOALS INCREASED")
        subLabel.fontName = "ChalkboardSE-Bold"
        subLabel.fontSize = 28
        subLabel.fontColor = strokeColor
        subLabel.position = CGPoint(x: 0, y: -25)
        container.addChild(subLabel)
        
        let sequence = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])
        container.run(sequence)
    }
    
    func showScorePopup(amount: Int, earnings: Int = 0, at position: CGPoint) {
        let container = SKNode()
        container.position = position
        container.zPosition = 100
        addChild(container)
        
        let scoreLabel = SKLabelNode(text: "+\(amount)")
        scoreLabel.fontName = "ChalkboardSE-Bold"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .systemGreen
        container.addChild(scoreLabel)
        
        if earnings > 0 {
            let earningLabel = SKLabelNode(text: "+\(earnings) Thread")
            earningLabel.fontName = "ChalkboardSE-Bold"
            earningLabel.fontSize = 16
            earningLabel.fontColor = .systemOrange
            earningLabel.position = CGPoint(x: 0, y: -20)
            container.addChild(earningLabel)
        }
        
        // Animation
        let move = SKAction.moveBy(x: 0, y: 40, duration: 0.8)
        let fade = SKAction.fadeOut(withDuration: 0.8)
        let group = SKAction.group([move, fade])
        
        container.run(SKAction.sequence([group, SKAction.removeFromParent()]))
    }
    
    func updateHUD() {
        // Not used as UIKit handles state updates
    }
}
