import SpriteKit

class MenuScene: SKScene {
    
    var onPlayButtonTapped: (() -> Void)?
    var onGuideButtonTapped: (() -> Void)?
    
    // Nodes
    private let titleNode = SKLabelNode(text: "Metro Manager")
    private var playButton: SKNode!
    private var guideButton: SKNode!
    
    private var isCreated = false
    
    override func didMove(to view: SKView) {
        backgroundColor = .white
        if !isCreated {
            createMenuUI()
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
    
    private func createMenuUI() {
        // Title
        titleNode.fontName = "AvenirNext-Bold"
        titleNode.fontSize = 50
        titleNode.fontColor = .black
        addChild(titleNode)
        
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
        
        titleNode.position = CGPoint(x: centerX, y: centerY + 80)
        playButton.position = CGPoint(x: centerX, y: centerY - 10)
        guideButton.position = CGPoint(x: centerX, y: centerY - 90)
    }
    
    private func createButton(text: String, name: String) -> SKNode {
        let container = SKNode()
        container.name = name
        
        let background = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 10)
        background.fillColor = .black
        background.strokeColor = .clear
        background.name = name // Hit test matches name
        container.addChild(background)
        
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 24
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.name = name
        container.addChild(label)
        
        return container
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        // Check node or its parent (in case label is clicked)
        let name = touchedNode.name ?? touchedNode.parent?.name
        
        if name == "play_btn" {
            onPlayButtonTapped?()
        } else if name == "guide_btn" {
            onGuideButtonTapped?()
        }
    }
}
