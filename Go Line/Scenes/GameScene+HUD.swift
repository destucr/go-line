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
        let hint = SKLabelNode(text: "DRAW A PATH BETWEEN STATIONS TO BEGIN")
        hint.name = "tutorial_hint"
        hint.fontName = "AvenirNext-Bold"
        hint.fontSize = 16
        hint.fontColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.8) // Dark Gray for contrast
        // Move lower to avoid HUD at the top
        hint.position = CGPoint(x: 0, y: 60)
        hint.alpha = 0
        
        // Add to camera so it stays on screen
        if let cam = camera {
            cam.addChild(hint)
        } else {
            addChild(hint)
        }
        
        let appear = SKAction.fadeIn(withDuration: 1.0)
        let wait = SKAction.wait(forDuration: 5.0)
        let disappear = SKAction.fadeOut(withDuration: 1.0)
        
        hint.run(SKAction.sequence([appear, wait, disappear, SKAction.removeFromParent()]))
    }
    
    func showLevelUpPopup() {
        let width: CGFloat = 350
        let height: CGFloat = 100
        let container = GraphicsManager.createTagNode(size: CGSize(width: width, height: height))
        
        var unlockedColorName = ""
        var strokeColor: UIColor = .systemBlue
        
        switch level {
        case 2: unlockedColorName = "BLUE"; strokeColor = .systemBlue
        case 3: unlockedColorName = "GREEN"; strokeColor = .systemGreen
        case 4: unlockedColorName = "ORANGE"; strokeColor = .systemOrange
        case 5: unlockedColorName = "PURPLE"; strokeColor = .systemPurple
        default: unlockedColorName = "NEW GOALS"; strokeColor = .white
        }
        
        container.strokeColor = strokeColor
        container.position = CGPoint(x: 0, y: 0)
        container.zPosition = 1_000
        container.alpha = 0
        
        if let cam = camera {
            cam.addChild(container)
        } else {
            addChild(container)
        }
        
        let titleLabel = SKLabelNode(text: "LEVEL \(level) REACHED")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 14
        titleLabel.fontColor = .white.withAlphaComponent(0.6)
        titleLabel.position = CGPoint(x: 0, y: 15)
        container.addChild(titleLabel)
        
        let subLabel = SKLabelNode(text: level <= 5 ? "\(unlockedColorName) LINE UNLOCKED" : "GOALS INCREASED")
        subLabel.fontName = "AvenirNext-Bold"
        subLabel.fontSize = 24
        subLabel.fontColor = strokeColor
        subLabel.position = CGPoint(x: 0, y: -15)
        container.addChild(subLabel)
        
        let sequence = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.wait(forDuration: 3.5),
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
        
        let hasEarnings = earnings > 0
        let bgWidth: CGFloat = hasEarnings ? 100 : 60
        let bgHeight: CGFloat = hasEarnings ? 40 : 28
        
        // Metro Pill Background
        let bg = SKShapeNode(rectOf: CGSize(width: bgWidth, height: bgHeight), cornerRadius: 4)
        bg.fillColor = .white
        bg.strokeColor = .black
        bg.lineWidth = 2
        // Shadow effect built into shape
        let shadow = SKShapeNode(rectOf: CGSize(width: bgWidth, height: bgHeight), cornerRadius: 4)
        shadow.fillColor = .black.withAlphaComponent(0.3)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 4, y: -4)
        shadow.zPosition = -1
        
        container.addChild(shadow)
        container.addChild(bg)
        
        let scoreLabel = SKLabelNode(text: "+\(amount)")
        scoreLabel.fontName = "ArialRoundedMTBold" // System-like rounded bold
        scoreLabel.fontSize = 18
        scoreLabel.fontColor = .black
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: 0, y: hasEarnings ? 8 : 0)
        container.addChild(scoreLabel)
        
        if hasEarnings {
            let earningLabel = SKLabelNode(text: "+\(earnings) THREAD")
            earningLabel.fontName = "Courier-Bold"
            earningLabel.fontSize = 10
            earningLabel.fontColor = .black
            earningLabel.verticalAlignmentMode = .center
            earningLabel.position = CGPoint(x: 0, y: -8)
            container.addChild(earningLabel)
        }
        
        // Animation: Gentle rise and scale up
        container.setScale(0.5)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.2)
        let move = SKAction.moveBy(x: 0, y: 60, duration: 1.2)
        let fade = SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.fadeOut(withDuration: 0.4)
        ])
        
        let group = SKAction.group([move, fade, scaleUp])
        container.run(SKAction.sequence([group, SKAction.removeFromParent()]))
    }
    
    func updateHUD() {
        // Not used as UIKit handles state updates
    }
}
