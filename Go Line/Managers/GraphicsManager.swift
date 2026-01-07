internal import SpriteKit

class GraphicsManager {
    
    // MARK: - Shaders
    
    static let paperShader: SKShader = {
        let source = """
        void main() {
            vec2 pos = v_tex_coord * u_size; // Use pixel position for consistent noise scale
            float noise = fract(sin(dot(pos, vec2(12.9898, 78.233))) * 43758.5453);
            vec3 color = vec3(0.96, 0.96, 0.92); // Beige/Paper base
            color -= noise * 0.08; // Subtract noise for grain
            gl_FragColor = vec4(color, 1.0);
        }
        """
        let shader = SKShader(source: source)
        // We pass 'u_size' from the node using the shader if needed,
        // but often v_tex_coord is enough if we just want random noise per pixel.
        // To make it screen-relative independent of node size, we might need uniforms.
        // For simplicity, let's use standard v_tex_coord.
        
        let simpleSource = """
        void main() {
            float noise = fract(sin(dot(v_tex_coord, vec2(12.9898, 78.233))) * 43758.5453);
            vec3 color = vec3(0.96, 0.96, 0.90);
            color -= noise * 0.05;
            gl_FragColor = vec4(color, 1.0);
        }
        """
        return SKShader(source: simpleSource)
    }()
    
    // MARK: - Shape Generators
    
    static func createBackground(size: CGSize) -> SKSpriteNode {
        let node = SKSpriteNode(color: .white, size: size)
        node.shader = paperShader
        node.zPosition = -100
        return node
    }
    
    static func createTagNode(size: CGSize) -> SKShapeNode {
        let rect = CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2), size: size)
        let node = SKShapeNode(rect: rect, cornerRadius: 8)
        node.fillColor = UIColor(white: 0.95, alpha: 1.0)
        node.strokeColor = .gray
        node.lineWidth = 1
        
        // Stitch effect
        let stitchRect = rect.insetBy(dx: 3, dy: 3)
        let stitchPath = CGPath(roundedRect: stitchRect, cornerWidth: 6, cornerHeight: 6, transform: nil)
        let stitch = SKShapeNode(path: stitchPath)
        
        // Create dashed pattern manually or via dashPhase
        // Note: SKShapeNode copy(dashingWithPhase...) works on the path
        let dashedPath = stitchPath.copy(dashingWithPhase: 0, lengths: [4, 4])
        stitch.path = dashedPath
        
        stitch.strokeColor = .darkGray
        stitch.lineWidth = 1
        node.addChild(stitch)
        
        return node
    }
    
    static func createStationShape(type: StationType, radius: CGFloat) -> SKShapeNode {
        let node: SKShapeNode
        
        switch type {
        case .circle:
            node = SKShapeNode(circleOfRadius: radius)
        case .square:
            let rect = CGRect(x: -radius, y: -radius, width: radius*2, height: radius*2)
            node = SKShapeNode(rect: rect, cornerRadius: 4)
        case .triangle:
            let path = CGMutablePath()
            // Triangle pointing up
            let h = radius * sqrt(3)
            // Center centroid
            let yOffset = h / 3
            path.move(to: CGPoint(x: 0, y: h - yOffset))
            path.addLine(to: CGPoint(x: -radius, y: -yOffset))
            path.addLine(to: CGPoint(x: radius, y: -yOffset))
            path.closeSubpath()
            node = SKShapeNode(path: path)
            node.lineJoin = .round
            
        case .pentagon:
            let path = CGMutablePath()
            for i in 0..<5 {
                let angle = CGFloat(i) * (2 * .pi / 5) + .pi / 2
                let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
            node = SKShapeNode(path: path)
            node.lineJoin = .round
            
        case .star:
            let path = CGMutablePath()
            let outerRadius = radius
            let innerRadius = radius * 0.4
            for i in 0..<10 {
                let angle = CGFloat(i) * (2 * .pi / 10) + .pi / 2
                let r = (i % 2 == 0) ? outerRadius : innerRadius
                let point = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
            node = SKShapeNode(path: path)
            node.lineJoin = .round
            
        case .diamond:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: radius))
            path.addLine(to: CGPoint(x: radius * 0.8, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -radius))
            path.addLine(to: CGPoint(x: -radius * 0.8, y: 0))
            path.closeSubpath()
            node = SKShapeNode(path: path)
            node.lineJoin = .round
            
        case .cross:
            let path = CGMutablePath()
            let w = radius * 0.4
            let r = radius
            path.move(to: CGPoint(x: -w, y: r))
            path.addLine(to: CGPoint(x: w, y: r))
            path.addLine(to: CGPoint(x: w, y: w))
            path.addLine(to: CGPoint(x: r, y: w))
            path.addLine(to: CGPoint(x: r, y: -w))
            path.addLine(to: CGPoint(x: w, y: -w))
            path.addLine(to: CGPoint(x: w, y: -r))
            path.addLine(to: CGPoint(x: -w, y: -r))
            path.addLine(to: CGPoint(x: -w, y: -w))
            path.addLine(to: CGPoint(x: -r, y: -w))
            path.addLine(to: CGPoint(x: -r, y: w))
            path.addLine(to: CGPoint(x: -w, y: w))
            path.closeSubpath()
            node = SKShapeNode(path: path)
            node.lineJoin = .round
            
        case .wedge:
            let path = CGMutablePath()
            // Teardrop shape
            path.addArc(center: CGPoint(x: 0, y: -radius * 0.2), radius: radius * 0.8, startAngle: 0, endAngle: .pi, clockwise: false)
            path.addLine(to: CGPoint(x: 0, y: radius))
            path.closeSubpath()
            node = SKShapeNode(path: path)
            node.lineJoin = .round
            
        case .oval:
            let rect = CGRect(x: -radius * 1.2, y: -radius * 0.7, width: radius * 2.4, height: radius * 1.4)
            node = SKShapeNode(ellipseIn: rect)
        }
        
        node.fillColor = .white
        node.strokeColor = .darkGray
        node.lineWidth = 2
        
        return node
    }
    
    static func createTrainShape(color: UIColor) -> SKShapeNode {
        let width: CGFloat = 24
        let height: CGFloat = 12
        let rect = CGRect(x: -width/2, y: -height/2, width: width, height: height)
        let node = SKShapeNode(rect: rect, cornerRadius: 4)
        node.fillColor = color
        node.strokeColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) // Charcoal outline
        node.lineWidth = 2
        return node
    }
    
    static func createScrapNode() -> SKNode {
        let container = SKNode()
        container.alpha = 0.2
        
        // Random scrap types (thread snips, small patches)
        let type = Int.random(in: 0...2)
        switch type {
        case 0:
            // Crossed Threads
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -10, y: -5))
            path.addLine(to: CGPoint(x: 10, y: 5))
            path.move(to: CGPoint(x: -5, y: 10))
            path.addLine(to: CGPoint(x: 5, y: -10))
            let lines = SKShapeNode(path: path)
            lines.strokeColor = .gray
            lines.lineWidth = 1
            container.addChild(lines)
        case 1:
            // Small Fabric Patch (Dashed square)
            let rect = CGRect(x: -8, y: -8, width: 16, height: 16)
            let patch = SKShapeNode(rect: rect, cornerRadius: 2)
            patch.strokeColor = .lightGray
            patch.lineWidth = 1
            if let dashed = patch.path?.copy(dashingWithPhase: 0, lengths: [2, 2]) {
                patch.path = dashed
            }
            container.addChild(patch)
        default:
            // Loose Loop
            let path = CGMutablePath()
            path.addEllipse(in: CGRect(x: -6, y: -6, width: 12, height: 12))
            let loop = SKShapeNode(path: path)
            loop.strokeColor = .gray
            loop.lineWidth = 0.5
            container.addChild(loop)
        }
        
        container.zRotation = CGFloat.random(in: 0...(2 * .pi))
        return container
    }
    
    static func createProgressBar(size: CGSize) -> (container: SKShapeNode, fill: SKShapeNode) {
        let container = SKShapeNode(rectOf: size, cornerRadius: size.height/2)
        container.fillColor = .white
        container.strokeColor = .lightGray
        container.lineWidth = 1
        
        let fill = SKShapeNode(rect: CGRect(x: -size.width/2, y: -size.height/2, width: 0, height: size.height), cornerRadius: size.height/2)
        fill.fillColor = .systemGreen
        fill.strokeColor = .clear
        container.addChild(fill)
        
        return (container, fill)
    }
    
    static func createConfettiEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 100
        emitter.numParticlesToEmit = 50
        emitter.particleLifetime = 2.0
        emitter.particleSpeed = 150
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.5
        emitter.particleScale = 0.5
        emitter.particleRotation = 0
        emitter.emissionAngleRange = .pi * 2
        emitter.particleColorSequence = SKKeyframeSequence(keyframeValues: [UIColor.red, UIColor.blue, UIColor.green, UIColor.yellow], times: [0, 0.33, 0.66, 1.0])
        
        let circle = SKShapeNode(circleOfRadius: 4)
        circle.fillColor = .white
        if let texture = SKView().texture(from: circle) {
            emitter.particleTexture = texture
        }
        
        return emitter
    }
}
