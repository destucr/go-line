import SpriteKit

class MenuScene: SKScene {
    
    var onPlayButtonTapped: (() -> Void)?
    var onGuideButtonTapped: (() -> Void)?
    
    // Nodes
    private let titleNode = SKLabelNode(text: "Metro Stitcher")
    private var subtitleNode = SKLabelNode(text: "Embroider the Transit Pattern")
    private var playButton: SKNode!
    private var guideButton: SKNode!
    
    private var isCreated = false
    
    override func didMove(to view: SKView) {
        // Background
        let bg = GraphicsManager.createBackground(size: size)
        bg.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(bg)
        
        if !isCreated {
            createMenuUI()
            isCreated = true
        }
        layoutUI()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // Update background size if needed
        if let bg = children.first(where: { $0.zPosition == -100 }) as? SKSpriteNode {
            bg.size = size
            bg.position = CGPoint(x: size.width/2, y: size.height/2)
        }
        
        if isCreated {
            layoutUI()
        }
    }
    
    private func createMenuUI() {
        // Title
        titleNode.fontName = "ChalkboardSE-Bold"
        titleNode.fontSize = 50
        titleNode.fontColor = .darkGray
        addChild(titleNode)
        
        subtitleNode.fontName = "ChalkboardSE-Regular"
        subtitleNode.fontSize = 18
        subtitleNode.fontColor = .systemBlue
        addChild(subtitleNode)
        
        // Play Button
        playButton = createButton(text: "Play Game", name: "play_btn")
        addChild(playButton)
        
        // Guide Button
        guideButton = createButton(text: "Guide", name: "guide_btn")
        addChild(guideButton)
    }
    
    private func layoutUI() {
        // Center vertically and horizontally
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        titleNode.position = CGPoint(x: centerX, y: centerY + 100)
        subtitleNode.position = CGPoint(x: centerX, y: centerY + 65)
        playButton.position = CGPoint(x: centerX, y: centerY - 10)
        guideButton.position = CGPoint(x: centerX, y: centerY - 90)
    }
    
    private func createButton(text: String, name: String) -> SKNode {
        let container = SKNode()
        container.name = name
        
        let background = GraphicsManager.createTagNode(size: CGSize(width: 200, height: 60))
        background.name = name // Hit test matches name
        container.addChild(background)
        
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 24
        label.fontColor = .darkGray
        label.verticalAlignmentMode = .center
        label.name = name
        container.addChild(label)
        
        return container
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        let name = touchedNode.name ?? touchedNode.parent?.name
        
        if name == "play_btn" || name == "guide_btn" {
            let buttonNode = (touchedNode.name == name) ? touchedNode : touchedNode.parent!
            animateButtonPress(buttonNode) { [weak self] in
                if name == "play_btn" {
                    self?.onPlayButtonTapped?()
                } else if name == "guide_btn" {
                    self?.onGuideButtonTapped?()
                }
            }
        }
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
}
