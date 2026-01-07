import SpriteKit

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
        node.strokeColor = .white
        node.lineWidth = 2
        return node
    }
}
