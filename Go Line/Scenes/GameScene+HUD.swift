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
        let container = SKShapeNode(rectOf: CGSize(width: 300, height: 100), cornerRadius: 20)
        container.fillColor = .white
        container.strokeColor = .systemBlue
        container.lineWidth = 4
        // Relative to camera center
        container.position = CGPoint(x: 0, y: -20)
        container.zPosition = 1000
        container.alpha = 0
        
        if let cam = camera {
            cam.addChild(container)
        } else {
            addChild(container)
        }
        
        let label = SKLabelNode(text: "PATTERN \(level) UNLOCKED")
        label.fontName = "ChalkboardSE-Bold"
        label.fontSize = 28
        label.fontColor = .systemBlue
        label.verticalAlignmentMode = .center
        container.addChild(label)
        
        let sequence = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.3),
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
