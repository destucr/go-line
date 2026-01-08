internal import SpriteKit

class GraphicsManager {
    
    // MARK: - Shaders
    
    /// A Metal-compatible SKShader providing a subtle brushed steel texture.
    /// Directional micro-noise simulates machining marks.
    static let metalShader: SKShader = {
        let source = """
        void main() {
            vec2 uv = v_tex_coord;
            // High-frequency directional noise for brushed effect
            float noise = fract(sin(dot(uv * vec2(1.0, 1000.0), vec2(12.9898, 78.233))) * 43758.5453);
            
            vec3 baseColor = vec3(0.12, 0.13, 0.15); // Deep Slate
            vec3 highlight = vec3(0.18, 0.19, 0.21); // Steel Highlight
            
            vec3 finalColor = mix(baseColor, highlight, noise * 0.15);
            
            // Subtle vignette for focus
            float dist = distance(uv, vec2(0.5, 0.5));
            finalColor *= smoothstep(1.2, 0.4, dist);
            
            gl_FragColor = vec4(finalColor, 1.0);
        }
        """
        return SKShader(source: source)
    }()
    
    // MARK: - Shape Generators
    
    static func createBackground(size: CGSize) -> SKSpriteNode {
        let node = SKSpriteNode(color: .black, size: size)
        node.shader = metalShader
        node.zPosition = -100
        return node
    }
    
    static func createTagNode(size: CGSize) -> SKShapeNode {
        let rect = CGRect(origin: CGPoint(x: -size.width / 2, y: -size.height / 2), size: size)
        let node = SKShapeNode(rect: rect, cornerRadius: 4) // Sharper industrial radius
        node.fillColor = UIColor(white: 0.1, alpha: 1.0)
        node.strokeColor = UIColor(white: 0.3, alpha: 1.0)
        node.lineWidth = 2
        
        return node
    }
    
    static func createStationShape(type: StationType, radius: CGFloat, lineWidth: CGFloat = 4) -> SKShapeNode {
        let node: SKShapeNode
        
        switch type {
        case .circle:
            node = SKShapeNode(circleOfRadius: radius)
        case .square:
            let rect = CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)
            node = SKShapeNode(rect: rect, cornerRadius: 4)
        case .triangle:
            let path = CGMutablePath()
            // Visually balance size: Triangles feel smaller, so we boost the radius slightly
            let adjustedRadius = radius * 1.2
            let h = adjustedRadius * sqrt(3)
            let yOffset = h / 3
            path.move(to: CGPoint(x: 0, y: h - yOffset))
            path.addLine(to: CGPoint(x: -adjustedRadius, y: -yOffset))
            path.addLine(to: CGPoint(x: adjustedRadius, y: -yOffset))
            path.closeSubpath()
            node = SKShapeNode(path: path)
            
        case .pentagon:
            let path = CGMutablePath()
            for i in 0..<5 {
                let angle = CGFloat(i) * (2 * .pi / 5) + .pi / 2
                let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
            node = SKShapeNode(path: path)

        case .star:
            let path = CGMutablePath()
            let outerRadius = radius
            let innerRadius = radius * 0.45
            for i in 0..<10 {
                let angle = CGFloat(i) * (2 * .pi / 10) + .pi / 2
                let r = (i % 2 == 0) ? outerRadius : innerRadius
                let point = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
            node = SKShapeNode(path: path)
            
        case .diamond:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: radius))
            path.addLine(to: CGPoint(x: radius * 0.9, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -radius))
            path.addLine(to: CGPoint(x: -radius * 0.9, y: 0))
            path.closeSubpath()
            node = SKShapeNode(path: path)
            
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
            
        case .wedge:
            let path = CGMutablePath()
            path.addArc(center: CGPoint(x: 0, y: -radius * 0.1), radius: radius * 0.9, startAngle: 0, endAngle: .pi, clockwise: false)
            path.addLine(to: CGPoint(x: 0, y: radius))
            path.closeSubpath()
            node = SKShapeNode(path: path)
            
        case .oval:
            let rect = CGRect(x: -radius * 1.3, y: -radius * 0.8, width: radius * 2.6, height: radius * 1.6)
            node = SKShapeNode(ellipseIn: rect)
        }
        
        node.fillColor = .white
        node.strokeColor = UIColor(white: 0.1, alpha: 1.0)
        node.lineWidth = lineWidth
        
        return node
    }
    
    static func createTrainShape(color: UIColor) -> SKShapeNode {
        let width: CGFloat = 28
        let height: CGFloat = 16
        let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
        let node = SKShapeNode(rect: rect, cornerRadius: 3)
        node.fillColor = color
        node.strokeColor = .white
        node.lineWidth = 2
        
        // Add a subtle "window" or detail to the train
        let window = SKShapeNode(rect: CGRect(x: -width / 2 + 4, y: -height / 2 + 3, width: width - 8, height: height - 6), cornerRadius: 1)
        window.fillColor = UIColor.white.withAlphaComponent(0.3)
        window.strokeColor = .clear
        node.addChild(window)
        
        return node
    }
    
    static func createProgressBar(size: CGSize) -> (container: SKShapeNode, fill: SKShapeNode) {
        let container = SKShapeNode(rectOf: size, cornerRadius: 2)
        container.fillColor = UIColor(white: 0.1, alpha: 1.0)
        container.strokeColor = UIColor(white: 0.3, alpha: 1.0)
        container.lineWidth = 1
        
        let fill = SKShapeNode(rect: CGRect(x: -size.width / 2, y: -size.height / 2, width: 0, height: size.height), cornerRadius: 0)
        fill.fillColor = .systemOrange // High visibility industrial orange
        fill.strokeColor = .clear
        container.addChild(fill)
        
        return (container, fill)
    }
    
    static func createConfettiEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 120
        emitter.numParticlesToEmit = 60
        emitter.particleLifetime = 1.5
        emitter.particleSpeed = 200
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.8
        emitter.particleScale = 0.4
        emitter.emissionAngleRange = .pi * 2
        
        // Industrial sparks instead of colorful confetti
        emitter.particleColorSequence = SKKeyframeSequence(keyframeValues: [UIColor.orange, UIColor.yellow, UIColor.white], times: [0, 0.5, 1.0])
        
        let spark = SKShapeNode(rectOf: CGSize(width: 4, height: 4))
        spark.fillColor = .white
        if let texture = SKView().texture(from: spark) {
            emitter.particleTexture = texture
        }
        
        return emitter
    }
    
    static func createScrapNode() -> SKNode {
        let size = CGSize(width: CGFloat.random(in: 10...30), height: CGFloat.random(in: 10...30))
        let node = SKShapeNode(rectOf: size, cornerRadius: 2)
        node.fillColor = UIColor(white: 0.9, alpha: 0.3)
        node.strokeColor = .clear
        node.zRotation = CGFloat.random(in: 0...( .pi * 2))
        return node
    }
}
