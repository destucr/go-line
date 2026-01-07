import SpriteKit

class GuideScene: SKScene {
    
    var onBackTapped: (() -> Void)?
    
    private let title = SKLabelNode(text: "How to Play")
    private var instructionLabels: [SKLabelNode] = []
    private var backBtn: SKNode!
    
    private var isCreated = false
    
    override func didMove(to view: SKView) {
        backgroundColor = .white
        if !isCreated {
            createContent()
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
    
    private func createContent() {
        // Title
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 40
        title.fontColor = .black
        addChild(title)
        
        // Instructions
        let instructions = [
            "1. Touch and drag from a station to draw a line.",
            "2. Connect different shapes (Circle -> Square).",
            "3. Don't let stations overcrowd!",
            "4. Use the menu to switch line colors."
        ]
        
        for text in instructions {
            let label = SKLabelNode(text: text)
            label.fontName = "AvenirNext-Medium"
            label.fontSize = 20
            label.fontColor = .darkGray
            addChild(label)
            instructionLabels.append(label)
        }
        
        // Back Button
        let container = SKNode()
        container.name = "back_btn"
        let bg = SKShapeNode(rectOf: CGSize(width: 120, height: 50), cornerRadius: 8)
        bg.fillColor = .systemBlue
        bg.strokeColor = .clear
        bg.name = "back_btn"
        container.addChild(bg)
        
        let btnLabel = SKLabelNode(text: "Back")
        btnLabel.fontName = "AvenirNext-Bold"
        btnLabel.fontSize = 20
        btnLabel.verticalAlignmentMode = .center
        btnLabel.fontColor = .white
        btnLabel.name = "back_btn"
        container.addChild(btnLabel)
        
        addChild(container)
        backBtn = container
    }
    
    private func layoutUI() {
        let centerX = size.width / 2
        let topY = size.height - 80
        
        title.position = CGPoint(x: centerX, y: topY)
        
        for (index, label) in instructionLabels.enumerated() {
            label.position = CGPoint(x: centerX, y: topY - 80 - CGFloat(index * 40))
        }
        
        // Back button bottom left
        backBtn.position = CGPoint(x: 80, y: 50)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)
        let name = node.name ?? node.parent?.name
        
        if name == "back_btn" {
            onBackTapped?()
        }
    }
}
